module BackendLogic exposing (Effect(..), init, notifyAdminWait, sendConfirmationEmailRateLimit, update, updateFromFrontend)

import Bounds exposing (Bounds)
import Change exposing (ClientChange(..), ServerChange(..))
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Dict
import Duration exposing (Duration)
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import EverySet exposing (EverySet)
import Grid exposing (Grid)
import GridCell
import Lamdera exposing (ClientId, SessionId)
import List.Extra as List
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LocalGrid
import NotifyMe
import Quantity exposing (Quantity(..))
import RecentChanges
import SendGrid
import String.Nonempty exposing (NonemptyString(..))
import Time
import Types exposing (..)
import Undo
import Units exposing (CellUnit, TileUnit)
import UrlHelper exposing (ConfirmEmailKey(..), InternalRoute(..), UnsubscribeEmailKey(..))
import User exposing (UserId)


type Effect
    = SendToFrontend ClientId ToFrontend
    | SendEmail (Result SendGrid.Error () -> BackendMsg) NonemptyString Email.Html.Html EmailAddress


init : BackendModel
init =
    { grid = Grid.empty
    , userSessions = Dict.empty
    , users = Dict.empty
    , usersHiddenRecently = []
    , userChangesRecently = RecentChanges.init
    , subscribedEmails = []
    , pendingEmails = []
    , secretLinkCounter = 0
    , errors = []
    }


notifyAdminWait : Duration
notifyAdminWait =
    String.toFloat Env.notifyAdminWaitInHours |> Maybe.map Duration.hours |> Maybe.withDefault (Duration.hours 3)


update : BackendMsg -> BackendModel -> ( BackendModel, List Effect )
update msg model =
    case msg of
        UserDisconnected sessionId clientId ->
            ( { model
                | userSessions =
                    Dict.update sessionId
                        (Maybe.map
                            (\session ->
                                { clientIds = Dict.remove clientId session.clientIds
                                , userId = session.userId
                                }
                            )
                        )
                        model.userSessions
              }
            , []
            )

        NotifyAdminTimeElapsed time ->
            let
                ( newModel, cmd ) =
                    notifyAdmin model
            in
            ( newModel, cmd )

        NotifyAdminEmailSent ->
            ( model, [] )

        ConfirmationEmailSent sessionId timeSent result ->
            ( case result of
                Ok () ->
                    model

                Err error ->
                    case Env.adminEmail of
                        Just adminEmail ->
                            addError timeSent (SendGridError adminEmail error) model

                        Nothing ->
                            model
            , broadcast
                (\sessionId_ _ ->
                    if sessionId_ == sessionId then
                        NotifyMeEmailSent { isSuccessful = result == Ok () } |> Just

                    else
                        Nothing
                )
                model
            )

        UpdateFromFrontend sessionId clientId toBackendMsg time ->
            updateFromFrontend time sessionId clientId toBackendMsg model

        ChangeEmailSent time email result ->
            case result of
                Ok _ ->
                    ( model, [] )

                Err error ->
                    ( addError time (SendGridError email error) model, [] )


addError : Time.Posix -> BackendError -> BackendModel -> BackendModel
addError time error model =
    { model | errors = ( time, error ) :: model.errors }


notifyAdmin : BackendModel -> ( BackendModel, List Effect )
notifyAdmin model =
    let
        idToString =
            User.rawId >> String.fromInt

        fullUrl point =
            Env.domain ++ "/" ++ UrlHelper.encodeUrl (UrlHelper.internalRoute False point)

        hidden =
            List.map
                (\{ reporter, hiddenUser, hidePoint } ->
                    "User "
                        ++ idToString reporter
                        ++ " hid user "
                        ++ idToString hiddenUser
                        ++ "'s text at "
                        ++ fullUrl hidePoint
                )
                model.usersHiddenRecently
                |> String.join "\n"
    in
    if List.isEmpty model.usersHiddenRecently then
        ( model, [] )

    else
        ( { model | usersHiddenRecently = [] }
        , case Env.adminEmail of
            Just adminEmail ->
                [ SendEmail
                    (always NotifyAdminEmailSent)
                    (String.Nonempty.append_
                        (String.Nonempty.fromInt (List.length model.usersHiddenRecently))
                        " users hidden"
                    )
                    (Email.Html.text hidden)
                    adminEmail
                ]

            Nothing ->
                []
        )


