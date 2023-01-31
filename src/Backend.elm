module Backend exposing (app, app_)

import AssocList
import Bounds exposing (Bounds)
import Change exposing (ClientChange(..), LocalChange(..), ServerChange(..), UserStatus(..))
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Cursor
import Dict
import DisplayName
import Duration exposing (Duration)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import EverySet exposing (EverySet)
import Grid exposing (Grid)
import GridCell
import Id exposing (EventId, Id, MailId, SecretId, TrainId, UserId)
import IdDict exposing (IdDict)
import Lamdera
import List.Extra as List
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LocalGrid
import MailEditor exposing (BackendMail, MailStatus(..))
import Postmark exposing (PostmarkSend, PostmarkSendResponse)
import Quantity exposing (Quantity(..))
import Route exposing (LoginOrInviteToken(..), LoginToken(..), Route(..))
import String.Nonempty exposing (NonemptyString(..))
import Tile exposing (RailPathType(..), Tile(..))
import Train exposing (Status(..), Train, TrainDiff)
import Types exposing (..)
import Undo
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Validation(..))
import User exposing (FrontendUser)


app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        (app_ Env.isProduction)


app_ isProduction =
    { init = ( init, Command.none )
    , update = update isProduction
    , updateFromFrontend =
        \sessionId clientId msg model ->
            ( model, Effect.Time.now |> Effect.Task.perform (UpdateFromFrontend sessionId clientId msg) )
    , subscriptions = subscriptions
    }


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions _ =
    Subscription.batch
        [ Effect.Lamdera.onDisconnect UserDisconnected
        , Effect.Lamdera.onConnect UserConnected
        , Effect.Time.every Duration.second WorldUpdateTimeElapsed
        , Effect.Time.every (Duration.seconds 5) (\_ -> CheckConnectionTimeElapsed)
        ]


init : BackendModel
init =
    let
        model : BackendModel
        model =
            { grid = Grid.empty
            , userSessions = Dict.empty
            , users = IdDict.empty
            , secretLinkCounter = 0
            , errors = []
            , trains = IdDict.empty
            , cows = IdDict.empty
            , lastWorldUpdateTrains = IdDict.empty
            , lastWorldUpdate = Nothing
            , mail = IdDict.empty
            , pendingLoginTokens = AssocList.empty
            , invites = AssocList.empty
            }
    in
    case Env.adminEmail of
        Just adminEmail ->
            createUser (Id.fromInt 0) adminEmail model |> Tuple.first

        Nothing ->
            model


sendEmail :
    Bool
    -> (Result Effect.Http.Error PostmarkSendResponse -> msg)
    -> NonemptyString
    -> String
    -> Email.Html.Html
    -> EmailAddress
    -> Command BackendOnly ToFrontend msg
sendEmail isProduction msg subject contentString content to =
    if isProduction then
        Postmark.sendEmail msg Env.postmarkApiKey (townCollabEmail subject contentString content to)

    else
        Effect.Process.sleep (Duration.milliseconds 100)
            |> Effect.Task.map
                (\_ ->
                    { to = EmailAddress.toString to
                    , submittedAt = ""
                    , messageId = ""
                    , errorCode = 0
                    , message = ""
                    }
                )
            |> Effect.Task.attempt msg


townCollabEmail : NonemptyString -> String -> Email.Html.Html -> EmailAddress -> PostmarkSend
townCollabEmail subject contentString content to =
    { from =
        { name = "town-collab"
        , email =
            EmailAddress.fromString "no-reply@town-collab.app"
                -- This should never happen
                |> Maybe.withDefault to
        }
    , to = Nonempty.fromElement { name = "", email = to }
    , subject = subject
    , body = Postmark.BodyBoth content contentString
    , messageStream = "outbound"
    }


disconnectClient : SessionId -> ClientId -> Id UserId -> BackendUserData -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend backendMsg )
disconnectClient sessionId clientId userId user model =
    ( { model
        | userSessions =
            Dict.update
                (Effect.Lamdera.sessionIdToString sessionId)
                (Maybe.map
                    (\session ->
                        { clientIds = AssocList.remove clientId session.clientIds
                        , userId = session.userId
                        }
                    )
                )
                model.userSessions
        , users = IdDict.update userId (\_ -> Just { user | cursor = Nothing }) model.users
      }
    , Nonempty (ServerUserDisconnected userId |> Change.ServerChange) []
        |> ChangeBroadcast
        |> Effect.Lamdera.broadcast
    )


