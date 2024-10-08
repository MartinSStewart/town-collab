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

import Animal exposing (Animal)
import Array exposing (Array)
import AssocList
import Bounds exposing (Bounds)
import Bytes exposing (Endianness(..))
import Bytes.Decode
import Change exposing (AdminChange(..), AdminData, AreTrainsAndAnimalsDisabled(..), LocalChange(..), MovementChange, NpcMovementChange, ServerChange(..), UserStatus(..), ViewBoundsChange2)
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Cursor exposing (AnimalOrNpcId(..), Holding(..))
import Dict
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
import GridCell exposing (BackendHistory)
import Hyperlink
import Id exposing (AnimalId, EventId, Id, MailId, NpcId, OneTimePasswordId, SecretId, TrainId, UserId)
import Lamdera
import LineSegmentExtra
import List.Extra as List
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LoadingPage
import LocalGrid
import MailEditor exposing (BackendMail, MailStatus(..))
import Maybe.Extra as Maybe
import Npc exposing (Npc)
import Point2d exposing (Point2d)
import Postmark exposing (PostmarkSend, PostmarkSendResponse)
import Quantity
import Random
import Route exposing (LoginOrInviteToken(..), PageRoute(..), Route(..))
import SHA224
import SeqDict exposing (SeqDict)
import Set exposing (Set)
import String.Nonempty exposing (NonemptyString(..))
import Tile exposing (BuildingData, RailPathType(..))
import TileCountBot
import TimeOfDay exposing (TimeOfDay(..))
import Train exposing (Status(..), Train, TrainDiff)
import Types exposing (BackendError(..), BackendModel, BackendMsg(..), BackendUserData, BackendUserType(..), EmailResult(..), HumanUserData, LoadingData_, LoginError(..), ToBackend(..), ToFrontend(..), UserSession)
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