backendUserId : UserId
backendUserId =
    User.userId -1


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( UserId, BackendUserData )
getUserFromSessionId sessionId model =
    case Dict.get sessionId model.userSessions of
        Just { userId } ->
            case Dict.get (User.rawId userId) model.users of
                Just user ->
                    Just ( userId, user )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


broadcastLocalChange :
    ( UserId, BackendUserData )
    -> Nonempty Change.LocalChange
    -> BackendModel
    -> ( BackendModel, List Effect )
broadcastLocalChange userIdAndUser changes model =
    let
        ( newModel, serverChanges ) =
            Nonempty.foldl
                (\change ( model_, serverChanges_ ) ->
                    updateLocalChange userIdAndUser change model_
                        |> Tuple.mapSecond (\serverChange -> serverChange :: serverChanges_)
                )
                ( model, [] )
                changes
                |> Tuple.mapSecond (List.filterMap identity >> List.reverse)
    in
    ( newModel
    , broadcast
        (\sessionId_ _ ->
            case getUserFromSessionId sessionId_ model of
                Just ( userId_, _ ) ->
                    if Tuple.first userIdAndUser == userId_ then
                        Nonempty.map Change.LocalChange changes |> ChangeBroadcast |> Just

                    else
                        List.filterMap
                            (\serverChange ->
                                case serverChange of
                                    Change.ServerToggleUserVisibilityForAll toggleUserId ->
                                        -- Don't let the user who got hidden know that they are hidden.
                                        if toggleUserId == userId_ then
                                            Nothing

                                        else
                                            Change.ServerChange serverChange |> Just

                                    _ ->
                                        Change.ServerChange serverChange |> Just
                            )
                            serverChanges
                            |> Nonempty.fromList
                            |> Maybe.map ChangeBroadcast

                Nothing ->
                    Nothing
        )
        model
    )


updateFromFrontend :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, List Effect )
updateFromFrontend currentTime sessionId clientId msg model =
    case msg of
        ConnectToBackend requestData maybeEmailEvent ->
            let
                ( newModel, effects ) =
                    requestDataUpdate sessionId clientId requestData model
            in
            (case maybeEmailEvent of
                Just (ConfirmationEmailConfirmed_ key) ->
                    confirmationEmailConfirmed sessionId currentTime key newModel

                Just (UnsubscribeEmail key) ->
                    unsubscribeEmail clientId key newModel

                Nothing ->
                    ( newModel, [] )
            )
                |> Tuple.mapSecond ((++) effects)

        GridChange changes ->
            case getUserFromSessionId sessionId model of
                Just userIdAndUser ->
                    broadcastLocalChange userIdAndUser changes model

                Nothing ->
                    ( model, [] )

        ChangeViewBounds bounds ->
            case
                Dict.get sessionId model.userSessions
                    |> Maybe.andThen (\{ clientIds } -> Dict.get clientId clientIds)
            of
                Just oldBounds ->
                    let
                        newCells =
                            Bounds.coordRangeFold
                                (\coord newCells_ ->
                                    if Bounds.contains coord oldBounds then
                                        newCells_

                                    else
                                        case Grid.getCell coord model.grid of
                                            Just cell ->
                                                ( coord, cell ) :: newCells_

                                            Nothing ->
                                                newCells_
                                )
                                identity
                                bounds
                                []
                    in
                    ( { model
                        | userSessions =
                            Dict.update
                                sessionId
                                (Maybe.map
                                    (\session ->
                                        { session
                                            | clientIds = Dict.update clientId (\_ -> Just bounds) session.clientIds
                                        }
                                    )
                                )
                                model.userSessions
                      }
                    , ViewBoundsChange bounds newCells
                        |> Change.ClientChange
                        |> Nonempty.fromElement
                        |> ChangeBroadcast
                        |> SendToFrontend clientId
                        |> List.singleton
                    )

                Nothing ->
                    ( model, [] )

        NotifyMeSubmitted validated ->
            case Dict.get sessionId model.userSessions of
                Just { userId } ->
                    sendConfirmationEmail validated model sessionId userId currentTime

                Nothing ->
                    ( model, [] )