update : Bool -> BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update isProduction msg model =
    case msg of
        UserDisconnected sessionId clientId ->
            asUser sessionId model (disconnectClient sessionId clientId)

        UserConnected _ clientId ->
            ( model, Effect.Lamdera.sendToFrontend clientId ClientConnected )

        NotifyAdminEmailSent ->
            ( model, Command.none )

        UpdateFromFrontend sessionId clientId toBackendMsg time ->
            updateFromFrontend isProduction time sessionId clientId toBackendMsg model

        SentLoginEmail sendTime emailAddress result ->
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError sendTime (PostmarkError emailAddress error) model, Command.none )

        WorldUpdateTimeElapsed time ->
            case model.lastWorldUpdate of
                Just oldTime ->
                    let
                        newTrains : IdDict TrainId Train
                        newTrains =
                            case model.lastWorldUpdate of
                                Just lastWorldUpdate ->
                                    IdDict.map
                                        (\trainId train ->
                                            Train.moveTrain trainId Train.defaultMaxSpeed lastWorldUpdate time model train
                                        )
                                        model.trains

                                Nothing ->
                                    model.trains

                        mergeTrains :
                            { mail : IdDict MailId BackendMail
                            , mailChanges : List ( Id MailId, BackendMail )
                            , diff : IdDict TrainId TrainDiff
                            }
                        mergeTrains =
                            IdDict.merge
                                (\_ _ a -> a)
                                (\trainId oldTrain newTrain state ->
                                    let
                                        diff : IdDict TrainId TrainDiff
                                        diff =
                                            IdDict.insert trainId (Train.diff oldTrain newTrain) state.diff
                                    in
                                    case ( Train.status oldTime oldTrain, Train.status time newTrain ) of
                                        ( TeleportingHome _, WaitingAtHome ) ->
                                            List.foldl
                                                (\( mailId, mail ) state2 ->
                                                    case mail.status of
                                                        MailInTransit mailTrainId ->
                                                            if trainId == mailTrainId then
                                                                let
                                                                    mail2 =
                                                                        { mail | status = MailWaitingPickup }
                                                                in
                                                                { mail = IdDict.insert mailId mail2 state2.mail
                                                                , mailChanges = ( mailId, mail2 ) :: state2.mailChanges
                                                                , diff = state2.diff
                                                                }

                                                            else
                                                                state2

                                                        _ ->
                                                            state2
                                                )
                                                { state | diff = diff }
                                                (IdDict.toList state.mail)

                                        ( StoppedAtPostOffice _, _ ) ->
                                            { state | diff = diff }

                                        ( _, StoppedAtPostOffice { userId } ) ->
                                            case Train.carryingMail state.mail trainId of
                                                Just ( mailId, mail ) ->
                                                    if mail.to == userId then
                                                        let
                                                            mail2 =
                                                                { mail | status = MailReceived { deliveryTime = time } }
                                                        in
                                                        { mail = IdDict.update mailId (\_ -> Just mail2) state.mail
                                                        , mailChanges = ( mailId, mail2 ) :: state.mailChanges
                                                        , diff = diff
                                                        }

                                                    else
                                                        { state | diff = diff }

                                                Nothing ->
                                                    case
                                                        MailEditor.getMailFrom userId state.mail
                                                            |> List.filter (\( _, mail ) -> mail.status == MailWaitingPickup)
                                                    of
                                                        ( mailId, mail ) :: _ ->
                                                            let
                                                                mail2 =
                                                                    { mail | status = MailInTransit trainId }
                                                            in
                                                            { mail = IdDict.update mailId (\_ -> Just mail2) state.mail
                                                            , mailChanges = ( mailId, mail2 ) :: state.mailChanges
                                                            , diff = diff
                                                            }

                                                        [] ->
                                                            { state | diff = diff }

                                        _ ->
                                            { state | diff = diff }
                                )
                                (\trainId train state ->
                                    { state | diff = IdDict.insert trainId (Train.NewTrain train) state.diff }
                                )
                                model.lastWorldUpdateTrains
                                newTrains
                                { mailChanges = [], mail = model.mail, diff = IdDict.empty }
                    in
                    ( { model
                        | lastWorldUpdate = Just time
                        , trains = newTrains
                        , lastWorldUpdateTrains = model.trains
                        , mail = mergeTrains.mail
                      }
                    , broadcast
                        (\sessionId clientId ->
                            let
                                maybeUserId =
                                    getUserFromSessionId sessionId model |> Maybe.map Tuple.first
                            in
                            Nonempty
                                (Change.ServerChange (ServerWorldUpdateBroadcast mergeTrains.diff))
                                (List.map
                                    (\( mailId, mail ) ->
                                        (case ( Just mail.to == maybeUserId, mail.status ) of
                                            ( True, MailReceived { deliveryTime } ) ->
                                                ServerReceivedMail
                                                    { mailId = mailId
                                                    , from = mail.from
                                                    , content = mail.content
                                                    , deliveryTime = deliveryTime
                                                    }

                                            _ ->
                                                ServerMailStatusChanged mailId mail.status
                                        )
                                            |> Change.ServerChange
                                    )
                                    mergeTrains.mailChanges
                                )
                                |> ChangeBroadcast
                                |> Just
                        )
                        model
                    )

                Nothing ->
                    ( { model | lastWorldUpdate = Just time }, Command.none )

        SentInviteEmail inviteToken result ->
            ( { model
                | invites =
                    AssocList.update
                        inviteToken
                        (Maybe.map
                            (\a ->
                                { a
                                    | emailResult =
                                        case result of
                                            Ok ok ->
                                                EmailSent ok

                                            Err error ->
                                                EmailSendFailed error
                                }
                            )
                        )
                        model.invites
              }
            , Command.none
            )

        CheckConnectionTimeElapsed ->
            ( model, Effect.Lamdera.broadcast CheckConnectionBroadcast )


