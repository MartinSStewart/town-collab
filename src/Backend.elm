module Backend exposing (app, app_)

import AssocList
import Bounds exposing (Bounds)
import Change exposing (ClientChange(..), LocalChange(..), ServerChange(..))
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Cursor
import Dict
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
import Id exposing (EventId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import Lamdera
import List.Extra as List
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LocalGrid exposing (UserStatus(..))
import MailEditor exposing (BackendMail, MailStatus(..))
import Postmark exposing (PostmarkSend, PostmarkSendResponse)
import Quantity exposing (Quantity(..))
import String.Nonempty exposing (NonemptyString(..))
import Tile exposing (RailPathType(..), Tile(..))
import Train exposing (Status(..), Train, TrainDiff)
import Types exposing (..)
import Undo
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Validation(..))
import UrlHelper exposing (InternalRoute(..), LoginToken(..))


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
        , Effect.Time.every Duration.second WorldUpdateTimeElapsed
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
            , trains = AssocList.empty
            , cows = IdDict.empty
            , lastWorldUpdateTrains = AssocList.empty
            , lastWorldUpdate = Nothing
            , mail = AssocList.empty
            , pendingLoginTokens = AssocList.empty
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


update : Bool -> BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update isProduction msg model =
    case msg of
        UserDisconnected sessionId clientId ->
            case getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
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

                Nothing ->
                    ( model, Command.none )

        NotifyAdminEmailSent ->
            ( model, Command.none )

        UpdateFromFrontend sessionId clientId toBackendMsg time ->
            updateFromFrontend isProduction time sessionId clientId toBackendMsg model

        SentLoginEmail time emailAddress result ->
            let
                _ =
                    Debug.log "a" result
            in
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError time (PostmarkError emailAddress error) model, Command.none )

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

                        mergeTrains :
                            { mail : AssocList.Dict (Id MailId) BackendMail
                            , mailChanged : Bool
                            , diff : AssocList.Dict (Id TrainId) TrainDiff
                            }
                        mergeTrains =
                            AssocList.merge
                                (\_ _ a -> a)
                                (\trainId oldTrain newTrain state ->
                                    let
                                        diff : AssocList.Dict (Id TrainId) TrainDiff
                                        diff =
                                            AssocList.insert trainId (Train.diff oldTrain newTrain) state.diff
                                    in
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
                                            , diff = diff
                                            }

                                        ( StoppedAtPostOffice _, _ ) ->
                                            { state | diff = diff }

                                        ( _, StoppedAtPostOffice { userId } ) ->
                                            case Train.carryingMail state.mail trainId of
                                                Just ( mailId, mail ) ->
                                                    if mail.to == userId then
                                                        { mail =
                                                            AssocList.update
                                                                mailId
                                                                (\_ -> Just { mail | status = MailReceived })
                                                                state.mail
                                                        , mailChanged = True
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
                                                            { mail =
                                                                AssocList.update
                                                                    mailId
                                                                    (\_ -> Just { mail | status = MailInTransit trainId })
                                                                    state.mail
                                                            , mailChanged = True
                                                            , diff = diff
                                                            }

                                                        [] ->
                                                            { state | diff = diff }

                                        _ ->
                                            { state | diff = diff }
                                )
                                (\trainId train state ->
                                    { state | diff = AssocList.insert trainId (Train.NewTrain train) state.diff }
                                )
                                model.lastWorldUpdateTrains
                                newTrains
                                { mailChanged = False, mail = model.mail, diff = AssocList.empty }
                    in
                    ( { model
                        | lastWorldUpdate = Just time
                        , trains = newTrains
                        , lastWorldUpdateTrains = model.trains
                        , mail = mergeTrains.mail
                      }
                    , Command.batch
                        [ WorldUpdateBroadcast mergeTrains.diff |> Effect.Lamdera.broadcast
                        , if mergeTrains.mailChanged then
                            AssocList.map (\_ mail -> MailEditor.backendMailToFrontend mail) mergeTrains.mail
                                |> MailBroadcast
                                |> Effect.Lamdera.broadcast

                          else
                            Command.none
                        ]
                    )

                Nothing ->
                    ( { model | lastWorldUpdate = Just time }, Command.none )


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


broadcastLocalChange :
    Effect.Time.Posix
    -> ( Id UserId, BackendUserData )
    -> Nonempty ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