confirmationEmailConfirmed : SessionId -> Time.Posix -> ConfirmEmailKey -> BackendModel -> ( BackendModel, List Effect )
confirmationEmailConfirmed sessionId currentTime confirmEmailKey model =
    case List.find (.key >> (==) confirmEmailKey) model.pendingEmails of
        Just pending ->
            let
                ( key, model2 ) =
                    generateKey UnsubscribeEmailKey model

                originalSessionId =
                    Dict.toList model.userSessions
                        |> List.find (\( _, { userId } ) -> pending.userId == userId)
                        |> Maybe.map Tuple.first
            in
            ( { model2
                | pendingEmails = List.filter (.key >> (/=) confirmEmailKey) model2.pendingEmails
                , subscribedEmails =
                    model2.subscribedEmails
                        |> List.filter (.email >> (/=) pending.email)
                        |> (::)
                            { email = pending.email
                            , frequency = pending.frequency
                            , confirmTime = currentTime
                            , userId = pending.userId
                            , unsubscribeKey = key
                            }
              }
            , broadcast
                (\sessionId_ _ ->
                    if sessionId_ == sessionId || Just sessionId_ == originalSessionId then
                        Just NotifyMeConfirmed

                    else
                        Nothing
                )
                model
            )

        Nothing ->
            ( model, [] )


unsubscribeEmail : ClientId -> UnsubscribeEmailKey -> BackendModel -> ( BackendModel, List Effect )
unsubscribeEmail clientId unsubscribeEmailKey model =
    case List.find (.unsubscribeKey >> (==) unsubscribeEmailKey) model.subscribedEmails of
        Just _ ->
            ( { model
                | subscribedEmails = List.filter (.unsubscribeKey >> (/=) unsubscribeEmailKey) model.subscribedEmails
              }
            , [ SendToFrontend clientId UnsubscribeEmailConfirmed ]
            )

        Nothing ->
            ( model, [] )


sendConfirmationEmailRateLimit : Duration
sendConfirmationEmailRateLimit =
    Duration.seconds 10


sendConfirmationEmail : NotifyMe.Validated -> BackendModel -> SessionId -> UserId -> Time.Posix -> ( BackendModel, List Effect )
sendConfirmationEmail validated model sessionId userId time =
    let
        tooEarly =
            case List.find (.email >> (==) validated.email) model.pendingEmails of
                Just { creationTime } ->
                    Duration.from creationTime time
                        |> Quantity.lessThanOrEqualTo sendConfirmationEmailRateLimit

                Nothing ->
                    False
    in
    if tooEarly then
        ( model, [] )

    else
        let
            ( key, model2 ) =
                generateKey ConfirmEmailKey model

            content =
                Email.Html.div []
                    [ Email.Html.a
                        [ Email.Html.Attributes.href
                            (Env.domain ++ "/" ++ UrlHelper.encodeUrl (EmailConfirmationRoute key))
                        ]
                        [ Email.Html.text "Click this link" ]
                    , Email.Html.text
                        " to confirm you want to be notified about changes people make on ascii-collab."
                    , Email.Html.br [] []
                    , Email.Html.text "If this email was sent to you in error, you can safely ignore it."
                    ]
        in
        ( { model2
            | pendingEmails =
                model2.pendingEmails
                    |> List.filter (.email >> (/=) validated.email)
                    |> (::)
                        { email = validated.email
                        , frequency = validated.frequency
                        , creationTime = time
                        , key = key
                        , userId = userId
                        }
          }
        , [ SendEmail
                (ConfirmationEmailSent sessionId time)
                (NonemptyString 'C' "onfirm ascii-collab notifications")
                content
                validated.email
          ]
        )