addError : Effect.Time.Posix -> BackendError -> BackendModel -> BackendModel
addError time error model =
    { model | errors = ( time, error ) :: model.errors }


backendUserId : Id UserId
backendUserId =
    Id.fromInt -1


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUserData )
getUserFromSessionId sessionId model =
    case Dict.get (Effect.Lamdera.sessionIdToString sessionId) model.userSessions of
        Just { userId } ->
            case userId of
                Just userId2 ->
                    case IdDict.get userId2 model.users of
                        Just user ->
                            Just ( userId2, user )

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


asUser :
    SessionId
    -> BackendModel
    -> (Id UserId -> BackendUserData -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asUser sessionId model updateFunc =
    case getUserFromSessionId sessionId model of
        Just ( userId, user ) ->
            updateFunc userId user model

        Nothing ->
            ( model, Command.none )


broadcastLocalChange :
    Effect.Time.Posix
    -> ClientId
    -> Nonempty ( Id EventId, Change.LocalChange )
    -> Id UserId
    -> BackendUserData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
broadcastLocalChange time clientId changes userId user model =
    let
        ( model2, ( eventId, originalChange ), firstMsg ) =
            updateLocalChange time userId user (Nonempty.head changes) model

        ( model3, originalChanges2, serverChanges ) =
            Nonempty.tail changes
                |> List.foldl
                    (\change ( model_, originalChanges, serverChanges_ ) ->
                        case IdDict.get userId model_.users of
                            Just user2 ->
                                let
                                    ( newModel, ( eventId2, originalChange2 ), serverChange_ ) =
                                        updateLocalChange time userId user2 change model_
                                in
                                ( newModel
                                , Nonempty.cons (Change.LocalChange eventId2 originalChange2) originalChanges
                                , Nonempty.cons serverChange_ serverChanges_
                                )

                            Nothing ->
                                ( model_, originalChanges, serverChanges_ )
                    )
                    ( model2
                    , Nonempty.singleton (Change.LocalChange eventId originalChange)
                    , Nonempty.singleton firstMsg
                    )
                |> (\( a, b, c ) -> ( a, Nonempty.reverse b, Nonempty.reverse c ))
    in
    ( model3
    , broadcast
        (\_ clientId_ ->
            if clientId == clientId_ then
                ChangeBroadcast originalChanges2 |> Just

            else
                Nonempty.toList serverChanges
                    |> List.filterMap (Maybe.map Change.ServerChange)
                    |> Nonempty.fromList
                    |> Maybe.map ChangeBroadcast
        )
        model3
    )


generateSecretId : Effect.Time.Posix -> { a | secretLinkCounter : Int } -> ( SecretId b, { a | secretLinkCounter : Int } )
generateSecretId currentTime model =
    ( Env.secretKey
        ++ "_"
        ++ String.fromInt (Effect.Time.posixToMillis currentTime)
        ++ "_"
        ++ String.fromInt model.secretLinkCounter
        |> Crypto.Hash.sha256
        |> Id.secretFromString
    , { model | secretLinkCounter = model.secretLinkCounter + 1 }
    )


updateFromFrontend :
    Bool
    -> Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend isProduction currentTime sessionId clientId msg model =
    case msg of
        ConnectToBackend requestData maybeToken ->
            requestDataUpdate currentTime sessionId clientId requestData maybeToken model

        GridChange changes ->
            asUser
                sessionId
                model
                (broadcastLocalChange currentTime clientId changes)

        ChangeViewBounds bounds ->
            case
                Dict.get (Effect.Lamdera.sessionIdToString sessionId) model.userSessions
                    |> Maybe.andThen (\{ clientIds } -> AssocList.get clientId clientIds)
            of
                Just oldBounds ->
                    let
                        newCells : List ( Coord CellUnit, GridCell.CellData )
                        newCells =
                            Bounds.coordRangeFold
                                (\coord newCells_ ->
                                    if Bounds.contains coord oldBounds then
                                        newCells_

                                    else
                                        case Grid.getCell coord model.grid of
                                            Just cell ->
                                                ( coord, GridCell.cellToData cell ) :: newCells_

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
                                (Effect.Lamdera.sessionIdToString sessionId)
                                (Maybe.map
                                    (\session ->
                                        { session
                                            | clientIds =
                                                AssocList.update
                                                    clientId
                                                    (\_ -> Just bounds)
                                                    session.clientIds
                                        }
                                    )
                                )
                                model.userSessions
                      }
                    , ViewBoundsChange bounds newCells
                        |> Change.ClientChange
                        |> Nonempty.fromElement
                        |> ChangeBroadcast
                        |> Effect.Lamdera.sendToFrontend clientId
                    )

                Nothing ->
                    ( model, Command.none )

        PingRequest ->
            ( model, PingResponse currentTime |> Effect.Lamdera.sendToFrontend clientId )

        SendLoginEmailRequest a ->
            case Untrusted.emailAddress a of
                Valid emailAddress ->
                    let
                        ( loginToken, model2 ) =
                            generateSecretId currentTime model

                        loginEmailUrl : String
                        loginEmailUrl =
                            Env.domain
                                ++ Route.encode
                                    (InternalRoute
                                        { loginOrInviteToken = Just (LoginToken2 loginToken)
                                        , showInbox = False
                                        , viewPoint = Coord.origin
                                        }
                                    )
                    in
                    case IdDict.toList model.users |> List.find (\( _, user ) -> user.emailAddress == emailAddress) of
                        Just ( userId, _ ) ->
                            --let
                            --    _ =
                            --        Debug.log "loginUrl" loginEmailUrl
                            --in
                            ( { model2
                                | pendingLoginTokens =
                                    AssocList.insert
                                        loginToken
                                        { requestTime = currentTime, userId = userId, requestedBy = sessionId }
                                        model2.pendingLoginTokens
                              }
                            , Command.batch
                                [ SendLoginEmailResponse emailAddress |> Effect.Lamdera.sendToFrontend clientId
                                , sendEmail
                                    isProduction
                                    (SentLoginEmail currentTime emailAddress)
                                    (NonemptyString 'L' "ogin Email")
                                    ("DO NOT click the following link if you didn't request this email.\n"
                                        ++ "\n"
                                        ++ "If you did, click the following link to login to town-collab\n"
                                        ++ loginEmailUrl
                                    )
                                    (Email.Html.div
                                        []
                                        [ Email.Html.div
                                            []
                                            [ Email.Html.b [] [ Email.Html.text "DO NOT" ]
                                            , Email.Html.text " click the following link if you didn't request this email."
                                            ]
                                        , Email.Html.div
                                            []
                                            [ Email.Html.text "If you did, "
                                            , Email.Html.a
                                                [ Email.Html.Attributes.href loginEmailUrl ]
                                                [ Email.Html.text "click here" ]
                                            , Email.Html.text " to login to town-collab"
                                            ]
                                        ]
                                    )
                                    emailAddress
                                ]
                            )

                        Nothing ->
                            ( model2, SendLoginEmailResponse emailAddress |> Effect.Lamdera.sendToFrontend clientId )

                Invalid ->
                    ( model, Command.none )

        SendInviteEmailRequest a ->
            case Untrusted.emailAddress a of
                Valid emailAddress ->
                    asUser
                        sessionId
                        model
                        (\userId user model2 ->
                            -- Check if email address has already accepted an invite
                            if IdDict.toList model2.users |> List.any (\( _, user2 ) -> user2.emailAddress == emailAddress) then
                                ( model2, Effect.Lamdera.sendToFrontend clientId (SendInviteEmailResponse emailAddress) )

                            else
                                let
                                    --_ =
                                    --    Debug.log "inviteUrl" inviteUrl
                                    ( inviteToken, model3 ) =
                                        generateSecretId currentTime model2

                                    inviteUrl : String
                                    inviteUrl =
                                        Env.domain
                                            ++ Route.encode
                                                (InternalRoute
                                                    { viewPoint = Coord.origin
                                                    , showInbox = False
                                                    , loginOrInviteToken = Just (InviteToken2 inviteToken)
                                                    }
                                                )
                                in
                                ( { model3
                                    | invites =
                                        AssocList.insert
                                            inviteToken
                                            { invitedBy = userId
                                            , invitedAt = currentTime
                                            , invitedEmailAddress = emailAddress
                                            , emailResult = EmailSending
                                            }
                                            model3.invites
                                  }
                                , Command.batch
                                    [ sendEmail
                                        isProduction
                                        (SentInviteEmail inviteToken)
                                        (NonemptyString 'T' "own-collab invitation")
                                        ("You've been invited by "
                                            ++ DisplayName.nameAndId user.name userId
                                            ++ " to join town-collab! Click this link to join "
                                            ++ inviteUrl
                                            ++ ". If you weren't expecting this email then it is safe to ignore."
                                        )
                                        (Email.Html.div
                                            []
                                            [ Email.Html.text
                                                ("You've been invited by "
                                                    ++ DisplayName.nameAndId user.name userId
                                                    ++ " to join town-collab! "
                                                )
                                            , Email.Html.a
                                                [ Email.Html.Attributes.href inviteUrl ]
                                                [ Email.Html.text "Click here to join" ]
                                            , Email.Html.text ". If you weren't expecting this email then it is safe to ignore."
                                            ]
                                        )
                                        emailAddress
                                    , Effect.Lamdera.sendToFrontend clientId (SendInviteEmailResponse emailAddress)
                                    ]
                                )
                        )

                Invalid ->
                    ( model, Command.none )

        PostOfficePositionRequest ->
            asUser
                sessionId
                model
                (\userId _ model2 ->
                    ( model2
                    , Grid.getPostOffice userId model2.grid
                        |> PostOfficePositionResponse
                        |> Effect.Lamdera.sendToFrontend clientId
                    )
                )