dummyChange =
    0


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
                Duration.seconds 1
            )
            WorldUpdateTimeElapsed
        , if Dict.isEmpty model.userSessions then
            Subscription.none

          else
            Effect.Time.every (Duration.seconds 10) (\_ -> CheckConnectionTimeElapsed)
        , Effect.Time.every (Duration.minutes 15) TileCountBotUpdate
        ]


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    let
        model : BackendModel
        model =
            { grid = Grid.empty
            , userSessions = Dict.empty
            , users = SeqDict.empty
            , secretLinkCounter = 0
            , errors = []
            , trains = SeqDict.empty
            , animals = SeqDict.empty
            , npcs = SeqDict.empty
            , lastWorldUpdateTrains = SeqDict.empty
            , lastWorldUpdate = Nothing
            , mail = SeqDict.empty
            , pendingLoginTokens = AssocList.empty
            , pendingOneTimePasswords = AssocList.empty
            , invites = AssocList.empty
            , lastCacheRegeneration = Nothing
            , reported = SeqDict.empty
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
    SeqDict.get adminId model.users


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
                    SeqDict.update userId (\_ -> Just { user | cursor = Nothing }) model.users

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
                (\_ _ sessionUserId _ ->
                    case sessionUserId of
                        Just userId2 ->
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
            ( model, broadcast (\_ _ _ _ -> Just CheckConnectionBroadcast) model )

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


updateTrains :
    Effect.Time.Posix
    -> Effect.Time.Posix
    -> SeqDict (Id TrainId) Train
    -> BackendModel
    ->
        { mail : SeqDict (Id MailId) BackendMail
        , mailChanges : List ( Id MailId, BackendMail )
        , diff : SeqDict (Id TrainId) TrainDiff
        }
updateTrains oldTime time newTrains model =
    SeqDict.merge
        (\_ _ a -> a)
        (\trainId oldTrain newTrain state ->
            let
                diff : SeqDict (Id TrainId) TrainDiff
                diff =
                    SeqDict.insert trainId (Train.diff newTrain) state.diff
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
                                        { mail = SeqDict.insert mailId mail2 state2.mail
                                        , mailChanges = ( mailId, mail2 ) :: state2.mailChanges
                                        , diff = state2.diff
                                        }

                                    else
                                        state2

                                _ ->
                                    state2
                        )
                        { state | diff = diff }
                        (SeqDict.toList state.mail)

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
                                { mail = SeqDict.update mailId (\_ -> Just mail2) state.mail
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
                                    { mail = SeqDict.update mailId (\_ -> Just mail2) state.mail
                                    , mailChanges = ( mailId, mail2 ) :: state.mailChanges
                                    , diff = diff
                                    }

                                [] ->
                                    { state | diff = diff }

                _ ->
                    { state | diff = diff }
        )
        (\trainId train state ->
            { state | diff = SeqDict.insert trainId (Train.NewTrain train) state.diff }
        )
        model.lastWorldUpdateTrains
        newTrains
        { mailChanges = [], mail = model.mail, diff = SeqDict.empty }


handleEmailNotifications isProduction time model mergeTrains =
    List.foldl
        (\( _, mail ) state ->
            case ( SeqDict.get mail.to model.users, mail.status ) of
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


handleWorldUpdate : Bool -> Effect.Time.Posix -> Effect.Time.Posix -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleWorldUpdate isProduction oldTime time model =
    let
        newTrains : SeqDict (Id TrainId) Train
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
            { mail : SeqDict (Id MailId) BackendMail
            , mailChanges : List ( Id MailId, BackendMail )
            , diff : SeqDict (Id TrainId) TrainDiff
            }
        mergeTrains =
            updateTrains oldTime time newTrains model

        emailNotifications : { model : BackendModel, cmds : List (Command BackendOnly ToFrontend BackendMsg) }
        emailNotifications =
            handleEmailNotifications isProduction time model mergeTrains

        model3 : BackendModel
        model3 =
            emailNotifications.model

        ( newNpcs, npcChanges ) =
            updateNpc time model

        ( newAnimals, animalDiff ) =
            updateAnimals model time

        broadcastChanges : Command BackendOnly ToFrontend BackendMsg
        broadcastChanges =
            broadcast
                (\_ _ sessionUserId viewBounds ->
                    Nonempty
                        (Change.ServerChange
                            (ServerWorldUpdateBroadcast
                                { trainDiff = mergeTrains.diff
                                , maybeNewNpc = npcChanges.maybeNewNpc
                                , relocatedNpcs = npcChanges.relocatedNpcs
                                , movementChanges =
                                    List.filter
                                        (\( _, movementChange ) ->
                                            let
                                                ( cellPoint, _ ) =
                                                    Grid.worldToCellAndLocalCoord
                                                        (Coord.roundPoint movementChange.position)
                                            in
                                            List.any (Bounds.contains cellPoint) viewBounds
                                        )
                                        npcChanges.movementChanges
                                }
                            )
                        )
                        (List.map
                            (\( mailId, mail ) ->
                                (case ( Just mail.to == sessionUserId, mail.status ) of
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
    in
    ( { model3
        | lastWorldUpdate = Just time
        , trains = newTrains
        , lastWorldUpdateTrains = model3.trains
        , mail = mergeTrains.mail
        , animals = newAnimals
        , npcs = newNpcs
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


updateNpc :
    Effect.Time.Posix
    -> BackendModel
    ->
        ( SeqDict (Id NpcId) Npc
        , { maybeNewNpc : Maybe ( Id NpcId, Npc )
          , relocatedNpcs : List ( Id NpcId, Coord WorldUnit )
          , movementChanges : List ( Id NpcId, NpcMovementChange )
          }
        )
updateNpc newTime model =
    case model.trainsAndAnimalsDisabled of
        TrainsAndAnimalsEnabled ->
            let
                occupied : Set ( Int, Int )
                occupied =
                    SeqDict.values model.npcs
                        |> List.map (\person -> Coord.toTuple person.home)
                        |> Set.fromList

                homelessNpcs : List ( Id NpcId, Npc )
                homelessNpcs =
                    SeqDict.toList model.npcs
                        |> List.filter (\( _, npc ) -> Npc.isHomeless model.grid npc)

                validHouses : List { position : Coord WorldUnit, userId : Id UserId, buildingData : BuildingData }
                validHouses =
                    Grid.getBuildings model.grid
                        |> List.filter
                            (\a ->
                                not (Set.member (Coord.toTuple a.position) occupied)
                                    && a.buildingData.isHome
                                    && (Maybe.map .userId model.tileCountBot /= Just a.userId)
                            )

                { relocatedNpcs, validHouses2 } =
                    List.foldl
                        (\( homelessNpcId, homelessNpc ) state ->
                            case
                                List.find
                                    (\validHouse ->
                                        Point2d.distanceFrom
                                            (Coord.toPoint2d validHouse.position)
                                            (Coord.toPoint2d homelessNpc.home)
                                            |> Quantity.lessThan (Units.tileUnit 3)
                                    )
                                    state.validHouses2
                            of
                                Just validHouse ->
                                    { validHouses2 = List.remove validHouse state.validHouses2
                                    , relocatedNpcs = ( homelessNpcId, validHouse.position ) :: state.relocatedNpcs
                                    }

                                Nothing ->
                                    state
                        )
                        { validHouses2 = validHouses, relocatedNpcs = [] }
                        homelessNpcs

                maybeNewNpc : Maybe ( Id NpcId, Npc )
                maybeNewNpc =
                    case Nonempty.fromList validHouses2 of
                        Just nonempty ->
                            let
                                npc : Npc
                                npc =
                                    Random.step
                                        (Npc.random nonempty newTime)
                                        (Random.initialSeed (Effect.Time.posixToMillis newTime))
                                        |> Tuple.first

                                npcId : Id NpcId
                                npcId =
                                    LocalGrid.nextId model.npcs
                            in
                            Just ( npcId, npc )

                        Nothing ->
                            Nothing

                npcs2 : SeqDict (Id NpcId) Npc
                npcs2 =
                    List.foldl
                        (\( npcId, position ) npcs -> SeqDict.updateIfExists npcId (\npc -> { npc | home = position }) npcs)
                        model.npcs
                        relocatedNpcs

                npcs3 : SeqDict (Id NpcId) Npc
                npcs3 =
                    case maybeNewNpc of
                        Just ( newNpcId, newNpc ) ->
                            SeqDict.insert newNpcId newNpc npcs2

                        Nothing ->
                            npcs2

                npcs4 : SeqDict (Id NpcId) Npc
                npcs4 =
                    SeqDict.map (Npc.updateNpcPath newTime model.grid) npcs3
            in
            ( npcs4
            , { maybeNewNpc = maybeNewNpc
              , relocatedNpcs = relocatedNpcs
              , movementChanges =
                    SeqDict.map
                        (\_ npc ->
                            { position = npc.position
                            , startTime = npc.startTime
                            , endPosition = npc.endPosition
                            , visitedPositions = npc.visitedPositions
                            }
                        )
                        npcs4
                        |> SeqDict.toList
              }
            )

        TrainsAndAnimalsDisabled ->
            ( model.npcs, { maybeNewNpc = Nothing, relocatedNpcs = [], movementChanges = [] } )


updateAnimals :
    BackendModel
    -> Effect.Time.Posix
    ->
        ( SeqDict (Id AnimalId) Animal
        , List
            ( Id AnimalId
            , { position : Point2d WorldUnit WorldUnit
              , endPosition : Point2d WorldUnit WorldUnit
              , startTime : Effect.Time.Posix
              }
            )
        )
updateAnimals model time =
    case model.trainsAndAnimalsDisabled of
        TrainsAndAnimalsEnabled ->
            let
                newAnimals2 : SeqDict (Id AnimalId) Animal
                newAnimals2 =
                    SeqDict.map
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
                                            (Npc.randomMovement start)
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
                                        , name = animal.name
                                        }

                                    Nothing ->
                                        animal
                        )
                        model.animals
            in
            ( newAnimals2
            , SeqDict.merge
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


addError : Effect.Time.Posix -> BackendError -> BackendModel -> BackendModel
addError time error model =
    { model | errors = ( time, error ) :: model.errors }


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUserData )
getUserFromSessionId sessionId model =
    case Dict.get (Effect.Lamdera.sessionIdToString sessionId) model.userSessions of
        Just { userId } ->
            case userId of
                Just userId2 ->
                    case SeqDict.get userId2 model.users of
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
    case SeqDict.get userId model.users of
        Just user ->
            let
                ( model2, _, firstMsg ) =
                    updateLocalChangeBot userId user time (Nonempty.head changes) model

                ( model3, serverChanges ) =
                    Nonempty.tail changes
                        |> List.foldl
                            (\change ( model_, serverChanges_ ) ->
                                case SeqDict.get userId model_.users of
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
                (\sessionId_ _ sessionUserId _ ->
                    Nonempty.toList serverChanges
                        |> List.filterMap
                            (\broadcastTo ->
                                case broadcastTo of
                                    BroadcastToEveryoneElse serverChange ->
                                        Change.ServerChange serverChange |> Just

                                    BroadcastToAdmin serverChange ->
                                        case sessionUserId of
                                            Just userId2 ->
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
            (\sessionId_ clientId_ sessionUserId _ ->
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
                                        case sessionUserId of
                                            Just userId2 ->
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
                            SeqDict.toList model.users
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
                                SeqDict.toList model2.users
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
                            case SeqDict.get pending.userId model.users of
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
                                                (\sessionId2 _ _ _ ->
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
                if SeqDict.size model.trains < 50 then
                    Train.handleAddingTrain model.trains userId change.change change.position

                else
                    Nothing

            { removed, newCells } =
                Grid.addChangeBackend change model.grid

            nextCowId =
                LocalGrid.nextId model.animals |> Id.toInt

            newAnimals : List ( Id AnimalId, Animal )
            newAnimals =
                List.concatMap LocalGrid.getAnimalsForCell newCells
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
                                        SeqDict.insert trainId train model.trains

                                    Nothing ->
                                        model.trains
                            , animals =
                                SeqDict.union
                                    (LocalGrid.updateAnimalMovement localChange model.animals)
                                    (SeqDict.fromList newAnimals)
                            , npcs = LocalGrid.updateNpcMovement localChange model.npcs
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
                    SeqDict.toList model.trains
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

        PickupAnimalOrNpc animalId position time2 ->
            asUser2
                (\userId _ ->
                    if model.isGridReadOnly then
                        ( model, InvalidChange, BroadcastToNoOne )

                    else
                        let
                            isAlreadyHeld : Bool
                            isAlreadyHeld =
                                SeqDict.toList model.users
                                    |> List.any
                                        (\( _, user2 ) ->
                                            case user2.cursor of
                                                Just cursor ->
                                                    case cursor.holding of
                                                        HoldingAnimalOrNpc holding ->
                                                            holding.animalOrNpcId == animalId

                                                        NotHolding ->
                                                            False

                                                Nothing ->
                                                    False
                                        )
                        in
                        if isAlreadyHeld then
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
                                                        , holding =
                                                            HoldingAnimalOrNpc
                                                                { animalOrNpcId = animalId
                                                                , pickupTime = time2
                                                                }
                                                    }
                                                        |> Just

                                                Nothing ->
                                                    Cursor.defaultCursor
                                                        position
                                                        (HoldingAnimalOrNpc
                                                            { animalOrNpcId = animalId
                                                            , pickupTime = time2
                                                            }
                                                        )
                                                        |> Just
                                    }
                                )
                                model
                            , PickupAnimalOrNpc animalId position (adjustEventTime time time2) |> NewLocalChange
                            , ServerPickupAnimalOrNpc userId animalId position time2 |> BroadcastToEveryoneElse
                            )
                )

        DropAnimalOrNpc animalOrNpcId position time2 ->
            asUser2
                (\userId _ ->
                    case SeqDict.get userId model.users |> Maybe.andThen .cursor of
                        Just cursor ->
                            case cursor.holding of
                                HoldingAnimalOrNpc holding ->
                                    let
                                        time3 =
                                            adjustEventTime time time2
                                    in
                                    if holding.animalOrNpcId == animalOrNpcId then
                                        ( updateUser
                                            userId
                                            (\user2 ->
                                                { user2
                                                    | cursor =
                                                        case user2.cursor of
                                                            Just cursor2 ->
                                                                { cursor2 | position = position, holding = NotHolding }
                                                                    |> Just

                                                            Nothing ->
                                                                Cursor.defaultCursor position NotHolding |> Just
                                                }
                                            )
                                            (case animalOrNpcId of
                                                AnimalId animalId ->
                                                    { model
                                                        | animals =
                                                            SeqDict.updateIfExists
                                                                animalId
                                                                (LocalGrid.placeAnimal position model.grid)
                                                                model.animals
                                                    }

                                                NpcId npcId ->
                                                    { model
                                                        | npcs =
                                                            SeqDict.updateIfExists
                                                                npcId
                                                                (LocalGrid.placeNpc time position model.grid)
                                                                model.npcs
                                                    }
                                            )
                                        , DropAnimalOrNpc animalOrNpcId position time3 |> NewLocalChange
                                        , ServerDropAnimalOrNpc userId animalOrNpcId position time3 |> BroadcastToEveryoneElse
                                        )

                                    else
                                        ( model, InvalidChange, BroadcastToNoOne )

                                NotHolding ->
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
                                            Cursor.defaultCursor position NotHolding |> Just
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
                    ( { model | users = SeqDict.insert userId { user | name = displayName } model.users }
                    , OriginalChange
                    , ServerChangeDisplayName userId displayName |> BroadcastToEveryoneElse
                    )
                )

        SubmitMail { to, content } ->
            asUser2
                (\userId user ->
                    let
                        mailId =
                            SeqDict.size model.mail |> Id.fromInt

                        newMail : SeqDict (Id MailId) BackendMail
                        newMail =
                            SeqDict.insert
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
                        , users = SeqDict.insert userId { user | mailDrafts = SeqDict.remove to user.mailDrafts } model.users
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
                            SeqDict.insert
                                userId
                                { user | mailDrafts = SeqDict.insert to content user.mailDrafts }
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
                    ( { model | trains = SeqDict.updateIfExists trainId (Train.startTeleportingHome adjustedTime) model.trains }
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
                    ( { model | trains = SeqDict.updateIfExists trainId (Train.leaveHome adjustedTime) model.trains }
                    , LeaveHomeTrainRequest trainId adjustedTime |> NewLocalChange
                    , ServerLeaveHomeTrainRequest trainId adjustedTime |> BroadcastToEveryoneElse
                    )
                )

        ViewedMail mailId ->
            asUser2
                (\userId _ ->
                    case SeqDict.get mailId model.mail of
                        Just mail ->
                            case ( mail.to == userId, mail.status ) of
                                ( True, MailReceived data ) ->
                                    ( { model
                                        | mail =
                                            SeqDict.insert mailId { mail | status = MailReceivedAndViewed data } model.mail
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
                            SeqDict.insert userId
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
                        , users = SeqDict.update userId (\_ -> Just { user | cursor = Nothing }) model.users
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

        VisitedHyperlink hyperlink ->
            asUser2
                (\userId user ->
                    ( updateHumanUser
                        (\a ->
                            { a
                                | hyperlinksVisited = Set.insert (Hyperlink.toString hyperlink) a.hyperlinksVisited
                            }
                        )
                        userId
                        user
                        model
                    , OriginalChange
                    , BroadcastToNoOne
                    )
                )

        RenameAnimalOrNpc animalOrNpcId name ->
            asUser2
                (\_ _ ->
                    ( LocalGrid.renameAnimalOrNpc animalOrNpcId name model
                    , OriginalChange
                    , BroadcastToEveryoneElse (ServerRenameAnimalOrNpc animalOrNpcId name)
                    )
                )


updateHumanUser : (HumanUserData -> HumanUserData) -> Id UserId -> BackendUserData -> BackendModel -> BackendModel
updateHumanUser updateFunc userId user model =
    { model
        | users =
            SeqDict.insert
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
                        , animals = SeqDict.fromList newCows |> SeqDict.union model.animals
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
            LocalGrid.nextId model.animals |> Id.toInt

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
                                LocalGrid.getAnimalsForCell coord

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
        | trains = SeqDict.remove trainId model.trains
        , mail =
            SeqDict.map
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
    { model | users = SeqDict.updateIfExists userId updateUserFunc model.users }


getUserInbox : Id UserId -> BackendModel -> SeqDict (Id MailId) MailEditor.ReceivedMail
getUserInbox userId model =
    SeqDict.filterMap
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
    case SeqDict.get userId model.reported of
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
    , hyperlinksVisited = humanUser.hyperlinksVisited
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
                                , hyperlinksVisited = humanUser.hyperlinksVisited
                                }

                        BotUser ->
                            NotLoggedIn { timeOfDay = Automatic }

                Nothing ->
                    NotLoggedIn { timeOfDay = Automatic }
            , model
            )

        ( userStatus, model2 ) =
            case maybeToken of
                Just (LoginToken2 loginToken) ->
                    case AssocList.get loginToken model.pendingLoginTokens of
                        Just data ->
                            if Duration.from data.requestTime currentTime |> Quantity.lessThan Duration.day then
                                case SeqDict.get data.userId model.users of
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
                                                    , hyperlinksVisited = humanUser.hyperlinksVisited
                                                    }
                                                , { model | pendingLoginTokens = AssocList.remove loginToken model.pendingLoginTokens }
                                                )

                                            BotUser ->
                                                ( NotLoggedIn { timeOfDay = Automatic }
                                                , addError currentTime (UserNotFoundWhenLoggingIn data.userId) model
                                                )

                                    Nothing ->
                                        ( NotLoggedIn { timeOfDay = Automatic }
                                        , addError currentTime (UserNotFoundWhenLoggingIn data.userId) model
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
                                        , hyperlinksVisited = humanUser.hyperlinksVisited
                                        }
                                    , { model4
                                        | invites = AssocList.remove inviteToken model.invites
                                        , users =
                                            SeqDict.updateIfExists
                                                invite.invitedBy
                                                (\user ->
                                                    case user.userType of
                                                        HumanUser humanUser2 ->
                                                            { user
                                                                | userType =
                                                                    { humanUser2
                                                                        | acceptedInvites =
                                                                            SeqDict.insert userId () humanUser2.acceptedInvites
                                                                    }
                                                                        |> HumanUser
                                                            }

                                                        BotUser ->
                                                            user
                                                )
                                                model4.users
                                      }
                                    )

                                BotUser ->
                                    ( NotLoggedIn { timeOfDay = Automatic }, model4 )

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
                { model2 | grid = newGrid, animals = SeqDict.fromList newCows |> SeqDict.union model.animals }

        loadingData : LoadingData_
        loadingData =
            { grid =
                List.map (\( coord, cell ) -> ( Coord.toTuple coord, cell )) cells
                    |> Dict.fromList
                    |> Grid.fromData
            , userStatus = userStatus
            , viewBounds = viewBounds
            , trains = model3.trains
            , mail = SeqDict.map (\_ mail -> { status = mail.status, from = mail.from, to = mail.to }) model3.mail
            , animals = model3.animals
            , cursors = SeqDict.filterMap (\_ a -> a.cursor) model3.users
            , users = SeqDict.map (\_ a -> backendUserToFrontend a) model3.users
            , inviteTree =
                invitesToInviteTree adminId model3.users
                    |> Maybe.withDefault (InviteTree { userId = adminId, invited = [] })
            , isGridReadOnly = model.isGridReadOnly
            , trainsDisabled = model.trainsAndAnimalsDisabled
            , npcs = model.npcs
            }

        frontendUser : FrontendUser
        frontendUser =
            case userStatus of
                LoggedIn loggedIn ->
                    case SeqDict.get loggedIn.userId model3.users of
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
                    (\sessionId2 clientId2 _ _ ->
                        if clientId2 == clientId then
                            Nothing

                        else if sessionId2 == sessionId then
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


invitesToInviteTree : Id UserId -> SeqDict (Id UserId) BackendUserData -> Maybe InviteTree
invitesToInviteTree rootUserId users =
    case SeqDict.get rootUserId users of
        Just user ->
            case user.userType of
                HumanUser humanUser ->
                    { userId = rootUserId
                    , invited =
                        List.filterMap
                            (\( userId, () ) -> invitesToInviteTree userId users)
                            (SeqDict.toList humanUser.acceptedInvites)
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
            , mailDrafts = SeqDict.empty
            , cursor = Nothing
            , handColor = Cursor.defaultColors
            , name = DisplayName.default
            , userType =
                HumanUser
                    { emailAddress = emailAddress
                    , acceptedInvites = SeqDict.empty
                    , allowEmailNotifications = True
                    , timeOfDay = Automatic
                    , tileHotkeys = AssocList.empty
                    , showNotifications = False
                    , notificationsClearedAt = Effect.Time.millisToPosix 0
                    , hyperlinksVisited = Set.empty
                    }
            }
    in
    ( { model | users = SeqDict.insert userId userBackendData model.users }, userBackendData )


createBotUser : DisplayName -> BackendModel -> ( BackendModel, Id UserId )
createBotUser name model =
    let
        userBackendData : BackendUserData
        userBackendData =
            { undoHistory = []
            , redoHistory = []
            , undoCurrent = Dict.empty
            , mailDrafts = SeqDict.empty
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
            SeqDict.insert id userBackendData model.users
                |> SeqDict.updateIfExists
                    adminId
                    (\user ->
                        case user.userType of
                            HumanUser humanUser ->
                                { user
                                    | userType =
                                        { humanUser | acceptedInvites = SeqDict.insert id () humanUser.acceptedInvites } |> HumanUser
                                }

                            BotUser ->
                                user
                    )
      }
    , id
    )


broadcast :
    (SessionId -> ClientId -> Maybe (Id UserId) -> List (Bounds CellUnit) -> Maybe ToFrontend)
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
broadcast msgFunc model =
    model.userSessions
        |> Dict.toList
        |> List.concatMap
            (\( sessionId, session ) ->
                AssocList.toList session.clientIds
                    |> List.filterMap
                        (\( clientId, viewBounds ) ->
                            msgFunc (Effect.Lamdera.sessionIdFromString sessionId) clientId session.userId viewBounds
                                |> Maybe.map (Effect.Lamdera.sendToFrontend clientId)
                        )
            )
        |> Command.batch
