module Backend exposing
    ( app
    , init
    , notifyAdminWait
    , sendConfirmationEmailRateLimit
    , update
    , updateFromFrontend
    )

import AssocList
import Bounds exposing (Bounds)
import Change exposing (ClientChange(..), LocalChange(..), ServerChange(..))
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Dict
import Duration exposing (Duration)
import Email.Html
import EmailAddress exposing (EmailAddress)
import Env
import EverySet exposing (EverySet)
import Grid exposing (Grid)
import GridCell
import Id exposing (EventId, Id, MailId, TrainId, UserId)
import Lamdera exposing (ClientId, SessionId)
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LocalGrid
import MailEditor exposing (BackendMail, MailStatus(..))
import Quantity exposing (Quantity(..))
import SendGrid exposing (Email)
import String.Nonempty exposing (NonemptyString(..))
import Task
import Tile exposing (Tile(..))
import Time
import Train exposing (Status(..), Train)
import Types exposing (..)
import Undo
import Units exposing (CellUnit, WorldUnit)
import UrlHelper exposing (ConfirmEmailKey(..), InternalRoute(..), UnsubscribeEmailKey(..))


app =
    Lamdera.backend
        { init = ( init, Cmd.none )
        , update = update
        , updateFromFrontend =
            \sessionId clientId msg model ->
                ( model, Time.now |> Task.perform (UpdateFromFrontend sessionId clientId msg) )
        , subscriptions = subscriptions
        }


subscriptions : BackendModel -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onDisconnect UserDisconnected
        , Time.every (notifyAdminWait |> Duration.inMilliseconds) NotifyAdminTimeElapsed
        , Time.every 1000 WorldUpdateTimeElapsed
        ]


init : BackendModel
init =
    { grid = Grid.empty
    , userSessions = Dict.empty
    , users = Dict.empty
    , usersHiddenRecently = []
    , secretLinkCounter = 0
    , errors = []
    , trains = AssocList.empty
    , lastWorldUpdate = Nothing
    , mail = AssocList.empty
    }


notifyAdminWait : Duration
notifyAdminWait =
    String.toFloat Env.notifyAdminWaitInHours |> Maybe.map Duration.hours |> Maybe.withDefault (Duration.hours 3)


sendEmail msg subject content to =
    SendGrid.sendEmail msg Env.sendGridKey (asciiCollabEmail subject content to)


asciiCollabEmail : NonemptyString -> Email.Html.Html -> EmailAddress -> Email
asciiCollabEmail subject content to =
    SendGrid.htmlEmail
        { subject = subject
        , content = content
        , to = Nonempty.fromElement to
        , nameOfSender = "ascii-collab"
        , emailAddressOfSender =
            EmailAddress.fromString "no-reply@ascii-collab.app"
                -- This should never happen
                |> Maybe.withDefault to
        }