{-| Allow a client to say when something happened but restrict how far it can be away from the current time.
-}
adjustEventTime : Effect.Time.Posix -> Effect.Time.Posix -> Effect.Time.Posix
adjustEventTime currentTime eventTime =
    if Duration.from currentTime eventTime |> Quantity.abs |> Quantity.lessThan (Duration.seconds 1) then
        eventTime

    else
        currentTime


updateLocalChange :
    Effect.Time.Posix
    -> Id UserId
    -> BackendUserData
    -> ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, ( Id EventId, Change.LocalChange ), Maybe ServerChange )
updateLocalChange time userId user (( eventId, change ) as originalChange) model =
    let
        invalidChange =
            ( eventId, Change.InvalidChange )
    in
    case change of
        Change.LocalUndo ->
            case Undo.undo user of
                Just newUser ->
                    let
                        undoMoveAmount : Dict.Dict RawCellCoord Int
                        undoMoveAmount =
                            Dict.map (\_ a -> -a) user.undoCurrent

                        newGrid : Grid
                        newGrid =
                            Grid.moveUndoPoint userId undoMoveAmount model.grid

                        trainsToRemove : List (Id TrainId)
                        trainsToRemove =
                            IdDict.toList model.trains
                                |> List.filterMap
                                    (\( trainId, train ) ->
                                        if Train.owner train == userId then
                                            case
                                                Grid.getTile
                                                    -- Add an offset since the top of the train home isn't collidable
                                                    (Train.home train |> Coord.plus (Coord.xy 1 1))
                                                    newGrid
                                            of
                                                Just tile ->
                                                    case
                                                        ( Tile.getData tile.tile |> .railPath
                                                        , tile.position == Train.home train
                                                        , tile.userId == userId
                                                        )
                                                    of
                                                        ( SingleRailPath path, True, True ) ->
                                                            if Train.homePath train == path then
                                                                Nothing

                                                            else
                                                                Just trainId

                                                        _ ->
                                                            Just trainId

                                                Nothing ->
                                                    Just trainId

                                        else
                                            Nothing
                                    )
                    in
                    ( List.foldl
                        removeTrain
                        { model | grid = newGrid }
                        trainsToRemove
                        |> updateUser userId (always newUser)
                    , originalChange
                    , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> Just
                    )

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalGridChange localChange ->
            let
                ( cellPosition, localPosition ) =
                    Grid.worldToCellAndLocalCoord localChange.position

                maybeTrain : Maybe ( Id TrainId, Train )
                maybeTrain =
                    if IdDict.size model.trains < 50 then
                        Train.handleAddingTrain model.trains userId localChange.change localChange.position

                    else
                        Nothing

                { grid, removed, newCells } =
                    Grid.addChange (Grid.localChangeToChange userId localChange) model.grid
            in
            case Train.canRemoveTiles time removed model.trains of
                Ok trainsToRemove ->
                    ( List.map Tuple.first trainsToRemove
                        |> List.foldl
                            removeTrain
                            { model
                                | grid =
                                    Grid.addChange (Grid.localChangeToChange userId localChange) model.grid
                                        |> .grid
                                , trains =
                                    case maybeTrain of
                                        Just ( trainId, train ) ->
                                            IdDict.insert trainId train model.trains

                                        Nothing ->
                                            model.trains
                            }
                        |> LocalGrid.addCows newCells
                        |> updateUser
                            userId
                            (always
                                { user
                                    | undoCurrent =
                                        LocalGrid.incrementUndoCurrent cellPosition localPosition user.undoCurrent
                                }
                            )
                    , originalChange
                    , ServerGridChange
                        { gridChange = Grid.localChangeToChange userId localChange, newCells = newCells }
                        |> Just
                    )

                Err _ ->
                    ( model, invalidChange, Nothing )

        Change.LocalRedo ->
            case Undo.redo user of
                Just newUser ->
                    let
                        undoMoveAmount =
                            newUser.undoCurrent
                    in
                    ( { model
                        | grid = Grid.moveUndoPoint userId undoMoveAmount model.grid
                      }
                        |> updateUser userId (always newUser)
                    , originalChange
                    , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> Just
                    )

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalAddUndo ->
            ( updateUser userId Undo.add model, originalChange, Nothing )

        Change.InvalidChange ->
            ( model, originalChange, Nothing )

        PickupCow cowId position time2 ->
            let
                isCowHeld =
                    IdDict.toList model.users
                        |> List.any
                            (\( _, user2 ) ->
                                case user2.cursor of
                                    Just cursor ->
                                        Maybe.map .cowId cursor.holdingCow == Just cowId

                                    Nothing ->
                                        False
                            )
            in
            if isCowHeld then
                ( model, ( eventId, InvalidChange ), Nothing )

            else
                ( updateUser
                    userId
                    (\user2 ->
                        { user2
                            | cursor =
                                { position = position
                                , holdingCow = Just { cowId = cowId, pickupTime = time2 }
                                }
                                    |> Just
                        }
                    )
                    model
                , ( eventId, PickupCow cowId position (adjustEventTime time time2) )
                , ServerPickupCow userId cowId position time2 |> Just
                )

        DropCow cowId position time2 ->
            case IdDict.get userId model.users |> Maybe.andThen .cursor of
                Just cursor ->
                    case cursor.holdingCow of
                        Just holdingCow ->
                            if holdingCow.cowId == cowId then
                                ( updateUser
                                    userId
                                    (\user2 -> { user2 | cursor = Just { position = position, holdingCow = Nothing } })
                                    { model
                                        | cows =
                                            IdDict.update
                                                cowId
                                                (Maybe.map (\cow -> { cow | position = position }))
                                                model.cows
                                    }
                                , ( eventId, DropCow cowId position (adjustEventTime time time2) )
                                , ServerDropCow userId cowId position |> Just
                                )

                            else
                                ( model, ( eventId, InvalidChange ), Nothing )

                        Nothing ->
                            ( model, ( eventId, InvalidChange ), Nothing )

                Nothing ->
                    ( model, ( eventId, InvalidChange ), Nothing )

        MoveCursor position ->
            ( updateUser
                userId
                (\user2 ->
                    { user2
                        | cursor =
                            (case user2.cursor of
                                Just cursor ->
                                    { cursor | position = position }

                                Nothing ->
                                    { position = position, holdingCow = Nothing }
                            )
                                |> Just
                    }
                )
                model
            , originalChange
            , ServerMoveCursor userId position |> Just
            )

        ChangeHandColor colors ->
            ( updateUser
                userId
                (\user2 -> { user2 | handColor = colors })
                model
            , originalChange
            , ServerChangeHandColor userId colors |> Just
            )

        ToggleRailSplit coord ->
            ( { model | grid = Grid.toggleRailSplit coord model.grid }
            , originalChange
            , ServerToggleRailSplit coord |> Just
            )

        ChangeDisplayName displayName ->
            ( { model | users = IdDict.insert userId { user | name = displayName } model.users }
            , originalChange
            , ServerChangeDisplayName userId displayName |> Just
            )

        SubmitMail { to, content } ->
            let
                mailId =
                    IdDict.size model.mail |> Id.fromInt

                newMail : IdDict MailId BackendMail
                newMail =
                    IdDict.insert
                        mailId
                        { content = content
                        , status = MailWaitingPickup
                        , from = userId
                        , to = to
                        }
                        model.mail
            in
            ( { model
                | mail = newMail
                , users = IdDict.insert userId { user | mailDrafts = IdDict.remove to user.mailDrafts } model.users
              }
            , originalChange
            , ServerSubmitMail { to = to, from = userId } |> Just
            )

        UpdateDraft { to, content } ->
            ( { model
                | users =
                    IdDict.insert
                        userId
                        { user | mailDrafts = IdDict.insert to content user.mailDrafts }
                        model.users
              }
            , originalChange
            , Nothing
            )

        TeleportHomeTrainRequest trainId teleportTime ->
            let
                adjustedTime =
                    adjustEventTime time teleportTime
            in
            ( { model
                | trains =
                    IdDict.update
                        trainId
                        (Maybe.map (Train.startTeleportingHome adjustedTime))
                        model.trains
              }
            , ( eventId, TeleportHomeTrainRequest trainId adjustedTime )
            , ServerTeleportHomeTrainRequest trainId adjustedTime |> Just
            )

        LeaveHomeTrainRequest trainId leaveTime ->
            let
                adjustedTime =
                    adjustEventTime time leaveTime
            in
            ( { model | trains = IdDict.update trainId (Maybe.map (Train.leaveHome adjustedTime)) model.trains }
            , ( eventId, LeaveHomeTrainRequest trainId adjustedTime )
            , ServerLeaveHomeTrainRequest trainId adjustedTime |> Just
            )

        ViewedMail mailId ->
            case IdDict.get mailId model.mail of
                Just mail ->
                    case ( mail.to == userId, mail.status ) of
                        ( True, MailReceived data ) ->
                            ( { model
                                | mail =
                                    IdDict.insert mailId { mail | status = MailReceivedAndViewed data } model.mail
                              }
                            , originalChange
                            , ServerViewedMail mailId userId |> Just
                            )

                        _ ->
                            ( model, invalidChange, Nothing )

                Nothing ->
                    ( model, invalidChange, Nothing )

        SetAllowEmailNotifications allow ->
            ( { model | users = IdDict.insert userId { user | allowEmailNotifications = allow } model.users }
            , originalChange
            , Nothing
            )