broadcastLocalChange time userIdAndUser changes model =
    let
        ( model2, ( eventId, originalChange ), firstMsg ) =
            updateLocalChange time userIdAndUser (Nonempty.head changes) model

        ( model3, originalChanges2, serverChanges ) =
            Nonempty.tail changes
                |> List.foldl
                    (\change ( model_, originalChanges, serverChanges_ ) ->
                        let
                            ( newModel, ( eventId2, originalChange2 ), serverChange_ ) =
                                updateLocalChange time userIdAndUser change model_
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
    Bool
    -> Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend isProduction currentTime sessionId clientId msg model =
    case msg of
        ConnectToBackend requestData maybeLoginToken ->
            requestDataUpdate currentTime sessionId clientId requestData maybeLoginToken model

        GridChange changes ->
            case getUserFromSessionId sessionId model of
                Just userIdAndUser ->
                    broadcastLocalChange currentTime userIdAndUser changes model

                Nothing ->
                    ( model, Command.none )

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
                            , Command.batch
                                [ MailEditor.SubmitMailResponse |> MailEditorToFrontend |> Effect.Lamdera.sendToFrontend clientId
                                , MailBroadcast
                                    (AssocList.map (\_ mail -> MailEditor.backendMailToFrontend mail) newMail)
                                    |> Effect.Lamdera.broadcast
                                ]
                            )

                        Nothing ->
                            ( model, Command.none )

                MailEditor.UpdateMailEditorRequest mailEditor ->
                    case getUserFromSessionId sessionId model of
                        Just ( userId, _ ) ->
                            ( updateUser userId (\user -> { user | mailEditor = mailEditor }) model
                            , Command.none
                            )

                        Nothing ->
                            ( model, Command.none )

        TeleportHomeTrainRequest trainId teleportTime ->
            ( { model
                | trains =
                    AssocList.update
                        trainId
                        (Maybe.map (Train.startTeleportingHome (adjustEventTime currentTime teleportTime)))
                        model.trains
              }
            , Command.none
            )

        CancelTeleportHomeTrainRequest trainId ->
            ( { model | trains = AssocList.update trainId (Maybe.map (Train.cancelTeleportingHome currentTime)) model.trains }
            , Command.none
            )

        LeaveHomeTrainRequest trainId ->
            ( { model | trains = AssocList.update trainId (Maybe.map (Train.leaveHome currentTime)) model.trains }
            , Command.none
            )

        PingRequest ->
            ( model, PingResponse currentTime |> Effect.Lamdera.sendToFrontend clientId )

        SendLoginEmailRequest a ->
            case Untrusted.emailAddress a of
                Valid emailAddress ->
                    let
                        ( loginToken, model2 ) =
                            generateKey currentTime model

                        loginEmailUrl : String
                        loginEmailUrl =
                            Env.domain ++ UrlHelper.encodeUrl (InternalRoute { loginToken = Just loginToken, viewPoint = Coord.origin })
                    in
                    case IdDict.toList model.users |> List.find (\( _, user ) -> user.emailAddress == emailAddress) of
                        Just ( userId, _ ) ->
                            let
                                _ =
                                    Debug.log "loginUrl" loginEmailUrl
                            in
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
                                            [ Email.Html.text "If you did,"
                                            , Email.Html.a
                                                [ Email.Html.Attributes.href loginEmailUrl ]
                                                [ Email.Html.text " click here" ]
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


{-| Allow a client to say when something happened but restrict how far it can be away from the current time.
-}
adjustEventTime : Effect.Time.Posix -> Effect.Time.Posix -> Effect.Time.Posix
adjustEventTime currentTime eventTime =
    if Duration.from currentTime eventTime |> Quantity.abs |> Quantity.lessThan (Duration.seconds 1) then
        eventTime

    else
        currentTime


generateKey : Effect.Time.Posix -> { a | secretLinkCounter : Int } -> ( LoginToken, { a | secretLinkCounter : Int } )
generateKey currentTime model =
    ( Env.confirmationEmailKey
        ++ "_"
        ++ String.fromInt (Effect.Time.posixToMillis currentTime)
        ++ "_"
        ++ String.fromInt model.secretLinkCounter
        |> Crypto.Hash.sha256
        |> LoginToken
    , { model | secretLinkCounter = model.secretLinkCounter + 1 }
    )


updateLocalChange :
    Effect.Time.Posix
    -> ( Id UserId, BackendUserData )
    -> ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, ( Id EventId, Change.LocalChange ), Maybe ServerChange )