update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
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
            , Cmd.none
            )

        NotifyAdminTimeElapsed time ->
            let
                ( newModel, cmd ) =
                    notifyAdmin model
            in
            ( newModel, cmd )

        NotifyAdminEmailSent ->
            ( model, Cmd.none )

        UpdateFromFrontend sessionId clientId toBackendMsg time ->
            updateFromFrontend time sessionId clientId toBackendMsg model

        ChangeEmailSent time email result ->
            case result of
                Ok _ ->
                    ( model, Cmd.none )

                Err error ->
                    ( addError time (SendGridError email error) model, Cmd.none )

        WorldUpdateTimeElapsed time ->
            case model.lastWorldUpdate of
                Just oldTime ->
                    let
                        newTrains : AssocList.Dict (Id TrainId) Train
                        newTrains =
                            case model.lastWorldUpdate of
                                Just lastWorldUpdate ->
                                    AssocList.map
                                        (\trainId train ->
                                            Train.moveTrain trainId Train.defaultMaxSpeed lastWorldUpdate time model train
                                        )
                                        model.trains

                                Nothing ->
                                    model.trains

                        updateMail : { mail : AssocList.Dict (Id MailId) BackendMail, mailChanged : Bool }
                        updateMail =
                            AssocList.merge
                                (\_ _ a -> a)
                                (\trainId oldTrain newTrain state ->
                                    case ( Train.status oldTime oldTrain, Train.status time newTrain ) of
                                        ( TeleportingHome _, WaitingAtHome ) ->
                                            { mail =
                                                AssocList.map
                                                    (\_ mail ->
                                                        case mail.status of
                                                            MailInTransit mailTrainId ->
                                                                if trainId == mailTrainId then
                                                                    { mail | status = MailWaitingPickup }

                                                                else
                                                                    mail

                                                            _ ->
                                                                mail
                                                    )
                                                    state.mail
                                            , mailChanged = True
                                            }

                                        ( StoppedAtPostOffice _, _ ) ->
                                            state

                                        ( _, StoppedAtPostOffice { userId } ) ->
                                            case Train.carryingMail state.mail trainId of
                                                Just ( mailId, mail ) ->
                                                    { mail =
                                                        AssocList.update
                                                            mailId
                                                            (\_ -> Just { mail | status = MailReceived })
                                                            state.mail
                                                    , mailChanged = True
                                                    }

                                                Nothing ->
                                                    case
                                                        MailEditor.getMailFrom userId state.mail
                                                            |> List.filter (\( _, mail ) -> mail.status == MailWaitingPickup)
                                                    of
                                                        ( mailId, mail ) :: _ ->
                                                            { mail =
                                                                AssocList.update
                                                                    mailId
                                                                    (\_ -> Just { mail | status = MailInTransit trainId })
                                                                    state.mail
                                                            , mailChanged = True
                                                            }

                                                        [] ->
                                                            state

                                        _ ->
                                            state
                                )
                                (\_ _ a -> a)
                                model.trains
                                newTrains
                                { mailChanged = False, mail = model.mail }
                    in
                    ( { model
                        | lastWorldUpdate = Just time
                        , trains = newTrains
                        , mail = updateMail.mail
                      }
                    , Cmd.batch
                        [ Lamdera.broadcast (TrainBroadcast newTrains)
                        , if updateMail.mailChanged then
                            AssocList.map (\_ mail -> MailEditor.backendMailToFrontend mail) updateMail.mail
                                |> MailBroadcast
                                |> Lamdera.broadcast

                          else
                            Cmd.none
                        ]
                    )

                Nothing ->
                    ( { model | lastWorldUpdate = Just time }, Cmd.none )


addError : Time.Posix -> BackendError -> BackendModel -> BackendModel
addError time error model =
    { model | errors = ( time, error ) :: model.errors }


notifyAdmin : BackendModel -> ( BackendModel, Cmd BackendMsg )
notifyAdmin model =
    let
        idToString =
            Id.toInt >> String.fromInt

        fullUrl point =
            Env.domain ++ "/" ++ UrlHelper.encodeUrl (UrlHelper.internalRoute point)

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
        ( model, Cmd.none )

    else
        ( { model | usersHiddenRecently = [] }
        , case Env.adminEmail of
            Just adminEmail ->
                sendEmail
                    (always NotifyAdminEmailSent)
                    (String.Nonempty.append_
                        (String.Nonempty.fromInt (List.length model.usersHiddenRecently))
                        " users hidden"
                    )
                    (Email.Html.text hidden)
                    adminEmail

            Nothing ->
                Cmd.none
        )


backendUserId : Id UserId
backendUserId =
    Id.fromInt -1


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUserData )
getUserFromSessionId sessionId model =
    case Dict.get sessionId model.userSessions of
        Just { userId } ->
            case Dict.get (Id.toInt userId) model.users of
                Just user ->
                    Just ( userId, user )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


broadcastLocalChange :
    ( Id UserId, BackendUserData )
    -> Nonempty ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, Cmd BackendMsg )
broadcastLocalChange userIdAndUser changes model =
    let
        ( model2, ( eventId, originalChange ), firstMsg ) =
            updateLocalChange userIdAndUser (Nonempty.head changes) model

        ( model3, originalChanges2, serverChanges ) =
            Nonempty.tail changes
                |> List.foldl
                    (\change ( model_, originalChanges, serverChanges_ ) ->
                        let
                            ( newModel, ( eventId2, originalChange2 ), serverChange_ ) =
                                updateLocalChange userIdAndUser change model_
                        in
                        ( newModel
                        , Nonempty.cons (Change.LocalChange eventId2 originalChange2) originalChanges
                        , Nonempty.cons serverChange_ serverChanges_
                        )
                    )
                    ( model2
                    , Nonempty.singleton (Change.LocalChange eventId originalChange)
                    , Nonempty.singleton firstMsg
                    )
                |> (\( a, b, c ) -> ( a, Nonempty.reverse b, Nonempty.reverse c ))
    in
    ( model3
    , broadcast
        (\sessionId_ _ ->
            case getUserFromSessionId sessionId_ model3 of
                Just ( userId_, _ ) ->
                    if Tuple.first userIdAndUser == userId_ then
                        ChangeBroadcast originalChanges2 |> Just

                    else
                        Nonempty.toList serverChanges
                            |> List.filterMap (Maybe.map Change.ServerChange)
                            |> Nonempty.fromList
                            |> Maybe.map ChangeBroadcast

                Nothing ->
                    Nothing
        )
        model3
    )