removeTrain : Id TrainId -> BackendModel -> BackendModel
removeTrain trainId model =
    { model
        | trains = IdDict.remove trainId model.trains
        , mail =
            IdDict.map
                (\_ mail ->
                    case mail.status of
                        MailInTransit trainId2 ->
                            if trainId == trainId2 then
                                { mail | status = MailWaitingPickup }

                            else
                                mail

                        MailWaitingPickup ->
                            mail

                        MailReceived _ ->
                            mail

                        MailReceivedAndViewed _ ->
                            mail
                )
                model.mail
    }


updateUser : Id UserId -> (BackendUserData -> BackendUserData) -> BackendModel -> BackendModel
updateUser userId updateUserFunc model =
    { model | users = IdDict.update userId (Maybe.map updateUserFunc) model.users }


{-| Gets globally hidden users known to a specific user.
-}
hiddenUsers :
    Maybe (Id UserId)
    -> { a | users : IdDict UserId { b | hiddenForAll : Bool } }
    -> EverySet (Id UserId)
hiddenUsers userId model =
    model.users
        |> IdDict.toList
        |> List.filterMap
            (\( userId_, { hiddenForAll } ) ->
                if hiddenForAll && userId /= Just userId_ then
                    Just userId_

                else
                    Nothing
            )
        |> EverySet.fromList