generateKey : (String -> keyType) -> { a | secretLinkCounter : Int } -> ( keyType, { a | secretLinkCounter : Int } )
generateKey keyType model =
    ( Env.confirmationEmailKey
        ++ String.fromInt model.secretLinkCounter
        |> Crypto.Hash.sha256
        |> keyType
    , { model | secretLinkCounter = model.secretLinkCounter + 1 }
    )


updateLocalChange :
    ( UserId, BackendUserData )
    -> Change.LocalChange
    -> BackendModel
    -> ( BackendModel, Maybe ServerChange )
updateLocalChange ( userId, _ ) change model =
    case change of
        Change.LocalUndo ->
            case Dict.get (User.rawId userId) model.users of
                Just user ->
                    case Undo.undo user of
                        Just newUser ->
                            let
                                undoMoveAmount : Dict.Dict RawCellCoord Int
                                undoMoveAmount =
                                    Dict.map (\_ a -> -a) user.undoCurrent
                            in
                            ( { model
                                | grid = Grid.moveUndoPoint userId undoMoveAmount model.grid
                                , userChangesRecently =
                                    if userId == backendUserId then
                                        model.userChangesRecently

                                    else
                                        RecentChanges.undoRedoChange undoMoveAmount model.grid model.userChangesRecently
                              }
                                |> updateUser userId (always newUser)
                            , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> Just
                            )

                        Nothing ->
                            ( model, Nothing )

                Nothing ->
                    ( model, Nothing )

        Change.LocalGridChange localChange ->
            case Dict.get (User.rawId userId) model.users of
                Just user ->
                    let
                        ( cellPosition, localPosition ) =
                            Grid.asciiToCellAndLocalCoord localChange.position
                    in
                    ( { model
                        | grid = Grid.addChange (Grid.localChangeToChange userId localChange) model.grid
                        , userChangesRecently =
                            if userId == backendUserId then
                                model.userChangesRecently

                            else
                                RecentChanges.addChange
                                    cellPosition
                                    (Grid.getCell cellPosition model.grid |> Maybe.withDefault GridCell.empty)
                                    model.userChangesRecently
                      }
                        |> updateUser
                            userId
                            (always
                                { user
                                    | undoCurrent =
                                        LocalGrid.incrementUndoCurrent cellPosition localPosition user.undoCurrent
                                }
                            )
                    , ServerGridChange (Grid.localChangeToChange userId localChange) |> Just
                    )

                Nothing ->
                    ( model, Nothing )

        Change.LocalRedo ->
            case Dict.get (User.rawId userId) model.users of
                Just user ->
                    case Undo.redo user of
                        Just newUser ->
                            let
                                undoMoveAmount =
                                    newUser.undoCurrent
                            in
                            ( { model
                                | grid = Grid.moveUndoPoint userId undoMoveAmount model.grid
                                , userChangesRecently =
                                    if userId == backendUserId then
                                        model.userChangesRecently

                                    else
                                        RecentChanges.undoRedoChange undoMoveAmount model.grid model.userChangesRecently
                              }
                                |> updateUser userId (always newUser)
                            , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> Just
                            )

                        Nothing ->
                            ( model, Nothing )

                Nothing ->
                    ( model, Nothing )

        Change.LocalAddUndo ->
            ( updateUser userId Undo.add model, Nothing )

        Change.LocalHideUser hideUserId hidePoint ->
            ( if userId == hideUserId then
                model

              else if Dict.member (User.rawId hideUserId) model.users then
                updateUser
                    userId
                    (\user -> { user | hiddenUsers = Coord.toggleSet hideUserId user.hiddenUsers })
                    { model
                        | usersHiddenRecently =
                            if Just userId == Env.adminUserId then
                                model.usersHiddenRecently

                            else
                                { reporter = userId, hiddenUser = hideUserId, hidePoint = hidePoint } :: model.usersHiddenRecently
                    }

              else
                model
            , Nothing
            )

        Change.LocalUnhideUser unhideUserId ->
            ( updateUser
                userId
                (\user -> { user | hiddenUsers = Coord.toggleSet unhideUserId user.hiddenUsers })
                { model
                    | usersHiddenRecently =
                        List.filterMap
                            (\value ->
                                if value.reporter == userId && unhideUserId == value.hiddenUser then
                                    Nothing

                                else
                                    Just value
                            )
                            model.usersHiddenRecently
                }
            , Nothing
            )

        Change.LocalToggleUserVisibilityForAll hideUserId ->
            if Just userId == Env.adminUserId && userId /= hideUserId then
                ( updateUser hideUserId (\user -> { user | hiddenForAll = not user.hiddenForAll }) model
                , ServerToggleUserVisibilityForAll hideUserId |> Just
                )

            else
                ( model, Nothing )