updateFromFrontend :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Cmd BackendMsg )
updateFromFrontend currentTime sessionId clientId msg model =
    case msg of
        ConnectToBackend requestData ->
            requestDataUpdate sessionId clientId requestData model

        GridChange changes ->
            case getUserFromSessionId sessionId model of
                Just userIdAndUser ->
                    broadcastLocalChange userIdAndUser changes model

                Nothing ->
                    ( model, Cmd.none )

        ChangeViewBounds bounds ->
            case
                Dict.get sessionId model.userSessions
                    |> Maybe.andThen (\{ clientIds } -> Dict.get clientId clientIds)
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
                        |> Lamdera.sendToFrontend clientId
                    )

                Nothing ->
                    ( model, Cmd.none )

        MailEditorToBackend mailEditorToBackend ->
            case mailEditorToBackend of
                MailEditor.SubmitMailRequest { content, to } ->
                    case getUserFromSessionId sessionId model of
                        Just ( userId, _ ) ->
                            let
                                newMail =
                                    AssocList.insert
                                        (AssocList.size model.mail |> Id.fromInt)
                                        { content = content
                                        , status = MailWaitingPickup
                                        , from = userId
                                        , to = to
                                        }
                                        model.mail
                            in
                            ( { model | mail = newMail }
                            , Cmd.batch
                                [ MailEditor.SubmitMailResponse |> MailEditorToFrontend |> Lamdera.sendToFrontend clientId
                                , MailBroadcast
                                    (AssocList.map (\_ mail -> MailEditor.backendMailToFrontend mail) newMail)
                                    |> Lamdera.broadcast
                                ]
                            )

                        Nothing ->
                            ( model, Cmd.none )

                MailEditor.UpdateMailEditorRequest mailEditor ->
                    case getUserFromSessionId sessionId model of
                        Just ( userId, _ ) ->
                            ( updateUser userId (\user -> { user | mailEditor = mailEditor }) model
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

        TeleportHomeTrainRequest trainId ->
            ( { model
                | trains =
                    AssocList.update trainId (Maybe.map (Train.startTeleportingHome currentTime)) model.trains
              }
            , Cmd.none
            )

        CancelTeleportHomeTrainRequest trainId ->
            ( { model | trains = AssocList.update trainId (Maybe.map (Train.cancelTeleportingHome currentTime)) model.trains }
            , Cmd.none
            )

        LeaveHomeTrainRequest trainId ->
            ( { model | trains = AssocList.update trainId (Maybe.map (Train.leaveHome currentTime)) model.trains }
            , Cmd.none
            )


sendConfirmationEmailRateLimit : Duration
sendConfirmationEmailRateLimit =
    Duration.seconds 10


generateKey : (String -> keyType) -> { a | secretLinkCounter : Int } -> ( keyType, { a | secretLinkCounter : Int } )
generateKey keyType model =
    ( Env.confirmationEmailKey
        ++ String.fromInt model.secretLinkCounter
        |> Crypto.Hash.sha256
        |> keyType
    , { model | secretLinkCounter = model.secretLinkCounter + 1 }
    )


updateLocalChange :
    ( Id UserId, BackendUserData )
    -> ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, ( Id EventId, Change.LocalChange ), Maybe ServerChange )