getUserInbox : Id UserId -> BackendModel -> IdDict MailId MailEditor.ReceivedMail
getUserInbox userId model =
    IdDict.filterMap
        (\_ mail ->
            if mail.to == userId then
                case mail.status of
                    MailWaitingPickup ->
                        Nothing

                    MailInTransit _ ->
                        Nothing

                    MailReceived { deliveryTime } ->
                        Just
                            { content = mail.content
                            , from = mail.from
                            , isViewed = False
                            , deliveryTime = deliveryTime
                            }

                    MailReceivedAndViewed { deliveryTime } ->
                        Just
                            { content = mail.content
                            , from = mail.from
                            , isViewed = True
                            , deliveryTime = deliveryTime
                            }

            else
                Nothing
        )
        model.mail


requestDataUpdate :
    Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> Bounds CellUnit
    -> Maybe LoginOrInviteToken
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
requestDataUpdate currentTime sessionId clientId viewBounds maybeToken model =
    let
        checkLogin () =
            ( case getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
                    LoggedIn
                        { userId = userId
                        , undoCurrent = user.undoCurrent
                        , undoHistory = user.undoHistory
                        , redoHistory = user.redoHistory
                        , mailDrafts = user.mailDrafts
                        , emailAddress = user.emailAddress
                        , inbox = getUserInbox userId model
                        , allowEmailNotifications = user.allowEmailNotifications
                        }

                Nothing ->
                    NotLoggedIn
            , model
            , Nothing
            )

        ( userStatus, model2, maybeRequestedBy ) =
            case maybeToken of
                Just (LoginToken2 loginToken) ->
                    case AssocList.get loginToken model.pendingLoginTokens of
                        Just data ->
                            if Duration.from data.requestTime currentTime |> Quantity.lessThan (Duration.minutes 10) then
                                case IdDict.get data.userId model.users of
                                    Just user ->
                                        ( LoggedIn
                                            { userId = data.userId
                                            , undoCurrent = user.undoCurrent
                                            , undoHistory = user.undoHistory
                                            , redoHistory = user.redoHistory
                                            , mailDrafts = user.mailDrafts
                                            , emailAddress = user.emailAddress
                                            , inbox = getUserInbox data.userId model
                                            , allowEmailNotifications = user.allowEmailNotifications
                                            }
                                        , { model | pendingLoginTokens = AssocList.remove loginToken model.pendingLoginTokens }
                                        , Just data.requestedBy
                                        )

                                    Nothing ->
                                        ( NotLoggedIn, addError currentTime (UserNotFoundWhenLoggingIn data.userId) model, Nothing )

                            else
                                checkLogin ()

                        Nothing ->
                            checkLogin ()

                Just (InviteToken2 inviteToken) ->
                    case AssocList.get inviteToken model.invites of
                        Just invite ->
                            let
                                userId : Id UserId
                                userId =
                                    Train.nextId model.users

                                ( model4, newUser ) =
                                    createUser userId invite.invitedEmailAddress model
                            in
                            ( LoggedIn
                                { userId = userId
                                , undoCurrent = newUser.undoCurrent
                                , undoHistory = newUser.undoHistory
                                , redoHistory = newUser.redoHistory
                                , mailDrafts = newUser.mailDrafts
                                , emailAddress = newUser.emailAddress
                                , inbox = getUserInbox userId model
                                , allowEmailNotifications = newUser.allowEmailNotifications
                                }
                            , { model4
                                | invites = AssocList.remove inviteToken model.invites
                                , users =
                                    IdDict.update
                                        invite.invitedBy
                                        (Maybe.map (\user -> { user | acceptedInvites = IdDict.insert userId () user.acceptedInvites }))
                                        model4.users
                              }
                            , Nothing
                            )

                        Nothing ->
                            checkLogin ()

                Nothing ->
                    checkLogin ()

        model3 : BackendModel
        model3 =
            addSession sessionId clientId viewBounds userStatus model2
                |> (case maybeRequestedBy of
                        Just requestedBy ->
                            addSession requestedBy clientId viewBounds userStatus

                        Nothing ->
                            identity
                   )

        loadingData : LoadingData_
        loadingData =
            { grid = Grid.region viewBounds model3.grid
            , userStatus = userStatus
            , viewBounds = viewBounds
            , trains = model3.trains
            , mail = IdDict.map (\_ mail -> { status = mail.status, from = mail.from, to = mail.to }) model3.mail
            , cows = model3.cows
            , cursors = IdDict.filterMap (\_ a -> a.cursor) model3.users
            , users = IdDict.map (\_ a -> backendUserToFrontend a) model3.users
            }

        frontendUser =
            case userStatus of
                LoggedIn loggedIn ->
                    case IdDict.get loggedIn.userId model3.users of
                        Just user ->
                            backendUserToFrontend user

                        Nothing ->
                            { handColor = Cursor.defaultColors, name = DisplayName.default }

                NotLoggedIn ->
                    { handColor = Cursor.defaultColors, name = DisplayName.default }
    in
    ( model3
    , Command.batch
        [ Effect.Lamdera.sendToFrontend clientId (LoadingData loadingData)
        , case ( maybeToken, userStatus ) of
            ( Just _, LoggedIn loggedIn ) ->
                broadcast
                    (\sessionId2 clientId2 ->
                        if clientId2 == clientId then
                            Nothing

                        else if sessionId2 == sessionId || Just sessionId2 == maybeRequestedBy then
                            ServerYouLoggedIn loggedIn frontendUser
                                |> Change.ServerChange
                                |> Nonempty.singleton
                                |> ChangeBroadcast
                                |> Just

                        else
                            ServerUserConnected loggedIn.userId frontendUser
                                |> Change.ServerChange
                                |> Nonempty.singleton
                                |> ChangeBroadcast
                                |> Just
                    )
                    model3

            _ ->
                Command.none
        ]
    )


