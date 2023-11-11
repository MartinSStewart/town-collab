module Backend exposing
    ( BroadcastTo
    , LocalChangeStatus
    , app
    , app_
    , createBotUser
    , localAddUndo
    , localGridChange
    , localUndo
    )

import Angle
import Animal exposing (Animal)
import Array exposing (Array)
import AssocList
import Bounds exposing (Bounds)
import Bytes exposing (Endianness(..))
import Bytes.Decode
import Change exposing (AdminChange(..), AdminData, AreTrainsAndAnimalsDisabled(..), LocalChange(..), ServerChange(..), UserStatus(..), ViewBoundsChange2)
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Cursor
import Dict
import Direction2d
import DisplayName exposing (DisplayName)
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
import Grid exposing (Grid)
import GridCell exposing (BackendHistory(..))
import Id exposing (AnimalId, EventId, Id, MailId, OneTimePasswordId, SecretId, TrainId, UserId)
import IdDict exposing (IdDict)
import Lamdera
import LineSegmentExtra
import List.Extra as List
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LoadingPage
import LocalGrid
import MailEditor exposing (BackendMail, MailStatus(..))
import Maybe.Extra as Maybe
import Point2d exposing (Point2d)
import Postmark exposing (PostmarkSend, PostmarkSendResponse)
import Quantity
import Random
import Route exposing (LoginOrInviteToken(..), PageRoute(..), Route(..))
import SHA224
import Set
import String.Nonempty exposing (NonemptyString(..))
import Tile exposing (RailPathType(..))
import TileCountBot
import TimeOfDay exposing (TimeOfDay(..))
import Train exposing (Status(..), Train, TrainDiff)
import Types exposing (..)
import Undo
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Validation(..))
import User exposing (FrontendUser, InviteTree(..))
import Vector2d


app :
    { init : ( BackendModel, Cmd BackendMsg )
    , update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , updateFromFrontend : String -> String -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , subscriptions : BackendModel -> Sub BackendMsg
    }
app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        (app_ Env.isProduction)


app_ :
    Bool
    ->
        { init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        , update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        , updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        , subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
        }
app_ isProduction =
    { init = init
    , update = update isProduction
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Effect.Time.now |> Effect.Task.perform (UpdateFromFrontend sessionId clientId msg) )


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.batch
        [ Effect.Lamdera.onDisconnect UserDisconnected
        , Effect.Lamdera.onConnect (\_ clientId -> UserConnected clientId)
        , Effect.Time.every
            (if Dict.toList model.userSessions |> List.all (\( _, { clientIds } ) -> AssocList.isEmpty clientIds) then
                Duration.minute

             else
                Duration.second
            )
            WorldUpdateTimeElapsed
        , Effect.Time.every (Duration.seconds 10) (\_ -> CheckConnectionTimeElapsed)
        , Effect.Time.every (Duration.minutes 15) TileCountBotUpdate
        ]


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
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
            , animals = IdDict.empty
            , people = IdDict.empty
            , lastWorldUpdateTrains = IdDict.empty
            , lastWorldUpdate = Nothing
            , mail = IdDict.empty
            , pendingLoginTokens = AssocList.empty
            , pendingOneTimePasswords = AssocList.empty
            , invites = AssocList.empty
            , lastCacheRegeneration = Nothing
            , reported = IdDict.empty
            , isGridReadOnly = False
            , trainsAndAnimalsDisabled = TrainsAndAnimalsEnabled
            , lastReportEmailToAdmin = Nothing
            , worldUpdateDurations = Array.empty
            , tileCountBot = Nothing
            }
    in
    ( case Env.adminEmail of
        Just adminEmail ->
            createHumanUser adminId adminEmail model
                |> Tuple.first

        Nothing ->
            model
    , Command.none
    )


adminId : Id UserId
adminId =
    Id.fromInt 0


getAdminUser : BackendModel -> Maybe BackendUserData
getAdminUser model =
    IdDict.get adminId model.users


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


disconnectClient : SessionId -> ClientId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend backendMsg )
disconnectClient sessionId clientId model =
    let
        maybeUser : Maybe ( Id UserId, BackendUserData )
        maybeUser =
            getUserFromSessionId sessionId model
    in
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
        , users =
            case maybeUser of
                Just ( userId, user ) ->
                    IdDict.update userId (\_ -> Just { user | cursor = Nothing }) model.users

                Nothing ->
                    model.users
      }
    , case maybeUser of
        Just ( userId, _ ) ->
            Nonempty (ServerUserDisconnected userId |> Change.ServerChange) []
                |> ChangeBroadcast
                |> Effect.Lamdera.broadcast

        Nothing ->
            Command.none
    )


update : Bool -> BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update isProduction msg model =
    case msg of
        UserDisconnected sessionId clientId ->
            disconnectClient sessionId clientId model

        UserConnected clientId ->
            ( model, Effect.Lamdera.sendToFrontend clientId ClientConnected )

        UpdateFromFrontend sessionId clientId toBackendMsg time ->
            updateFromFrontendWithTime isProduction time sessionId clientId toBackendMsg model

        SentLoginEmail sendTime emailAddress result ->
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError sendTime (PostmarkError emailAddress error) model, Command.none )

        WorldUpdateTimeElapsed time ->
            case model.lastWorldUpdate of
                Just oldTime ->
                    handleWorldUpdate isProduction oldTime time model

                Nothing ->
                    ( { model | lastWorldUpdate = Just time }, Command.none )

        GotTimeAfterWorldUpdate updateStartTime updateEndTime ->
            let
                duration =
                    Duration.from updateStartTime updateEndTime
            in
            ( LocalGrid.updateWorldUpdateDurations duration model
            , broadcast
                (\sessionId_ _ ->
                    case getUserFromSessionId sessionId_ model of
                        Just ( userId2, _ ) ->
                            if userId2 == adminId then
                                Nonempty (Change.ServerChange (ServerWorldUpdateDuration duration)) []
                                    |> ChangeBroadcast
                                    |> Just

                            else
                                Nothing

                        Nothing ->
                            Nothing
                )
                model
            )

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
            ( model, broadcast (\_ _ -> Just CheckConnectionBroadcast) model )

        SentMailNotification sendTime emailAddress result ->
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError sendTime (PostmarkError emailAddress error) model, Command.none )

        SentReportVandalismAdminEmail sendTime emailAddress result ->
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError sendTime (PostmarkError emailAddress error) model, Command.none )

        TileCountBotUpdate time ->
            case model.tileCountBot of
                Just tileCountBot ->
                    let
                        tileCountBot2 : TileCountBot.Model
                        tileCountBot2 =
                            { tileCountBot
                                | tileUsage =
                                    Dict.foldl
                                        (\coord oldFlattenedCell tileUsage ->
                                            let
                                                newFlattenedCell : List GridCell.Value
                                                newFlattenedCell =
                                                    case Grid.getCell (Coord.tuple coord) model.grid of
                                                        Just cell ->
                                                            GridCell.flatten cell

                                                        Nothing ->
                                                            []
                                            in
                                            AssocList.merge
                                                (\tileGroup count tileUsage2 ->
                                                    AssocList.update
                                                        tileGroup
                                                        (\maybe ->
                                                            Maybe.withDefault 0 maybe |> (+) -count |> Just
                                                        )
                                                        tileUsage2
                                                )
                                                (\tileGroup oldCount newCount tileUsage2 ->
                                                    AssocList.update
                                                        tileGroup
                                                        (\maybe ->
                                                            Maybe.withDefault 0 maybe
                                                                |> (+) (newCount - oldCount)
                                                                |> Just
                                                        )
                                                        tileUsage2
                                                )
                                                (\tileGroup count tileUsage2 ->
                                                    AssocList.update
                                                        tileGroup
                                                        (\maybe ->
                                                            Maybe.withDefault 0 maybe |> (+) count |> Just
                                                        )
                                                        tileUsage2
                                                )
                                                (TileCountBot.countCellsHelper AssocList.empty oldFlattenedCell)
                                                (TileCountBot.countCellsHelper AssocList.empty newFlattenedCell)
                                                tileUsage
                                        )
                                        tileCountBot.tileUsage
                                        tileCountBot.changedCells
                                , changedCells = Dict.empty
                            }

                        model2 =
                            { model
                                | tileCountBot = Just tileCountBot2
                            }
                    in
                    if tileCountBot.tileUsage == tileCountBot2.tileUsage then
                        ( model, Command.none )

                    else
                        broadcastBotLocalChange
                            tileCountBot2.userId
                            time
                            (TileCountBot.drawHighscore False time tileCountBot2)
                            { model2 | tileCountBot = Just tileCountBot2 }

                Nothing ->
                    initTileCountBot time model