updateUser : UserId -> (BackendUserData -> BackendUserData) -> BackendModel -> BackendModel
updateUser userId updateUserFunc model =
    { model | users = Dict.update (User.rawId userId) (Maybe.map updateUserFunc) model.users }


{-| Gets globally hidden users known to a specific user.
-}
hiddenUsers :
    Maybe UserId
    -> { a | users : Dict.Dict Int { b | hiddenForAll : Bool } }
    -> EverySet UserId
hiddenUsers userId model =
    model.users
        |> Dict.toList
        |> List.filterMap
            (\( userId_, { hiddenForAll } ) ->
                if hiddenForAll && userId /= Just (User.userId userId_) then
                    Just (User.userId userId_)

                else
                    Nothing
            )
        |> EverySet.fromList


requestDataUpdate : SessionId -> ClientId -> Bounds CellUnit -> BackendModel -> ( BackendModel, List Effect )
requestDataUpdate sessionId clientId viewBounds model =
    let
        loadingData ( userId, user ) =
            { user = userId
            , grid = Grid.region viewBounds model.grid
            , hiddenUsers = user.hiddenUsers
            , adminHiddenUsers = hiddenUsers (Just userId) model
            , undoHistory = user.undoHistory
            , redoHistory = user.redoHistory
            , undoCurrent = user.undoCurrent
            , viewBounds = viewBounds
            }
    in
    case getUserFromSessionId sessionId model of
        Just ( userId, user ) ->
            ( { model
                | userSessions =
                    Dict.update sessionId
                        (\maybeSession ->
                            case maybeSession of
                                Just session ->
                                    Just { session | clientIds = Dict.insert clientId viewBounds session.clientIds }

                                Nothing ->
                                    Nothing
                        )
                        model.userSessions
              }
            , [ SendToFrontend clientId (LoadingData (loadingData ( userId, user ))) ]
            )

        Nothing ->
            let
                userId =
                    Dict.size model.users |> User.userId

                ( newModel, userData ) =
                    { model
                        | userSessions =
                            Dict.insert
                                sessionId
                                { clientIds = Dict.singleton clientId viewBounds, userId = userId }
                                model.userSessions
                    }
                        |> createUser userId
            in
            ( newModel
            , [ SendToFrontend
                    clientId
                    (LoadingData (loadingData ( userId, userData )))
              ]
            )


createUser : UserId -> BackendModel -> ( BackendModel, BackendUserData )
createUser userId model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { hiddenUsers = EverySet.empty
            , hiddenForAll = False
            , undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            }
    in
    ( { model | users = Dict.insert (User.rawId userId) userBackendData model.users }, userBackendData )


broadcast : (SessionId -> ClientId -> Maybe ToFrontend) -> BackendModel -> List Effect
broadcast msgFunc model =
    model.userSessions
        |> Dict.toList
        |> List.concatMap (\( sessionId, { clientIds } ) -> Dict.keys clientIds |> List.map (Tuple.pair sessionId))
        |> List.filterMap (\( sessionId, clientId ) -> msgFunc sessionId clientId |> Maybe.map (SendToFrontend clientId))