backendUserToFrontend : BackendUserData -> FrontendUser
backendUserToFrontend user =
    { name = user.name
    , handColor = user.handColor
    }


addSession : SessionId -> ClientId -> Bounds CellUnit -> UserStatus -> BackendModel -> BackendModel
addSession sessionId clientId viewBounds userStatus model =
    { model
        | userSessions =
            Dict.update
                (Effect.Lamdera.sessionIdToString sessionId)
                (\maybeSession ->
                    (case maybeSession of
                        Just session ->
                            { clientIds = AssocList.insert clientId viewBounds session.clientIds
                            , userId =
                                case userStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.userId

                                    NotLoggedIn ->
                                        Nothing
                            }

                        Nothing ->
                            { clientIds = AssocList.singleton clientId viewBounds
                            , userId =
                                case userStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.userId

                                    NotLoggedIn ->
                                        Nothing
                            }
                    )
                        |> Just
                )
                model.userSessions
    }


createUser : Id UserId -> EmailAddress -> BackendModel -> ( BackendModel, BackendUserData )
createUser userId emailAddress model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            , mailDrafts = IdDict.empty
            , cursor = Nothing
            , handColor = Cursor.defaultColors
            , emailAddress = emailAddress
            , acceptedInvites = IdDict.empty
            , name = DisplayName.default
            , allowEmailNotifications = True
            }
    in
    ( { model | users = IdDict.insert userId userBackendData model.users }, userBackendData )


broadcast : (SessionId -> ClientId -> Maybe ToFrontend) -> BackendModel -> Command BackendOnly ToFrontend BackendMsg
broadcast msgFunc model =
    model.userSessions
        |> Dict.toList
        |> List.concatMap
            (\( sessionId, { clientIds } ) ->
                AssocList.keys clientIds |> List.map (Tuple.pair (Effect.Lamdera.sessionIdFromString sessionId))
            )
        |> List.filterMap (\( sessionId, clientId ) -> msgFunc sessionId clientId |> Maybe.map (Effect.Lamdera.sendToFrontend clientId))
        |> Command.batch