initTileCountBot : Effect.Time.Posix -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
initTileCountBot time model =
    let
        ( model2, botId ) =
            createBotUser TileCountBot.name model

        bot =
            TileCountBot.init botId model2.grid
    in
    broadcastBotLocalChange
        botId
        time
        (TileCountBot.drawHighscore True time bot)
        { model2 | tileCountBot = Just bot }


handleWorldUpdate : Bool -> Effect.Time.Posix -> Effect.Time.Posix -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleWorldUpdate isProduction oldTime time model =
    let
        newTrains : IdDict TrainId Train
        newTrains =
            case model.trainsAndAnimalsDisabled of
                TrainsAndAnimalsDisabled ->
                    model.trains

                TrainsAndAnimalsEnabled ->
                    Train.moveTrains
                        time
                        (Duration.from oldTime time |> Quantity.min Duration.minute |> Duration.subtractFrom time)
                        model.trains
                        model

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

        emailNotifications =
            List.foldl
                (\( _, mail ) state ->
                    case ( IdDict.get mail.to model.users, mail.status ) of
                        ( Just user, MailReceived _ ) ->
                            case user.cursor of
                                Just _ ->
                                    state

                                Nothing ->
                                    case user.userType of
                                        HumanUser humanUser ->
                                            if humanUser.allowEmailNotifications then
                                                let
                                                    ( loginToken, model2 ) =
                                                        generateSecretId time state.model

                                                    _ =
                                                        Debug.log "notification" loginEmailUrl

                                                    loginEmailUrl : String
                                                    loginEmailUrl =
                                                        Env.domain
                                                            ++ Route.encode
                                                                (InternalRoute
                                                                    { viewPoint =
                                                                        Grid.getPostOffice mail.to state.model.grid
                                                                            |> Maybe.withDefault Coord.origin
                                                                    , page = MailEditorRoute
                                                                    , loginOrInviteToken = LoginToken2 loginToken |> Just
                                                                    }
                                                                )
                                                in
                                                { model =
                                                    { model2
                                                        | pendingLoginTokens =
                                                            AssocList.insert
                                                                loginToken
                                                                { requestTime = time
                                                                , userId = mail.to
                                                                , requestedBy = LoginRequestedByBackend
                                                                }
                                                                model2.pendingLoginTokens
                                                    }
                                                , cmds =
                                                    sendEmail
                                                        isProduction
                                                        (SentMailNotification time humanUser.emailAddress)
                                                        (NonemptyString 'Y' "ou got a letter!")
                                                        ("You received a letter. You can view it directly by clicking on this link "
                                                            ++ loginEmailUrl
                                                        )
                                                        (Email.Html.div
                                                            []
                                                            [ Email.Html.text "You received a letter. You can view it directly by "
                                                            , Email.Html.a
                                                                [ Email.Html.Attributes.href loginEmailUrl ]
                                                                [ Email.Html.text "clicking here" ]
                                                            , Email.Html.text "."
                                                            ]
                                                        )
                                                        humanUser.emailAddress
                                                        :: state.cmds
                                                }

                                            else
                                                state

                                        BotUser ->
                                            state

                        _ ->
                            state
                )
                { model = model, cmds = [] }
                mergeTrains.mailChanges

        model3 =
            emailNotifications.model

        broadcastChanges : Command BackendOnly ToFrontend BackendMsg
        broadcastChanges =
            broadcast
                (\sessionId _ ->
                    let
                        maybeUserId =
                            getUserFromSessionId sessionId model3 |> Maybe.map Tuple.first
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
                model3

        ( newAnimals, animalDiff ) =
            case model.trainsAndAnimalsDisabled of
                TrainsAndAnimalsEnabled ->
                    let
                        newAnimals2 : IdDict AnimalId Animal
                        newAnimals2 =
                            IdDict.map
                                (\id animal ->
                                    if Duration.from (Animal.moveEndTime animal) time |> Quantity.lessThanZero then
                                        animal

                                    else
                                        let
                                            start =
                                                animal.endPosition

                                            maybeMove : Maybe { endPosition : Point2d WorldUnit WorldUnit, delay : Duration }
                                            maybeMove =
                                                Random.step
                                                    (randomMovement start)
                                                    (Random.initialSeed (Id.toInt id + Effect.Time.posixToMillis time))
                                                    |> Tuple.first
                                        in
                                        case maybeMove of
                                            Just { endPosition, delay } ->
                                                let
                                                    size =
                                                        (Animal.getData animal.animalType).size
                                                            |> Units.pixelToTileVector
                                                            |> Vector2d.scaleBy 0.5
                                                in
                                                { position = start
                                                , startTime = Duration.addTo time delay
                                                , endPosition =
                                                    case Grid.rayIntersection2 True size start endPosition model.grid of
                                                        Just { intersection } ->
                                                            LineSegmentExtra.extendLineEnd
                                                                start
                                                                intersection
                                                                (Quantity.negate Animal.moveCollisionThreshold)

                                                        Nothing ->
                                                            endPosition
                                                , animalType = animal.animalType
                                                }

                                            Nothing ->
                                                animal
                                )
                                model.animals
                    in
                    ( newAnimals2
                    , IdDict.merge
                        (\_ _ list -> list)
                        (\id old new list ->
                            if old.endPosition == new.endPosition then
                                list

                            else
                                ( id
                                , { position = new.position
                                  , endPosition = new.endPosition
                                  , startTime = new.startTime
                                  }
                                )
                                    :: list
                        )
                        (\_ _ list -> list)
                        model.animals
                        newAnimals2
                        []
                    )

                TrainsAndAnimalsDisabled ->
                    ( model.animals, [] )
    in
    ( { model3
        | lastWorldUpdate = Just time
        , trains = newTrains
        , lastWorldUpdateTrains = model3.trains
        , mail = mergeTrains.mail
        , animals = newAnimals
      }
    , Command.batch
        [ Command.batch emailNotifications.cmds
        , broadcastChanges
        , case Nonempty.fromList animalDiff of
            Just nonempty ->
                ServerAnimalMovement nonempty
                    |> Change.ServerChange
                    |> Nonempty.singleton
                    |> ChangeBroadcast
                    |> Effect.Lamdera.broadcast

            Nothing ->
                Command.none
        , Effect.Task.perform (GotTimeAfterWorldUpdate time) Effect.Time.now
        ]
    )


randomMovement :
    Point2d WorldUnit WorldUnit
    -> Random.Generator (Maybe { endPosition : Point2d WorldUnit WorldUnit, delay : Duration })
randomMovement position =
    Random.map4
        (\shouldMove direction distance delay ->
            if shouldMove == 0 then
                { endPosition = Point2d.translateIn (Direction2d.fromAngle (Angle.degrees direction)) (Units.tileUnit distance) position
                , delay = Duration.seconds delay
                }
                    |> Just

            else
                Nothing
        )
        (Random.int 0 2)
        (Random.float 0 360)
        (Random.float 2 10)
        (Random.float 1 1.5)


addError : Effect.Time.Posix -> BackendError -> BackendModel -> BackendModel
addError time error model =
    { model | errors = ( time, error ) :: model.errors }


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


localChangeStatusToLocalChange : Id EventId -> LocalChange -> LocalChangeStatus -> Change.Change
localChangeStatusToLocalChange eventId originalChange localChangeStatus =
    Change.LocalChange
        eventId
        (case localChangeStatus of
            OriginalChange ->
                originalChange

            InvalidChange ->
                Change.InvalidChange

            NewLocalChange localChange ->
                localChange
        )


broadcastBotLocalChange :
    Id UserId
    -> Effect.Time.Posix
    -> Nonempty Change.LocalChange
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
broadcastBotLocalChange userId time changes model =
    case IdDict.get userId model.users of
        Just user ->
            let
                ( model2, _, firstMsg ) =
                    updateLocalChangeBot userId user time (Nonempty.head changes) model

                ( model3, serverChanges ) =
                    Nonempty.tail changes
                        |> List.foldl
                            (\change ( model_, serverChanges_ ) ->
                                case IdDict.get userId model_.users of
                                    Just user2 ->
                                        let
                                            ( newModel, _, serverChange_ ) =
                                                updateLocalChangeBot userId user2 time change model_
                                        in
                                        ( newModel
                                        , Nonempty.cons serverChange_ serverChanges_
                                        )

                                    Nothing ->
                                        ( model_, serverChanges_ )
                            )
                            ( model2
                            , Nonempty.singleton firstMsg
                            )
                        |> (\( a, c ) -> ( a, Nonempty.reverse c ))
            in
            ( model3
            , broadcast
                (\sessionId_ _ ->
                    Nonempty.toList serverChanges
                        |> List.filterMap
                            (\broadcastTo ->
                                case broadcastTo of
                                    BroadcastToEveryoneElse serverChange ->
                                        Change.ServerChange serverChange |> Just

                                    BroadcastToAdmin serverChange ->
                                        case getUserFromSessionId sessionId_ model of
                                            Just ( userId2, _ ) ->
                                                if userId2 == adminId then
                                                    Change.ServerChange serverChange |> Just

                                                else
                                                    Nothing

                                            Nothing ->
                                                Nothing

                                    BroadcastToNoOne ->
                                        Nothing

                                    BroadcastToRestOfSessionAndEveryoneElse sessionId2 restOfSession everyoneElse ->
                                        (if sessionId_ == sessionId2 then
                                            restOfSession

                                         else
                                            everyoneElse
                                        )
                                            |> Change.ServerChange
                                            |> Just
                            )
                        |> Nonempty.fromList
                        |> Maybe.map ChangeBroadcast
                )
                model3
            )

        Nothing ->
            ( model, Command.none )


broadcastLocalChange :
    Bool
    -> Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> Nonempty ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
broadcastLocalChange isProduction time sessionId clientId changes model =
    let
        ( model2, localChange, firstMsg ) =
            updateLocalChange sessionId clientId time (Nonempty.head changes |> Tuple.second) model

        ( model3, allLocalChanges, serverChanges ) =
            Nonempty.tail changes
                |> List.foldl
                    (\( eventId2, change ) ( model_, originalChanges, serverChanges_ ) ->
                        let
                            ( newModel, localChange2, serverChange_ ) =
                                updateLocalChange sessionId clientId time change model_
                        in
                        ( newModel
                        , Nonempty.cons (localChangeStatusToLocalChange eventId2 change localChange2) originalChanges
                        , Nonempty.cons serverChange_ serverChanges_
                        )
                    )
                    ( model2
                    , Nonempty.singleton
                        (localChangeStatusToLocalChange
                            (Nonempty.head changes |> Tuple.first)
                            (Nonempty.head changes |> Tuple.second)
                            localChange
                        )
                    , Nonempty.singleton firstMsg
                    )
                |> (\( a, b, c ) -> ( a, Nonempty.reverse b, Nonempty.reverse c ))

        vandalismReported : Bool
        vandalismReported =
            Nonempty.any
                (\( _, change ) ->
                    case change of
                        ReportVandalism _ ->
                            True

                        _ ->
                            False
                )
                changes

        sendReportVandalismEmail : Bool
        sendReportVandalismEmail =
            case ( vandalismReported, model3.lastReportEmailToAdmin ) of
                ( True, Just lastReportEmailToAdmin ) ->
                    Duration.from lastReportEmailToAdmin time |> Quantity.greaterThan (Duration.minutes 5)

                ( True, Nothing ) ->
                    True

                ( False, _ ) ->
                    False
    in
    ( { model3
        | lastReportEmailToAdmin =
            if sendReportVandalismEmail then
                Just time

            else
                model3.lastReportEmailToAdmin
      }
    , Command.batch
        [ broadcast
            (\sessionId_ clientId_ ->
                if clientId == clientId_ then
                    ChangeBroadcast allLocalChanges |> Just

                else
                    Nonempty.toList serverChanges
                        |> List.filterMap
                            (\broadcastTo ->
                                case broadcastTo of
                                    BroadcastToEveryoneElse serverChange ->
                                        Change.ServerChange serverChange |> Just

                                    BroadcastToAdmin serverChange ->
                                        case getUserFromSessionId sessionId_ model of
                                            Just ( userId2, _ ) ->
                                                if userId2 == adminId then
                                                    Change.ServerChange serverChange |> Just

                                                else
                                                    Nothing

                                            Nothing ->
                                                Nothing

                                    BroadcastToNoOne ->
                                        Nothing

                                    BroadcastToRestOfSessionAndEveryoneElse sessionId2 restOfSession everyoneElse ->
                                        (if sessionId_ == sessionId2 then
                                            restOfSession

                                         else
                                            everyoneElse
                                        )
                                            |> Change.ServerChange
                                            |> Just
                            )
                        |> Nonempty.fromList
                        |> Maybe.map ChangeBroadcast
            )
            model3
        , case ( sendReportVandalismEmail, getAdminUser model3 ) of
            ( True, Just adminUser ) ->
                case adminUser.userType of
                    HumanUser { emailAddress } ->
                        sendEmail
                            isProduction
                            (SentReportVandalismAdminEmail time emailAddress)
                            (NonemptyString 'V' "andalism reported")
                            "Vandalism reported"
                            (Email.Html.text "Vandalism reported")
                            emailAddress

                    BotUser ->
                        Command.none

            _ ->
                Command.none
        ]
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


generateOneTimePassword :
    Effect.Time.Posix
    -> { a | secretLinkCounter : Int }
    -> ( SecretId OneTimePasswordId, { a | secretLinkCounter : Int } )
generateOneTimePassword currentTime model =
    ( Env.secretKey
        ++ "_"
        ++ String.fromInt (Effect.Time.posixToMillis currentTime)
        ++ "_"
        ++ String.fromInt model.secretLinkCounter
        |> SHA224.fromString
        |> SHA224.toBytes
        |> Bytes.Decode.decode oneTimePasswordDecoder
        |> Maybe.withDefault ""
        |> Id.secretFromString
    , { model | secretLinkCounter = model.secretLinkCounter + 1 }
    )


oneTimePasswordDecoder : Bytes.Decode.Decoder String
oneTimePasswordDecoder =
    Bytes.Decode.loop
        ( [], 0 )
        (\( list, count ) ->
            if count >= Id.oneTimePasswordLength then
                Bytes.Decode.succeed (Bytes.Decode.Done (String.fromList list))

            else
                Bytes.Decode.map
                    (\value ->
                        ( (Array.get
                            (modBy (Array.length oneTimePasswordChars - 1) value)
                            oneTimePasswordChars
                            |> Maybe.withDefault '?'
                          )
                            :: list
                        , count + 1
                        )
                            |> Bytes.Decode.Loop
                    )
                    (Bytes.Decode.unsignedInt16 BE)
        )


oneTimePasswordChars : Array Char
oneTimePasswordChars =
    List.range (Char.toCode 'a') (Char.toCode 'z')
        ++ List.range (Char.toCode 'A') (Char.toCode 'Z')
        ++ List.range (Char.toCode '0') (Char.toCode '9')
        |> List.map Char.fromCode
        -- Remove chars that are easily confused with eachother
        |> List.remove 'O'
        |> List.remove '0'
        |> List.remove 'l'
        |> List.remove '1'
        |> Array.fromList


updateFromFrontendWithTime :
    Bool
    -> Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendWithTime isProduction currentTime sessionId clientId msg model =
    case msg of
        ConnectToBackend requestData maybeToken ->
            connectToBackend currentTime sessionId clientId requestData maybeToken model

        GridChange changes ->
            broadcastLocalChange isProduction currentTime sessionId clientId changes model

        PingRequest ->
            ( model, PingResponse currentTime |> Effect.Lamdera.sendToFrontend clientId )

        SendLoginEmailRequest a ->
            case Untrusted.emailAddress a of
                Valid emailAddress ->
                    let
                        ( oneTimePassword, model2 ) =
                            generateOneTimePassword currentTime model

                        maybeUser =
                            IdDict.toList model.users
                                |> List.find
                                    (\( _, user ) ->
                                        case user.userType of
                                            HumanUser humanUser ->
                                                humanUser.emailAddress == emailAddress

                                            BotUser ->
                                                False
                                    )
                    in
                    case maybeUser of
                        Just ( userId, _ ) ->
                            let
                                _ =
                                    Debug.log "OTP" (Id.secretToString oneTimePassword)
                            in
                            ( { model2
                                | pendingOneTimePasswords =
                                    AssocList.insert
                                        sessionId
                                        { requestTime = currentTime
                                        , userId = userId
                                        , oneTimePassword = oneTimePassword
                                        , loginAttempts = 0
                                        }
                                        model2.pendingOneTimePasswords
                              }
                            , Command.batch
                                [ SendLoginEmailResponse emailAddress |> Effect.Lamdera.sendToFrontend clientId
                                , sendEmail
                                    isProduction
                                    (SentLoginEmail currentTime emailAddress)
                                    (NonemptyString 'L' "ogin Email")
                                    ("Here's your login code: "
                                        ++ Id.secretToString oneTimePassword
                                        ++ "\n\nIf you didn't request this email then it's safe to ignore."
                                    )
                                    (Email.Html.div
                                        []
                                        [ Email.Html.div
                                            []
                                            [ Email.Html.text "Here's your login code: "
                                            , Email.Html.span [ Email.Html.Attributes.fontFamily "courier" ] [ Email.Html.text (Id.secretToString oneTimePassword) ]
                                            ]
                                        , Email.Html.br [] []
                                        , Email.Html.div
                                            []
                                            [ Email.Html.text
                                                "If you didn't request this email then it's safe to ignore."
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
                            if
                                IdDict.toList model2.users
                                    |> List.any
                                        (\( _, user2 ) ->
                                            case user2.userType of
                                                HumanUser humanUser ->
                                                    humanUser.emailAddress == emailAddress

                                                BotUser ->
                                                    False
                                        )
                            then
                                ( model2, Effect.Lamdera.sendToFrontend clientId (SendInviteEmailResponse emailAddress) )

                            else
                                let
                                    _ =
                                        Debug.log "inviteUrl" inviteUrl

                                    ( inviteToken, model3 ) =
                                        generateSecretId currentTime model2

                                    inviteUrl : String
                                    inviteUrl =
                                        Env.domain
                                            ++ Route.encode
                                                (InternalRoute
                                                    { viewPoint = Route.startPointAt
                                                    , page = WorldRoute
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

        ResetTileBotRequest ->
            case model.tileCountBot of
                Just bot ->
                    let
                        newBot : TileCountBot.Model
                        newBot =
                            TileCountBot.init bot.userId model.grid
                    in
                    broadcastBotLocalChange
                        bot.userId
                        currentTime
                        (TileCountBot.drawHighscore False currentTime newBot)
                        { model | tileCountBot = Just newBot }

                Nothing ->
                    initTileCountBot currentTime model

        LoginAttemptRequest oneTimePassword ->
            case AssocList.get sessionId model.pendingOneTimePasswords of
                Just pending ->
                    if
                        (Duration.from pending.requestTime currentTime |> Quantity.lessThan (Duration.minutes 10))
                            && (pending.loginAttempts < 20)
                    then
                        if Id.secretIdEquals oneTimePassword pending.oneTimePassword then
                            case IdDict.get pending.userId model.users of
                                Just user ->
                                    case user.userType of
                                        HumanUser humanUser ->
                                            let
                                                loggedIn : Change.LoggedIn_
                                                loggedIn =
                                                    getLoggedInData pending.userId user humanUser model

                                                model2 =
                                                    { model
                                                        | userSessions =
                                                            Dict.update
                                                                (Effect.Lamdera.sessionIdToString sessionId)
                                                                (Maybe.map (\a -> { a | userId = Just pending.userId }))
                                                                model.userSessions
                                                        , pendingOneTimePasswords = AssocList.remove sessionId model.pendingOneTimePasswords
                                                    }

                                                frontendUser : FrontendUser
                                                frontendUser =
                                                    backendUserToFrontend user
                                            in
                                            ( model2
                                            , broadcast
                                                (\sessionId2 _ ->
                                                    if sessionId2 == sessionId then
                                                        ServerYouLoggedIn loggedIn frontendUser
                                                            |> Change.ServerChange
                                                            |> Nonempty.singleton
                                                            |> ChangeBroadcast
                                                            |> Just

                                                    else
                                                        ServerUserConnected
                                                            { maybeLoggedIn =
                                                                Just { userId = loggedIn.userId, user = frontendUser }
                                                            , cowsSpawnedFromVisibleRegion = []
                                                            }
                                                            |> Change.ServerChange
                                                            |> Nonempty.singleton
                                                            |> ChangeBroadcast
                                                            |> Just
                                                )
                                                model2
                                            )

                                        BotUser ->
                                            ( model, Command.none )

                                Nothing ->
                                    ( model, Command.none )

                        else
                            ( { model
                                | pendingOneTimePasswords =
                                    AssocList.update
                                        sessionId
                                        (Maybe.map (\a -> { a | loginAttempts = a.loginAttempts + 1 |> Debug.log "a" }))
                                        model.pendingOneTimePasswords
                              }
                            , Effect.Lamdera.sendToFrontend
                                clientId
                                (LoginAttemptResponse (WrongOneTimePassword oneTimePassword))
                            )

                    else
                        ( model
                        , Effect.Lamdera.sendToFrontend
                            clientId
                            (LoginAttemptResponse OneTimePasswordExpiredOrTooManyAttempts)
                        )

                Nothing ->
                    ( model
                    , Effect.Lamdera.sendToFrontend
                        clientId
                        (LoginAttemptResponse OneTimePasswordExpiredOrTooManyAttempts)
                    )


{-| Allow a client to say when something happened but restrict how far it can be away from the current time.
-}
adjustEventTime : Effect.Time.Posix -> Effect.Time.Posix -> Effect.Time.Posix
adjustEventTime currentTime eventTime =
    if Duration.from currentTime eventTime |> Quantity.abs |> Quantity.lessThan (Duration.seconds 1) then
        eventTime

    else
        currentTime


type BroadcastTo
    = BroadcastToEveryoneElse ServerChange
    | BroadcastToAdmin ServerChange
    | BroadcastToNoOne
    | BroadcastToRestOfSessionAndEveryoneElse SessionId ServerChange ServerChange


type LocalChangeStatus
    = OriginalChange
    | InvalidChange
    | NewLocalChange LocalChange


localGridChange :
    Effect.Time.Posix
    -> BackendModel
    -> Grid.LocalGridChange
    -> Id UserId
    -> BackendUserData
    -> ( BackendModel, LocalChangeStatus, BroadcastTo )
localGridChange time model localChange userId user =
    let
        localChange2 : Grid.LocalGridChange
        localChange2 =
            { position = localChange.position
            , change = localChange.change
            , colors = localChange.colors
            , time = time
            }

        change : Grid.GridChange
        change =
            Grid.localChangeToChange userId localChange2
    in
    if model.isGridReadOnly then
        ( model, InvalidChange, BroadcastToNoOne )

    else if LoadingPage.canPlaceTile time change model.trains model.grid then
        let
            ( cellPosition, localPosition ) =
                Grid.worldToCellAndLocalCoord change.position

            maybeTrain : Maybe ( Id TrainId, Train )
            maybeTrain =
                if IdDict.size model.trains < 50 then
                    Train.handleAddingTrain model.trains userId change.change change.position

                else
                    Nothing

            { removed, newCells } =
                Grid.addChangeBackend change model.grid

            nextCowId =
                IdDict.nextId model.animals |> Id.toInt

            newAnimals : List ( Id AnimalId, Animal )
            newAnimals =
                List.concatMap LocalGrid.getCowsForCell newCells
                    |> List.indexedMap (\index cow -> ( Id.fromInt (nextCowId + index), cow ))
        in
        case Train.canRemoveTiles time removed model.trains of
            Ok trainsToRemove ->
                ( List.map Tuple.first trainsToRemove
                    |> List.foldl
                        removeTrain
                        { model
                            | grid = Grid.addChangeBackend change model.grid |> .grid
                            , trains =
                                case maybeTrain of
                                    Just ( trainId, train ) ->
                                        IdDict.insert trainId train model.trains

                                    Nothing ->
                                        model.trains
                            , animals =
                                IdDict.union
                                    (LocalGrid.updateAnimalMovement localChange model.animals)
                                    (IdDict.fromList newAnimals)
                            , tileCountBot =
                                case model.tileCountBot of
                                    Just tileCountBot ->
                                        TileCountBot.onGridChanged
                                            (Grid.worldToCellAndLocalCoord localChange.position
                                                |> (\( a, b ) -> Grid.closeNeighborCells a b)
                                                |> List.map Tuple.first
                                            )
                                            model.grid
                                            tileCountBot
                                            |> Just

                                    Nothing ->
                                        Nothing
                        }
                    |> updateUser
                        userId
                        (always
                            { user
                                | undoCurrent =
                                    LocalGrid.incrementUndoCurrent cellPosition localPosition user.undoCurrent
                            }
                        )
                , Change.LocalGridChange localChange2 |> NewLocalChange
                , ServerGridChange
                    { gridChange = change
                    , newCells = newCells
                    , newAnimals = newAnimals
                    }
                    |> BroadcastToEveryoneElse
                )

            Err _ ->
                ( model, InvalidChange, BroadcastToNoOne )

    else
        ( model, InvalidChange, BroadcastToNoOne )


localUndo : BackendModel -> Id UserId -> BackendUserData -> ( BackendModel, LocalChangeStatus, BroadcastTo )
localUndo model userId user =
    case ( model.isGridReadOnly, Undo.undo user ) of
        ( False, Just newUser ) ->
            let
                undoMoveAmount : Dict.Dict RawCellCoord Int
                undoMoveAmount =
                    Dict.map (\_ a -> -a) user.undoCurrent

                newGrid : Grid BackendHistory
                newGrid =
                    Grid.moveUndoPointBackend userId undoMoveAmount model.grid

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
                { model
                    | grid = newGrid
                    , tileCountBot =
                        case model.tileCountBot of
                            Just tileCountBot ->
                                TileCountBot.onGridChanged
                                    (List.map Coord.tuple (Dict.keys undoMoveAmount))
                                    model.grid
                                    tileCountBot
                                    |> Just

                            Nothing ->
                                Nothing
                }
                trainsToRemove
                |> updateUser userId (always newUser)
            , OriginalChange
            , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> BroadcastToEveryoneElse
            )

        _ ->
            ( model, InvalidChange, BroadcastToNoOne )


localAddUndo : BackendModel -> Id UserId -> BackendUserData -> ( BackendModel, LocalChangeStatus, BroadcastTo )
localAddUndo model userId _ =
    if model.isGridReadOnly then
        ( model, InvalidChange, BroadcastToNoOne )

    else
        ( updateUser userId Undo.add model, OriginalChange, BroadcastToNoOne )


localRedo : BackendModel -> Id UserId -> BackendUserData -> ( BackendModel, LocalChangeStatus, BroadcastTo )
localRedo model userId user =
    case ( model.isGridReadOnly, Undo.redo user ) of
        ( False, Just newUser ) ->
            let
                undoMoveAmount =
                    newUser.undoCurrent
            in
            ( { model
                | grid = Grid.moveUndoPointBackend userId undoMoveAmount model.grid
                , tileCountBot =
                    case model.tileCountBot of
                        Just tileCountBot ->
                            TileCountBot.onGridChanged
                                (List.map Coord.tuple (Dict.keys undoMoveAmount))
                                model.grid
                                tileCountBot
                                |> Just

                        Nothing ->
                            Nothing
              }
                |> updateUser userId (always newUser)
            , OriginalChange
            , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> BroadcastToEveryoneElse
            )

        _ ->
            ( model, InvalidChange, BroadcastToNoOne )


updateLocalChangeBot :
    Id UserId
    -> BackendUserData
    -> Effect.Time.Posix
    -> LocalChange
    -> BackendModel
    -> ( BackendModel, LocalChangeStatus, BroadcastTo )
updateLocalChangeBot userId user time change model =
    case change of
        Change.LocalUndo ->
            localUndo model userId user

        Change.LocalGridChange localChange ->
            localGridChange time model localChange userId user

        Change.LocalRedo ->
            localRedo model userId user

        Change.LocalAddUndo ->
            localAddUndo model userId user

        _ ->
            ( model, InvalidChange, BroadcastToNoOne )


updateLocalChange :
    SessionId
    -> ClientId
    -> Effect.Time.Posix
    -> Change.LocalChange
    -> BackendModel
    -> ( BackendModel, LocalChangeStatus, BroadcastTo )
updateLocalChange sessionId clientId time change model =
    let
        asUser2 :
            (Id UserId -> BackendUserData -> ( BackendModel, LocalChangeStatus, BroadcastTo ))
            -> ( BackendModel, LocalChangeStatus, BroadcastTo )
        asUser2 func =
            case getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
                    func userId user

                Nothing ->
                    ( model, InvalidChange, BroadcastToNoOne )
    in
    case change of
        Change.LocalUndo ->
            asUser2 (localUndo model)

        Change.LocalGridChange localChange ->
            asUser2 (localGridChange time model localChange)

        Change.LocalRedo ->
            asUser2 (localRedo model)

        Change.LocalAddUndo ->
            asUser2 (localAddUndo model)

        Change.InvalidChange ->
            ( model, OriginalChange, BroadcastToNoOne )

        PickupAnimal cowId position time2 ->
            asUser2
                (\userId _ ->
                    if model.isGridReadOnly then
                        ( model, InvalidChange, BroadcastToNoOne )

                    else
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
                            ( model, InvalidChange, BroadcastToNoOne )

                        else
                            ( updateUser
                                userId
                                (\user2 ->
                                    { user2
                                        | cursor =
                                            case user2.cursor of
                                                Just cursor ->
                                                    { cursor
                                                        | position = position
                                                        , holdingCow = Just { cowId = cowId, pickupTime = time2 }
                                                    }
                                                        |> Just

                                                Nothing ->
                                                    Cursor.defaultCursor position (Just { cowId = cowId, pickupTime = time2 })
                                                        |> Just
                                    }
                                )
                                model
                            , PickupAnimal cowId position (adjustEventTime time time2) |> NewLocalChange
                            , ServerPickupAnimal userId cowId position time2 |> BroadcastToEveryoneElse
                            )
                )

        DropAnimal animalId position time2 ->
            asUser2
                (\userId _ ->
                    case IdDict.get userId model.users |> Maybe.andThen .cursor of
                        Just cursor ->
                            case cursor.holdingCow of
                                Just holdingCow ->
                                    if holdingCow.cowId == animalId then
                                        ( updateUser
                                            userId
                                            (\user2 ->
                                                { user2
                                                    | cursor =
                                                        case user2.cursor of
                                                            Just cursor2 ->
                                                                { cursor2 | position = position, holdingCow = Nothing }
                                                                    |> Just

                                                            Nothing ->
                                                                Cursor.defaultCursor position Nothing |> Just
                                                }
                                            )
                                            { model
                                                | animals =
                                                    IdDict.update2
                                                        animalId
                                                        (LocalGrid.placeAnimal position model.grid)
                                                        model.animals
                                            }
                                        , DropAnimal animalId position (adjustEventTime time time2) |> NewLocalChange
                                        , ServerDropAnimal userId animalId position |> BroadcastToEveryoneElse
                                        )

                                    else
                                        ( model, InvalidChange, BroadcastToNoOne )

                                Nothing ->
                                    ( model, InvalidChange, BroadcastToNoOne )

                        Nothing ->
                            ( model, InvalidChange, BroadcastToNoOne )
                )

        MoveCursor position ->
            asUser2
                (\userId _ ->
                    ( updateUser
                        userId
                        (\user2 ->
                            { user2
                                | cursor =
                                    case user2.cursor of
                                        Just cursor ->
                                            { cursor | position = position } |> Just

                                        Nothing ->
                                            Cursor.defaultCursor position Nothing |> Just
                            }
                        )
                        model
                    , OriginalChange
                    , ServerMoveCursor userId position |> BroadcastToEveryoneElse
                    )
                )

        ChangeHandColor colors ->
            asUser2
                (\userId _ ->
                    ( updateUser
                        userId
                        (\user2 -> { user2 | handColor = colors })
                        model
                    , OriginalChange
                    , ServerChangeHandColor userId colors |> BroadcastToEveryoneElse
                    )
                )

        ToggleRailSplit coord ->
            asUser2
                (\_ _ ->
                    ( { model | grid = Grid.toggleRailSplit coord model.grid }
                    , OriginalChange
                    , ServerToggleRailSplit coord |> BroadcastToEveryoneElse
                    )
                )

        ChangeDisplayName displayName ->
            asUser2
                (\userId user ->
                    ( { model | users = IdDict.insert userId { user | name = displayName } model.users }
                    , OriginalChange
                    , ServerChangeDisplayName userId displayName |> BroadcastToEveryoneElse
                    )
                )

        SubmitMail { to, content } ->
            asUser2
                (\userId user ->
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
                    , OriginalChange
                    , ServerSubmitMail { to = to, from = userId } |> BroadcastToEveryoneElse
                    )
                )

        UpdateDraft { to, content } ->
            asUser2
                (\userId user ->
                    ( { model
                        | users =
                            IdDict.insert
                                userId
                                { user | mailDrafts = IdDict.insert to content user.mailDrafts }
                                model.users
                      }
                    , OriginalChange
                    , BroadcastToNoOne
                    )
                )

        TeleportHomeTrainRequest trainId teleportTime ->
            asUser2
                (\_ _ ->
                    let
                        adjustedTime =
                            adjustEventTime time teleportTime
                    in
                    ( { model | trains = IdDict.update2 trainId (Train.startTeleportingHome adjustedTime) model.trains }
                    , TeleportHomeTrainRequest trainId adjustedTime |> NewLocalChange
                    , ServerTeleportHomeTrainRequest trainId adjustedTime |> BroadcastToEveryoneElse
                    )
                )

        LeaveHomeTrainRequest trainId leaveTime ->
            asUser2
                (\_ _ ->
                    let
                        adjustedTime =
                            adjustEventTime time leaveTime
                    in
                    ( { model | trains = IdDict.update2 trainId (Train.leaveHome adjustedTime) model.trains }
                    , LeaveHomeTrainRequest trainId adjustedTime |> NewLocalChange
                    , ServerLeaveHomeTrainRequest trainId adjustedTime |> BroadcastToEveryoneElse
                    )
                )

        ViewedMail mailId ->
            asUser2
                (\userId _ ->
                    case IdDict.get mailId model.mail of
                        Just mail ->
                            case ( mail.to == userId, mail.status ) of
                                ( True, MailReceived data ) ->
                                    ( { model
                                        | mail =
                                            IdDict.insert mailId { mail | status = MailReceivedAndViewed data } model.mail
                                      }
                                    , OriginalChange
                                    , ServerViewedMail mailId userId |> BroadcastToEveryoneElse
                                    )

                                _ ->
                                    ( model, InvalidChange, BroadcastToNoOne )

                        Nothing ->
                            ( model, InvalidChange, BroadcastToNoOne )
                )

        SetAllowEmailNotifications allow ->
            asUser2
                (\userId user ->
                    ( updateHumanUser (\a -> { a | allowEmailNotifications = allow }) userId user model
                    , OriginalChange
                    , BroadcastToNoOne
                    )
                )

        ChangeTool tool ->
            asUser2
                (\userId user ->
                    ( { model
                        | users =
                            IdDict.insert userId
                                { user
                                    | cursor =
                                        case user.cursor of
                                            Just cursor ->
                                                Just { cursor | currentTool = tool }

                                            Nothing ->
                                                Nothing
                                }
                                model.users
                      }
                    , OriginalChange
                    , ServerChangeTool userId tool |> BroadcastToEveryoneElse
                    )
                )

        ReportVandalism report ->
            asUser2
                (\userId _ ->
                    let
                        backendReport =
                            { reportedUser = report.reportedUser
                            , position = report.position
                            , reportedAt = time
                            }
                    in
                    ( { model | reported = LocalGrid.addReported userId backendReport model.reported }
                    , OriginalChange
                    , ServerVandalismReportedToAdmin userId backendReport |> BroadcastToAdmin
                    )
                )

        RemoveReport position ->
            asUser2
                (\userId _ ->
                    ( { model | reported = LocalGrid.removeReported userId position model.reported }
                    , OriginalChange
                    , ServerVandalismRemovedToAdmin userId position |> BroadcastToAdmin
                    )
                )

        AdminChange adminChange ->
            asUser2
                (\userId _ ->
                    if userId == adminId then
                        case adminChange of
                            AdminResetSessions ->
                                ( { model
                                    | userSessions = Dict.map (\_ data -> { data | clientIds = AssocList.empty }) model.userSessions
                                  }
                                , OriginalChange
                                , BroadcastToNoOne
                                )

                            AdminSetGridReadOnly isGridReadOnly ->
                                ( { model | isGridReadOnly = isGridReadOnly }
                                , OriginalChange
                                , ServerGridReadOnly isGridReadOnly |> BroadcastToEveryoneElse
                                )

                            AdminSetTrainsDisabled areTrainsDisabled ->
                                ( { model | trainsAndAnimalsDisabled = areTrainsDisabled }
                                , OriginalChange
                                , ServerSetTrainsDisabled areTrainsDisabled |> BroadcastToEveryoneElse
                                )

                            AdminDeleteMail mailId deleteTime ->
                                let
                                    adjustedTime =
                                        adjustEventTime time deleteTime
                                in
                                ( LocalGrid.deleteMail mailId adjustedTime model
                                , AdminDeleteMail mailId adjustedTime |> AdminChange |> NewLocalChange
                                , BroadcastToNoOne
                                )

                            AdminRestoreMail mailId ->
                                ( LocalGrid.restoreMail mailId model
                                , OriginalChange
                                , BroadcastToNoOne
                                )

                            AdminResetUpdateDuration ->
                                ( model, OriginalChange, BroadcastToNoOne )

                            AdminRegenerateGridCellCache _ ->
                                ( { model
                                    | grid = Grid.regenerateGridCellCacheBackend model.grid
                                    , lastCacheRegeneration = Just time
                                  }
                                , OriginalChange
                                , BroadcastToEveryoneElse (ServerRegenerateCache time)
                                )

                    else
                        ( model, InvalidChange, BroadcastToNoOne )
                )

        SetTimeOfDay timeOfDay ->
            case getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
                    ( updateHumanUser (\a -> { a | timeOfDay = timeOfDay }) userId user model
                    , OriginalChange
                    , BroadcastToNoOne
                    )

                Nothing ->
                    ( model, OriginalChange, BroadcastToNoOne )

        SetTileHotkey tileHotkey tileGroup ->
            asUser2
                (\userId user ->
                    ( updateHumanUser (LocalGrid.setTileHotkey tileHotkey tileGroup) userId user model
                    , OriginalChange
                    , BroadcastToNoOne
                    )
                )

        ShowNotifications showNotifications ->
            asUser2
                (\userId user ->
                    ( updateHumanUser (\a -> { a | showNotifications = showNotifications }) userId user model
                    , OriginalChange
                    , BroadcastToNoOne
                    )
                )

        Logout ->
            asUser2
                (\userId user ->
                    ( { model
                        | userSessions =
                            Dict.update
                                (Effect.Lamdera.sessionIdToString sessionId)
                                (Maybe.map (\session -> { session | userId = Nothing }))
                                model.userSessions
                        , users = IdDict.update userId (\_ -> Just { user | cursor = Nothing }) model.users
                      }
                    , OriginalChange
                    , BroadcastToRestOfSessionAndEveryoneElse sessionId ServerLogout (ServerUserDisconnected userId)
                    )
                )

        ViewBoundsChange data ->
            viewBoundsChange data sessionId clientId model

        ClearNotifications clearedAt ->
            asUser2
                (\userId user ->
                    ( updateHumanUser (\a -> { a | notificationsClearedAt = clearedAt }) userId user model
                    , OriginalChange
                    , BroadcastToNoOne
                    )
                )


updateHumanUser : (HumanUserData -> HumanUserData) -> Id UserId -> BackendUserData -> BackendModel -> BackendModel
updateHumanUser updateFunc userId user model =
    { model
        | users =
            IdDict.insert
                userId
                (case user.userType of
                    HumanUser humanUser ->
                        { user | userType = HumanUser (updateFunc humanUser) }

                    BotUser ->
                        user
                )
                model.users
    }


viewBoundsChange :
    ViewBoundsChange2
    -> SessionId
    -> ClientId
    -> BackendModel
    -> ( BackendModel, LocalChangeStatus, BroadcastTo )
viewBoundsChange { viewBounds, previewBounds } sessionId clientId model =
    case
        Dict.get (Effect.Lamdera.sessionIdToString sessionId) model.userSessions
            |> Maybe.andThen (\{ clientIds } -> AssocList.get clientId clientIds)
    of
        Just oldBounds ->
            let
                ( newGrid, cells, newCows ) =
                    generateVisibleRegion oldBounds (viewBounds :: Maybe.toList previewBounds) model

                model2 =
                    { model
                        | userSessions =
                            Dict.update
                                (Effect.Lamdera.sessionIdToString sessionId)
                                (Maybe.map
                                    (\session ->
                                        { session
                                            | clientIds =
                                                AssocList.update
                                                    clientId
                                                    (\_ -> Just (viewBounds :: Maybe.toList previewBounds))
                                                    session.clientIds
                                        }
                                    )
                                )
                                model.userSessions
                        , animals = IdDict.fromList newCows |> IdDict.union model.animals
                        , grid = newGrid
                    }
            in
            ( model2
            , ViewBoundsChange
                { viewBounds = viewBounds
                , previewBounds = previewBounds
                , newCells = cells
                , newCows = newCows
                }
                |> NewLocalChange
            , case Nonempty.fromList newCows of
                Just nonempty ->
                    ServerNewCows nonempty |> BroadcastToEveryoneElse

                Nothing ->
                    BroadcastToNoOne
            )

        Nothing ->
            ( model, InvalidChange, BroadcastToNoOne )


generateVisibleRegion :
    List (Bounds CellUnit)
    -> List (Bounds CellUnit)
    -> BackendModel
    -> ( Grid BackendHistory, List ( Coord CellUnit, GridCell.CellData ), List ( Id d, Animal ) )
generateVisibleRegion oldBounds bounds model =
    let
        nextCowId =
            IdDict.nextId model.animals |> Id.toInt

        coords : List (Coord CellUnit)
        coords =
            List.foldl
                (\bound set ->
                    Bounds.coordRangeFold
                        (\coord set2 ->
                            if List.any (Bounds.contains coord) oldBounds then
                                set2

                            else
                                Set.insert (Coord.toTuple coord) set2
                        )
                        identity
                        bound
                        set
                )
                Set.empty
                bounds
                |> Set.toList
                |> List.map Coord.tuple

        newCells : { grid : Grid BackendHistory, cows : List Animal, cells : List ( Coord CellUnit, GridCell.CellData ) }
        newCells =
            List.foldl
                (\coord state ->
                    let
                        data =
                            Grid.getCell2 coord state.grid

                        newCows : List Animal
                        newCows =
                            if data.isNew then
                                LocalGrid.getCowsForCell coord

                            else
                                []

                        ( newCell, cellData ) =
                            GridCell.cellToData data.cell
                    in
                    { grid = Grid.setCell coord newCell data.grid
                    , cows = newCows ++ state.cows
                    , cells = ( coord, cellData ) :: state.cells
                    }
                )
                { grid = model.grid, cows = [], cells = [] }
                coords
    in
    ( newCells.grid
    , newCells.cells
    , List.indexedMap (\index cow -> ( Id.fromInt (nextCowId + index), cow )) newCells.cows
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

                        MailDeletedByAdmin _ ->
                            mail
                )
                model.mail
    }


updateUser : Id UserId -> (BackendUserData -> BackendUserData) -> BackendModel -> BackendModel
updateUser userId updateUserFunc model =
    { model | users = IdDict.update2 userId updateUserFunc model.users }


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

                    MailDeletedByAdmin _ ->
                        Nothing

            else
                Nothing
        )
        model.mail


getAdminData : Id UserId -> BackendModel -> Maybe AdminData
getAdminData userId model =
    if userId == adminId then
        { lastCacheRegeneration = model.lastCacheRegeneration
        , userSessions =
            Dict.toList model.userSessions
                |> List.map
                    (\( _, data ) ->
                        { userId = data.userId
                        , connectionCount = AssocList.size data.clientIds
                        }
                    )
        , reported = model.reported
        , mail = model.mail
        , worldUpdateDurations = model.worldUpdateDurations
        , totalGridCells = Grid.allCellsDict model.grid |> Dict.size
        }
            |> Just

    else
        Nothing


getUserReports : Id UserId -> BackendModel -> List Change.Report
getUserReports userId model =
    case IdDict.get userId model.reported of
        Just nonempty ->
            Nonempty.toList nonempty
                |> List.map
                    (\a ->
                        { reportedUser = a.reportedUser
                        , position = a.position
                        }
                    )

        Nothing ->
            []


getLoggedInData : Id UserId -> BackendUserData -> HumanUserData -> BackendModel -> Change.LoggedIn_
getLoggedInData userId user humanUser model =
    { userId = userId
    , undoCurrent = user.undoCurrent
    , undoHistory = user.undoHistory
    , redoHistory = user.redoHistory
    , mailDrafts = user.mailDrafts
    , emailAddress = humanUser.emailAddress
    , inbox = getUserInbox userId model
    , allowEmailNotifications = humanUser.allowEmailNotifications
    , adminData = getAdminData userId model
    , reports = getUserReports userId model
    , isGridReadOnly = model.isGridReadOnly
    , timeOfDay = humanUser.timeOfDay
    , tileHotkeys = humanUser.tileHotkeys
    , showNotifications = humanUser.showNotifications
    , notifications =
        Grid.latestChanges humanUser.notificationsClearedAt userId model.grid
            |> List.foldl LocalGrid.addNotification []
    , notificationsClearedAt = humanUser.notificationsClearedAt
    }


connectToBackend :
    Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> Bounds CellUnit
    -> Maybe LoginOrInviteToken
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
connectToBackend currentTime sessionId clientId viewBounds maybeToken model =
    let
        checkLogin () =
            ( case getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
                    case user.userType of
                        HumanUser humanUser ->
                            LoggedIn
                                { userId = userId
                                , undoCurrent = user.undoCurrent
                                , undoHistory = user.undoHistory
                                , redoHistory = user.redoHistory
                                , mailDrafts = user.mailDrafts
                                , emailAddress = humanUser.emailAddress
                                , inbox = getUserInbox userId model
                                , allowEmailNotifications = humanUser.allowEmailNotifications
                                , adminData = getAdminData userId model
                                , reports = getUserReports userId model
                                , isGridReadOnly = model.isGridReadOnly
                                , timeOfDay = humanUser.timeOfDay
                                , tileHotkeys = humanUser.tileHotkeys
                                , showNotifications = humanUser.showNotifications
                                , notifications =
                                    Grid.latestChanges humanUser.notificationsClearedAt userId model.grid
                                        |> List.foldl LocalGrid.addNotification []
                                , notificationsClearedAt = humanUser.notificationsClearedAt
                                }

                        BotUser ->
                            NotLoggedIn { timeOfDay = Automatic }

                Nothing ->
                    NotLoggedIn { timeOfDay = Automatic }
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
                                        case user.userType of
                                            HumanUser humanUser ->
                                                ( LoggedIn
                                                    { userId = data.userId
                                                    , undoCurrent = user.undoCurrent
                                                    , undoHistory = user.undoHistory
                                                    , redoHistory = user.redoHistory
                                                    , mailDrafts = user.mailDrafts
                                                    , emailAddress = humanUser.emailAddress
                                                    , inbox = getUserInbox data.userId model
                                                    , allowEmailNotifications = humanUser.allowEmailNotifications
                                                    , adminData = getAdminData data.userId model
                                                    , reports = getUserReports data.userId model
                                                    , isGridReadOnly = model.isGridReadOnly
                                                    , timeOfDay = humanUser.timeOfDay
                                                    , tileHotkeys = humanUser.tileHotkeys
                                                    , showNotifications = humanUser.showNotifications
                                                    , notifications =
                                                        Grid.latestChanges humanUser.notificationsClearedAt data.userId model.grid
                                                            |> List.foldl LocalGrid.addNotification []
                                                    , notificationsClearedAt = humanUser.notificationsClearedAt
                                                    }
                                                , { model | pendingLoginTokens = AssocList.remove loginToken model.pendingLoginTokens }
                                                , case data.requestedBy of
                                                    LoginRequestedByBackend ->
                                                        Nothing

                                                    LoginRequestedByFrontend requestedBy ->
                                                        Just requestedBy
                                                )

                                            BotUser ->
                                                ( NotLoggedIn { timeOfDay = Automatic }
                                                , addError currentTime (UserNotFoundWhenLoggingIn data.userId) model
                                                , Nothing
                                                )

                                    Nothing ->
                                        ( NotLoggedIn { timeOfDay = Automatic }
                                        , addError currentTime (UserNotFoundWhenLoggingIn data.userId) model
                                        , Nothing
                                        )

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
                                    createHumanUser userId invite.invitedEmailAddress model
                            in
                            case newUser.userType of
                                HumanUser humanUser ->
                                    ( LoggedIn
                                        { userId = userId
                                        , undoCurrent = newUser.undoCurrent
                                        , undoHistory = newUser.undoHistory
                                        , redoHistory = newUser.redoHistory
                                        , mailDrafts = newUser.mailDrafts
                                        , emailAddress = humanUser.emailAddress
                                        , inbox = getUserInbox userId model
                                        , allowEmailNotifications = humanUser.allowEmailNotifications
                                        , adminData = getAdminData userId model
                                        , reports = getUserReports userId model
                                        , isGridReadOnly = model.isGridReadOnly
                                        , timeOfDay = Automatic
                                        , tileHotkeys = humanUser.tileHotkeys
                                        , showNotifications = humanUser.showNotifications
                                        , notifications = []
                                        , notificationsClearedAt = humanUser.notificationsClearedAt
                                        }
                                    , { model4
                                        | invites = AssocList.remove inviteToken model.invites
                                        , users =
                                            IdDict.update2
                                                invite.invitedBy
                                                (\user ->
                                                    case user.userType of
                                                        HumanUser humanUser2 ->
                                                            { user
                                                                | userType =
                                                                    { humanUser2
                                                                        | acceptedInvites =
                                                                            IdDict.insert userId () humanUser2.acceptedInvites
                                                                    }
                                                                        |> HumanUser
                                                            }

                                                        BotUser ->
                                                            user
                                                )
                                                model4.users
                                      }
                                    , Nothing
                                    )

                                BotUser ->
                                    ( NotLoggedIn { timeOfDay = Automatic }, model4, Nothing )

                        Nothing ->
                            checkLogin ()

                Nothing ->
                    checkLogin ()

        ( newGrid, cells, newCows ) =
            generateVisibleRegion [] [ viewBounds ] model2

        model3 : BackendModel
        model3 =
            addSession
                sessionId
                clientId
                viewBounds
                userStatus
                { model2 | grid = newGrid, animals = IdDict.fromList newCows |> IdDict.union model.animals }
                |> (case maybeRequestedBy of
                        Just requestedBy ->
                            addSession requestedBy clientId viewBounds userStatus

                        Nothing ->
                            identity
                   )

        loadingData : LoadingData_
        loadingData =
            { grid =
                List.map (\( coord, cell ) -> ( Coord.toTuple coord, cell )) cells
                    |> Dict.fromList
                    |> Grid.fromData
            , userStatus = userStatus
            , viewBounds = viewBounds
            , trains = model3.trains
            , mail = IdDict.map (\_ mail -> { status = mail.status, from = mail.from, to = mail.to }) model3.mail
            , cows = model3.animals
            , cursors = IdDict.filterMap (\_ a -> a.cursor) model3.users
            , users = IdDict.map (\_ a -> backendUserToFrontend a) model3.users
            , inviteTree =
                invitesToInviteTree adminId model3.users
                    |> Maybe.withDefault (InviteTree { userId = adminId, invited = [] })
            , isGridReadOnly = model.isGridReadOnly
            , trainsDisabled = model.trainsAndAnimalsDisabled
            }

        frontendUser : FrontendUser
        frontendUser =
            case userStatus of
                LoggedIn loggedIn ->
                    case IdDict.get loggedIn.userId model3.users of
                        Just user ->
                            backendUserToFrontend user

                        Nothing ->
                            { handColor = Cursor.defaultColors
                            , name = DisplayName.default
                            , isBot = False
                            }

                NotLoggedIn _ ->
                    { handColor = Cursor.defaultColors
                    , name = DisplayName.default
                    , isBot = False
                    }
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
                            ServerUserConnected
                                { maybeLoggedIn = Just { userId = loggedIn.userId, user = frontendUser }
                                , cowsSpawnedFromVisibleRegion = newCows
                                }
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


invitesToInviteTree : Id UserId -> IdDict UserId BackendUserData -> Maybe InviteTree
invitesToInviteTree rootUserId users =
    case IdDict.get rootUserId users of
        Just user ->
            case user.userType of
                HumanUser humanUser ->
                    { userId = rootUserId
                    , invited =
                        List.filterMap
                            (\( userId, () ) -> invitesToInviteTree userId users)
                            (IdDict.toList humanUser.acceptedInvites)
                    }
                        |> InviteTree
                        |> Just

                BotUser ->
                    { userId = rootUserId
                    , invited = []
                    }
                        |> InviteTree
                        |> Just

        Nothing ->
            Nothing


backendUserToFrontend : BackendUserData -> FrontendUser
backendUserToFrontend user =
    { name = user.name
    , handColor = user.handColor
    , isBot = user.userType == BotUser
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
                            { clientIds = AssocList.insert clientId [ viewBounds ] session.clientIds
                            , userId =
                                case userStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.userId

                                    NotLoggedIn _ ->
                                        Nothing
                            }

                        Nothing ->
                            { clientIds = AssocList.singleton clientId [ viewBounds ]
                            , userId =
                                case userStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.userId

                                    NotLoggedIn _ ->
                                        Nothing
                            }
                    )
                        |> Just
                )
                model.userSessions
    }


createHumanUser : Id UserId -> EmailAddress -> BackendModel -> ( BackendModel, BackendUserData )
createHumanUser userId emailAddress model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            , mailDrafts = IdDict.empty
            , cursor = Nothing
            , handColor = Cursor.defaultColors
            , name = DisplayName.default
            , userType =
                HumanUser
                    { emailAddress = emailAddress
                    , acceptedInvites = IdDict.empty
                    , allowEmailNotifications = True
                    , timeOfDay = Automatic
                    , tileHotkeys = AssocList.empty
                    , showNotifications = False
                    , notificationsClearedAt = Effect.Time.millisToPosix 0
                    }
            }
    in
    ( { model | users = IdDict.insert userId userBackendData model.users }, userBackendData )


createBotUser : DisplayName -> BackendModel -> ( BackendModel, Id UserId )
createBotUser name model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            , mailDrafts = IdDict.empty
            , cursor = Nothing
            , handColor = Cursor.defaultColors
            , name = name
            , userType = BotUser
            }

        id =
            Train.nextId model.users
    in
    ( { model
        | users =
            IdDict.insert id userBackendData model.users
                |> IdDict.update2
                    adminId
                    (\user ->
                        case user.userType of
                            HumanUser humanUser ->
                                { user
                                    | userType =
                                        { humanUser | acceptedInvites = IdDict.insert id () humanUser.acceptedInvites } |> HumanUser
                                }

                            BotUser ->
                                user
                    )
      }
    , id
    )


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