updateLocalChange ( userId, _ ) (( eventId, change ) as originalChange) model =
    let
        invalidChange =
            ( eventId, Change.InvalidChange )
    in
    case change of
        Change.LocalUndo ->
            case Dict.get (Id.toInt userId) model.users of
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
                              }
                                |> updateUser userId (always newUser)
                            , originalChange
                            , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> Just
                            )

                        Nothing ->
                            ( model, invalidChange, Nothing )

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalGridChange localChange ->
            case Dict.get (Id.toInt userId) model.users of
                Just user ->
                    let
                        ( cellPosition, localPosition ) =
                            Grid.worldToCellAndLocalCoord localChange.position

                        maybeTrain =
                            if AssocList.size model.trains < 50 then
                                Train.handleAddingTrain model.trains localChange.change localChange.position

                            else
                                Nothing
                    in
                    ( { model
                        | grid = Grid.addChange (Grid.localChangeToChange userId localChange) model.grid |> .grid
                        , trains =
                            case maybeTrain of
                                Just ( trainId, train ) ->
                                    AssocList.insert trainId train model.trains

                                Nothing ->
                                    model.trains
                      }
                        |> updateUser
                            userId
                            (always
                                { user
                                    | undoCurrent =
                                        LocalGrid.incrementUndoCurrent cellPosition localPosition user.undoCurrent
                                }
                            )
                    , originalChange
                    , ServerGridChange (Grid.localChangeToChange userId localChange) |> Just
                    )

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalRedo ->
            case Dict.get (Id.toInt userId) model.users of
                Just user ->
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

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalAddUndo ->
            ( updateUser userId Undo.add model, originalChange, Nothing )

        Change.LocalHideUser hideUserId hidePoint ->
            ( if userId == hideUserId then
                model

              else if Dict.member (Id.toInt hideUserId) model.users then
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
            , originalChange
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
            , originalChange
            , Nothing
            )

        Change.InvalidChange ->
            ( model, originalChange, Nothing )


updateUser : Id UserId -> (BackendUserData -> BackendUserData) -> BackendModel -> BackendModel
updateUser userId updateUserFunc model =
    { model | users = Dict.update (Id.toInt userId) (Maybe.map updateUserFunc) model.users }


{-| Gets globally hidden users known to a specific user.
-}
hiddenUsers :
    Maybe (Id UserId)
    -> { a | users : Dict.Dict Int { b | hiddenForAll : Bool } }
    -> EverySet (Id UserId)
hiddenUsers userId model =
    model.users
        |> Dict.toList
        |> List.filterMap
            (\( userId_, { hiddenForAll } ) ->
                if hiddenForAll && userId /= Just (Id.fromInt userId_) then
                    Just (Id.fromInt userId_)

                else
                    Nothing
            )
        |> EverySet.fromList


requestDataUpdate : SessionId -> ClientId -> Bounds CellUnit -> BackendModel -> ( BackendModel, Cmd BackendMsg )
requestDataUpdate sessionId clientId viewBounds model =
    let
        loadingData : ( Id UserId, BackendUserData ) -> LoadingData_
        loadingData ( userId, user ) =
            { user = userId
            , grid = Grid.region viewBounds model.grid
            , hiddenUsers = user.hiddenUsers
            , adminHiddenUsers = hiddenUsers (Just userId) model
            , undoHistory = user.undoHistory
            , redoHistory = user.redoHistory
            , undoCurrent = user.undoCurrent
            , viewBounds = viewBounds
            , trains = model.trains
            , mail = AssocList.map (\_ mail -> { status = mail.status, from = mail.from, to = mail.to }) model.mail
            , mailEditor = user.mailEditor
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
            , Lamdera.sendToFrontend clientId (LoadingData (loadingData ( userId, user )))
            )

        Nothing ->
            let
                userId =
                    Dict.size model.users |> Id.fromInt

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
            , Lamdera.sendToFrontend
                clientId
                (LoadingData (loadingData ( userId, userData )))
            )


createUser : Id UserId -> BackendModel -> ( BackendModel, BackendUserData )
createUser userId model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { hiddenUsers = EverySet.empty
            , hiddenForAll = False
            , undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            , mailEditor = MailEditor.init
            }
    in
    ( { model | users = Dict.insert (Id.toInt userId) userBackendData model.users }, userBackendData )


broadcast : (SessionId -> ClientId -> Maybe ToFrontend) -> BackendModel -> Cmd BackendMsg
broadcast msgFunc model =
    model.userSessions
        |> Dict.toList
        |> List.concatMap (\( sessionId, { clientIds } ) -> Dict.keys clientIds |> List.map (Tuple.pair sessionId))
        |> List.filterMap (\( sessionId, clientId ) -> msgFunc sessionId clientId |> Maybe.map (Lamdera.sendToFrontend clientId))
        |> Cmd.batch