updateLocalChange time ( userId, _ ) (( eventId, change ) as originalChange) model =
    let
        invalidChange =
            ( eventId, Change.InvalidChange )
    in
    case change of
        Change.LocalUndo ->
            case IdDict.get userId model.users of
                Just user ->
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
                                    AssocList.toList model.trains
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

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalGridChange localChange ->
            case IdDict.get userId model.users of
                Just user ->
                    let
                        ( cellPosition, localPosition ) =
                            Grid.worldToCellAndLocalCoord localChange.position

                        maybeTrain : Maybe ( Id TrainId, Train )
                        maybeTrain =
                            if AssocList.size model.trains < 50 then
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
                                                    AssocList.insert trainId train model.trains

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

                Nothing ->
                    ( model, invalidChange, Nothing )

        Change.LocalRedo ->
            case IdDict.get userId model.users of
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

        Change.InvalidChange ->
            ( model, originalChange, Nothing )

        PickupCow cowId position time2 ->
            let
                isCowHeld =
                    IdDict.toList model.users
                        |> List.any
                            (\( _, user ) ->
                                case user.cursor of
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
                    (\user ->
                        { user
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


removeTrain : Id TrainId -> BackendModel -> BackendModel
removeTrain trainId model =
    { model
        | trains = AssocList.remove trainId model.trains
        , mail =
            AssocList.map
                (\_ mail ->
                    case mail.status of
                        MailInTransit trainId2 ->
                            if trainId == trainId2 then
                                { mail | status = MailWaitingPickup }

                            else
                                mail

                        MailWaitingPickup ->
                            mail

                        MailReceived ->
                            mail

                        MailReceivedAndViewed ->
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


requestDataUpdate : Effect.Time.Posix -> SessionId -> ClientId -> Bounds CellUnit -> Maybe LoginToken -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
requestDataUpdate currentTime sessionId clientId viewBounds maybeLoginToken model =
    let
        checkLogin () =
            ( case getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
                    LoggedIn
                        { userId = userId
                        , undoCurrent = user.undoCurrent
                        , undoHistory = user.undoHistory
                        , redoHistory = user.redoHistory
                        , mailEditor = user.mailEditor
                        }

                Nothing ->
                    NotLoggedIn
            , model
            )

        ( userStatus, model2 ) =
            case maybeLoginToken of
                Just loginToken ->
                    case AssocList.get loginToken model.pendingLoginTokens of
                        Just data ->
                            case IdDict.get data.userId model.users of
                                Just user ->
                                    ( LoggedIn
                                        { userId = data.userId
                                        , undoCurrent = user.undoCurrent
                                        , undoHistory = user.undoHistory
                                        , redoHistory = user.redoHistory
                                        , mailEditor = user.mailEditor
                                        }
                                    , { model | pendingLoginTokens = AssocList.remove loginToken model.pendingLoginTokens }
                                    )

                                Nothing ->
                                    ( NotLoggedIn, addError currentTime (UserNotFoundWhenLoggingIn data.userId) model )

                        Nothing ->
                            checkLogin ()

                Nothing ->
                    checkLogin ()

        model3 : BackendModel
        model3 =
            { model2
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
                        model2.userSessions
            }

        loadingData : LoadingData_
        loadingData =
            { grid = Grid.region viewBounds model3.grid
            , userStatus = userStatus
            , viewBounds = viewBounds
            , trains = model3.trains
            , mail = AssocList.map (\_ mail -> { status = mail.status, from = mail.from, to = mail.to }) model3.mail
            , cows = model3.cows
            , cursors = IdDict.filterMap (\_ a -> a.cursor) model3.users
            , handColors = IdDict.map (\_ a -> a.handColor) model3.users
            }
    in
    ( model3
    , Command.batch
        [ Effect.Lamdera.sendToFrontend clientId (LoadingData loadingData)
        , case userStatus of
            LoggedIn loggedIn ->
                broadcast
                    (\_ clientId2 ->
                        if clientId2 == clientId then
                            Nothing

                        else
                            ServerUserConnected loggedIn.userId Cursor.defaultColors
                                |> Change.ServerChange
                                |> Nonempty.singleton
                                |> ChangeBroadcast
                                |> Just
                    )
                    model3

            NotLoggedIn ->
                Command.none
        ]
    )


createUser : Id UserId -> EmailAddress -> BackendModel -> ( BackendModel, BackendUserData )
createUser userId emailAddress model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            , mailEditor = MailEditor.init
            , cursor = Nothing
            , handColor = Cursor.defaultColors
            , emailAddress = emailAddress
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
