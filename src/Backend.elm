module Backend exposing (app, app_)

import Animal exposing (Animal)
import AssocList
import Bounds exposing (Bounds)
import Change exposing (AdminChange(..), AdminData, AreTrainsDisabled(..), ClientChange(..), LocalChange(..), ServerChange(..), UserStatus(..))
import Coord exposing (Coord, RawCellCoord)
import Crypto.Hash
import Cursor
import Dict
import DisplayName
import Duration
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
import GridCell
import Id exposing (AnimalId, EventId, Id, MailId, SecretId, TrainId, UserId)
import IdDict exposing (IdDict)
import Lamdera
import List.Extra as List
import List.Nonempty as Nonempty exposing (Nonempty(..))
import LocalGrid
import MailEditor exposing (BackendMail, MailStatus(..), MailStatus2(..))
import Postmark exposing (PostmarkSend, PostmarkSendResponse)
import Quantity
import Route exposing (LoginOrInviteToken(..), PageRoute(..), Route(..))
import String.Nonempty exposing (NonemptyString(..))
import Tile exposing (RailPathType(..))
import TimeOfDay exposing (TimeOfDay(..))
import Train exposing (Status(..), Train, TrainDiff)
import Types exposing (..)
import Undo
import Units exposing (CellUnit)
import Untrusted exposing (Validation(..))
import User exposing (FrontendUser, InviteTree(..))


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
        { init : ( BackendModel, Command restriction toMsg msg )
        , update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        , updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        , subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
        }
app_ isProduction =
    { init = ( init, Command.none )
    , update = update isProduction
    , updateFromFrontend =
        \sessionId clientId msg model ->
            ( model, Effect.Time.now |> Effect.Task.perform (UpdateFromFrontend sessionId clientId msg) )
    , subscriptions = subscriptions
    }


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.batch
        [ Effect.Lamdera.onDisconnect UserDisconnected
        , Effect.Lamdera.onConnect UserConnected
        , Effect.Time.every
            (if Dict.toList model.userSessions |> List.all (\( _, { clientIds } ) -> AssocList.isEmpty clientIds) then
                Duration.minute

             else
                Duration.second
            )
            WorldUpdateTimeElapsed
        , Effect.Time.every (Duration.seconds 10) (\_ -> CheckConnectionTimeElapsed)
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
            , lastCacheRegeneration = Nothing
            , reported = IdDict.empty
            , isGridReadOnly = False
            , trainsDisabled = TrainsEnabled
            , lastReportEmailToAdmin = Nothing
            }
    in
    case Env.adminEmail of
        Just adminEmail ->
            createUser adminId adminEmail model |> Tuple.first

        Nothing ->
            model


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
                    handleWorldUpdate isProduction oldTime time model

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
            ( model, broadcast (\_ _ -> Just CheckConnectionBroadcast) model )

        SentMailNotification sendTime emailAddress result ->
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError sendTime (PostmarkError emailAddress error) model, Command.none )

        RegenerateCache time ->
            ( { model
                | grid =
                    Grid.allCellsDict model.grid
                        |> Dict.map (\cellPosition cell -> GridCell.updateCache (Coord.tuple cellPosition) cell)
                        |> Grid.from
                , lastCacheRegeneration = Just time
              }
            , Command.none
            )

        SentReportVandalismAdminEmail sendTime emailAddress result ->
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    ( addError sendTime (PostmarkError emailAddress error) model, Command.none )


handleWorldUpdate : Bool -> Effect.Time.Posix -> Effect.Time.Posix -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleWorldUpdate isProduction oldTime time model =
    let
        newTrains : IdDict TrainId Train
        newTrains =
            case model.trainsDisabled of
                TrainsDisabled ->
                    model.trains

                TrainsEnabled ->
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
                                    if user.allowEmailNotifications then
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
                                                (SentMailNotification time user.emailAddress)
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
                                                user.emailAddress
                                                :: state.cmds
                                        }

                                    else
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
    in
    ( { model3
        | lastWorldUpdate = Just time
        , trains = newTrains
        , lastWorldUpdateTrains = model3.trains
        , mail = mergeTrains.mail
      }
    , Command.batch [ Command.batch emailNotifications.cmds, broadcastChanges ]
    )


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


broadcastLocalChange :
    Bool
    -> Effect.Time.Posix
    -> SessionId
    -> ClientId
    -> Nonempty ( Id EventId, Change.LocalChange )
    -> Id UserId
    -> BackendUserData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
broadcastLocalChange isProduction time sessionId clientId changes userId user model =
    let
        ( model2, ( eventId, originalChange ), firstMsg ) =
            updateLocalChange sessionId time userId user (Nonempty.head changes) model

        ( model3, originalChanges2, serverChanges ) =
            Nonempty.tail changes
                |> List.foldl
                    (\change ( model_, originalChanges, serverChanges_ ) ->
                        case IdDict.get userId model_.users of
                            Just user2 ->
                                let
                                    ( newModel, ( eventId2, originalChange2 ), serverChange_ ) =
                                        updateLocalChange sessionId time userId user2 change model_
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
                    ChangeBroadcast originalChanges2 |> Just

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
                sendEmail
                    isProduction
                    (SentReportVandalismAdminEmail time adminUser.emailAddress)
                    (NonemptyString 'V' "andalism reported")
                    "Vandalism reported"
                    (Email.Html.text "Vandalism reported")
                    adminUser.emailAddress

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
                (broadcastLocalChange isProduction currentTime sessionId clientId changes)

        ChangeViewBounds bounds ->
            case
                Dict.get (Effect.Lamdera.sessionIdToString sessionId) model.userSessions
                    |> Maybe.andThen (\{ clientIds } -> AssocList.get clientId clientIds)
            of
                Just oldBounds ->
                    let
                        ( newGrid, cells, newCows ) =
                            generateVisibleRegion (Just oldBounds) bounds model

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
                                                            (\_ -> Just bounds)
                                                            session.clientIds
                                                }
                                            )
                                        )
                                        model.userSessions
                                , cows = IdDict.fromList newCows |> IdDict.union model.cows
                                , grid = newGrid
                            }
                    in
                    ( model2
                    , broadcast
                        (\_ clientId2 ->
                            if clientId2 == clientId then
                                ViewBoundsChange bounds cells newCows
                                    |> Change.ClientChange
                                    |> Nonempty.fromElement
                                    |> ChangeBroadcast
                                    |> Just

                            else
                                case Nonempty.fromList newCows of
                                    Just nonempty ->
                                        ServerNewCows nonempty
                                            |> Change.ServerChange
                                            |> Nonempty.fromElement
                                            |> ChangeBroadcast
                                            |> Just

                                    Nothing ->
                                        Nothing
                        )
                        model2
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
                                        , page = WorldRoute
                                        , viewPoint = Route.startPointAt
                                        }
                                    )
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
                                        { requestTime = currentTime
                                        , userId = userId
                                        , requestedBy = LoginRequestedByFrontend sessionId
                                        }
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


updateLocalChange :
    SessionId
    -> Effect.Time.Posix
    -> Id UserId
    -> BackendUserData
    -> ( Id EventId, Change.LocalChange )
    -> BackendModel
    -> ( BackendModel, ( Id EventId, Change.LocalChange ), BroadcastTo )
updateLocalChange sessionId time userId user (( eventId, change ) as originalChange) model =
    let
        invalidChange =
            ( eventId, Change.InvalidChange )
    in
    case change of
        Change.LocalUndo ->
            case ( model.isGridReadOnly, Undo.undo user ) of
                ( False, Just newUser ) ->
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
                    , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> BroadcastToEveryoneElse
                    )

                _ ->
                    ( model, invalidChange, BroadcastToNoOne )

        Change.LocalGridChange localChange ->
            if model.isGridReadOnly then
                ( model, invalidChange, BroadcastToNoOne )

            else
                let
                    localChange2 : Grid.LocalGridChange
                    localChange2 =
                        { position = localChange.position
                        , change = localChange.change
                        , colors = localChange.colors
                        , time = time
                        }

                    ( cellPosition, localPosition ) =
                        Grid.worldToCellAndLocalCoord localChange2.position

                    maybeTrain : Maybe ( Id TrainId, Train )
                    maybeTrain =
                        if IdDict.size model.trains < 50 then
                            Train.handleAddingTrain model.trains userId localChange2.change localChange2.position

                        else
                            Nothing

                    { removed, newCells } =
                        Grid.addChange (Grid.localChangeToChange userId localChange2) model.grid

                    nextCowId =
                        IdDict.nextId model.cows |> Id.toInt

                    newCows : List ( Id AnimalId, Animal )
                    newCows =
                        List.concatMap LocalGrid.getCowsForCell newCells
                            |> List.indexedMap (\index cow -> ( Id.fromInt (nextCowId + index), cow ))
                in
                case Train.canRemoveTiles time removed model.trains of
                    Ok trainsToRemove ->
                        ( List.map Tuple.first trainsToRemove
                            |> List.foldl
                                removeTrain
                                { model
                                    | grid =
                                        Grid.addChange (Grid.localChangeToChange userId localChange2) model.grid
                                            |> .grid
                                    , trains =
                                        case maybeTrain of
                                            Just ( trainId, train ) ->
                                                IdDict.insert trainId train model.trains

                                            Nothing ->
                                                model.trains
                                    , cows = IdDict.fromList newCows |> IdDict.union model.cows
                                }
                            |> updateUser
                                userId
                                (always
                                    { user
                                        | undoCurrent =
                                            LocalGrid.incrementUndoCurrent cellPosition localPosition user.undoCurrent
                                    }
                                )
                        , ( eventId, Change.LocalGridChange localChange2 )
                        , ServerGridChange
                            { gridChange = Grid.localChangeToChange userId localChange2
                            , newCells = newCells
                            , newCows = newCows
                            }
                            |> BroadcastToEveryoneElse
                        )

                    Err _ ->
                        ( model, invalidChange, BroadcastToNoOne )

        Change.LocalRedo ->
            case ( model.isGridReadOnly, Undo.redo user ) of
                ( False, Just newUser ) ->
                    let
                        undoMoveAmount =
                            newUser.undoCurrent
                    in
                    ( { model
                        | grid = Grid.moveUndoPoint userId undoMoveAmount model.grid
                      }
                        |> updateUser userId (always newUser)
                    , originalChange
                    , ServerUndoPoint { userId = userId, undoPoints = undoMoveAmount } |> BroadcastToEveryoneElse
                    )

                _ ->
                    ( model, invalidChange, BroadcastToNoOne )

        Change.LocalAddUndo ->
            if model.isGridReadOnly then
                ( model, invalidChange, BroadcastToNoOne )

            else
                ( updateUser userId Undo.add model, originalChange, BroadcastToNoOne )

        Change.InvalidChange ->
            ( model, originalChange, BroadcastToNoOne )

        PickupCow cowId position time2 ->
            if model.isGridReadOnly then
                ( model, invalidChange, BroadcastToNoOne )

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
                    ( model, ( eventId, InvalidChange ), BroadcastToNoOne )

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
                    , ( eventId, PickupCow cowId position (adjustEventTime time time2) )
                    , ServerPickupCow userId cowId position time2 |> BroadcastToEveryoneElse
                    )

        DropCow cowId position time2 ->
            case IdDict.get userId model.users |> Maybe.andThen .cursor of
                Just cursor ->
                    case cursor.holdingCow of
                        Just holdingCow ->
                            if holdingCow.cowId == cowId then
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
                                        | cows =
                                            IdDict.update2
                                                cowId
                                                (\cow -> { cow | position = position })
                                                model.cows
                                    }
                                , ( eventId, DropCow cowId position (adjustEventTime time time2) )
                                , ServerDropCow userId cowId position |> BroadcastToEveryoneElse
                                )

                            else
                                ( model, ( eventId, InvalidChange ), BroadcastToNoOne )

                        Nothing ->
                            ( model, ( eventId, InvalidChange ), BroadcastToNoOne )

                Nothing ->
                    ( model, ( eventId, InvalidChange ), BroadcastToNoOne )

        MoveCursor position ->
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
            , originalChange
            , ServerMoveCursor userId position |> BroadcastToEveryoneElse
            )

        ChangeHandColor colors ->
            ( updateUser
                userId
                (\user2 -> { user2 | handColor = colors })
                model
            , originalChange
            , ServerChangeHandColor userId colors |> BroadcastToEveryoneElse
            )

        ToggleRailSplit coord ->
            ( { model | grid = Grid.toggleRailSplit coord model.grid }
            , originalChange
            , ServerToggleRailSplit coord |> BroadcastToEveryoneElse
            )

        ChangeDisplayName displayName ->
            ( { model | users = IdDict.insert userId { user | name = displayName } model.users }
            , originalChange
            , ServerChangeDisplayName userId displayName |> BroadcastToEveryoneElse
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
            , ServerSubmitMail { to = to, from = userId } |> BroadcastToEveryoneElse
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
            , BroadcastToNoOne
            )

        TeleportHomeTrainRequest trainId teleportTime ->
            let
                adjustedTime =
                    adjustEventTime time teleportTime
            in
            ( { model | trains = IdDict.update2 trainId (Train.startTeleportingHome adjustedTime) model.trains }
            , ( eventId, TeleportHomeTrainRequest trainId adjustedTime )
            , ServerTeleportHomeTrainRequest trainId adjustedTime |> BroadcastToEveryoneElse
            )

        LeaveHomeTrainRequest trainId leaveTime ->
            let
                adjustedTime =
                    adjustEventTime time leaveTime
            in
            ( { model | trains = IdDict.update2 trainId (Train.leaveHome adjustedTime) model.trains }
            , ( eventId, LeaveHomeTrainRequest trainId adjustedTime )
            , ServerLeaveHomeTrainRequest trainId adjustedTime |> BroadcastToEveryoneElse
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
                            , ServerViewedMail mailId userId |> BroadcastToEveryoneElse
                            )

                        _ ->
                            ( model, invalidChange, BroadcastToNoOne )

                Nothing ->
                    ( model, invalidChange, BroadcastToNoOne )

        SetAllowEmailNotifications allow ->
            ( { model | users = IdDict.insert userId { user | allowEmailNotifications = allow } model.users }
            , originalChange
            , BroadcastToNoOne
            )

        ChangeTool tool ->
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
            , originalChange
            , ServerChangeTool userId tool |> BroadcastToEveryoneElse
            )

        ReportVandalism report ->
            let
                backendReport =
                    { reportedUser = report.reportedUser
                    , position = report.position
                    , reportedAt = time
                    }
            in
            ( { model | reported = LocalGrid.addReported userId backendReport model.reported }
            , originalChange
            , ServerVandalismReportedToAdmin userId backendReport |> BroadcastToAdmin
            )

        RemoveReport position ->
            ( { model | reported = LocalGrid.removeReported userId position model.reported }
            , originalChange
            , ServerVandalismRemovedToAdmin userId position |> BroadcastToAdmin
            )

        AdminChange adminChange ->
            if userId == adminId then
                case adminChange of
                    AdminResetSessions ->
                        ( { model
                            | userSessions = Dict.map (\_ data -> { data | clientIds = AssocList.empty }) model.userSessions
                          }
                        , originalChange
                        , BroadcastToNoOne
                        )

                    AdminSetGridReadOnly isGridReadOnly ->
                        ( { model | isGridReadOnly = isGridReadOnly }
                        , originalChange
                        , ServerGridReadOnly isGridReadOnly |> BroadcastToEveryoneElse
                        )

                    AdminSetTrainsDisabled areTrainsDisabled ->
                        ( { model | trainsDisabled = areTrainsDisabled }
                        , originalChange
                        , ServerSetTrainsDisabled areTrainsDisabled |> BroadcastToEveryoneElse
                        )

                    AdminDeleteMail mailId deleteTime ->
                        let
                            adjustedTime =
                                adjustEventTime time deleteTime
                        in
                        ( LocalGrid.deleteMail mailId adjustedTime model
                        , ( eventId, AdminDeleteMail mailId adjustedTime |> AdminChange )
                        , BroadcastToNoOne
                        )

                    AdminRestoreMail mailId ->
                        ( LocalGrid.restoreMail mailId model
                        , originalChange
                        , BroadcastToNoOne
                        )

            else
                ( model, invalidChange, BroadcastToNoOne )

        SetTimeOfDay timeOfDay ->
            ( { model | users = IdDict.insert userId { user | timeOfDay = timeOfDay } model.users }
            , originalChange
            , BroadcastToNoOne
            )

        SetTileHotkey tileHotkey tileGroup ->
            ( { model
                | users =
                    IdDict.insert
                        userId
                        (LocalGrid.setTileHotkey tileHotkey tileGroup user)
                        model.users
              }
            , originalChange
            , BroadcastToNoOne
            )

        ShowNotifications showNotifications ->
            ( { model
                | users =
                    IdDict.insert
                        userId
                        { user | showNotifications = showNotifications }
                        model.users
              }
            , originalChange
            , BroadcastToNoOne
            )

        Logout ->
            ( { model
                | userSessions =
                    Dict.update
                        (Effect.Lamdera.sessionIdToString sessionId)
                        (Maybe.map (\session -> { session | userId = Nothing }))
                        model.userSessions
                , users = IdDict.update userId (\_ -> Just { user | cursor = Nothing }) model.users
              }
            , originalChange
            , BroadcastToRestOfSessionAndEveryoneElse sessionId ServerLogout (ServerUserDisconnected userId)
            )


generateVisibleRegion :
    Maybe (Bounds CellUnit)
    -> Bounds CellUnit
    -> BackendModel
    -> ( Grid, List ( Coord CellUnit, GridCell.CellData ), List ( Id d, Animal ) )
generateVisibleRegion maybeOldBounds bounds model =
    let
        nextCowId =
            IdDict.nextId model.cows |> Id.toInt

        newCells =
            Bounds.coordRangeFold
                (\coord state ->
                    if maybeOldBounds |> Maybe.map (Bounds.contains coord) |> Maybe.withDefault False then
                        state

                    else
                        let
                            data =
                                Grid.getCell2 coord state.grid

                            newCows : List Animal
                            newCows =
                                if data.isNew then
                                    LocalGrid.getCowsForCell coord

                                else
                                    []
                        in
                        { grid = data.grid
                        , cows = newCows ++ state.cows
                        , cells = ( coord, GridCell.cellToData data.cell ) :: state.cells
                        }
                )
                identity
                bounds
                { grid = model.grid, cows = [], cells = [] }
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

                    MailDeletedByAdmin record ->
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
                        , adminData = getAdminData userId model
                        , reports = getUserReports userId model
                        , isGridReadOnly = model.isGridReadOnly
                        , timeOfDay = user.timeOfDay
                        , tileHotkeys = user.tileHotkeys
                        , showNotifications = user.showNotifications
                        , notifications =
                            Grid.latestChanges (Effect.Time.millisToPosix 0) userId model.grid
                                |> List.foldl LocalGrid.addNotification []
                        }

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
                                        ( LoggedIn
                                            { userId = data.userId
                                            , undoCurrent = user.undoCurrent
                                            , undoHistory = user.undoHistory
                                            , redoHistory = user.redoHistory
                                            , mailDrafts = user.mailDrafts
                                            , emailAddress = user.emailAddress
                                            , inbox = getUserInbox data.userId model
                                            , allowEmailNotifications = user.allowEmailNotifications
                                            , adminData = getAdminData data.userId model
                                            , reports = getUserReports data.userId model
                                            , isGridReadOnly = model.isGridReadOnly
                                            , timeOfDay = user.timeOfDay
                                            , tileHotkeys = user.tileHotkeys
                                            , showNotifications = user.showNotifications
                                            , notifications =
                                                Grid.latestChanges (Effect.Time.millisToPosix 0) data.userId model.grid
                                                    |> List.foldl LocalGrid.addNotification []
                                            }
                                        , { model | pendingLoginTokens = AssocList.remove loginToken model.pendingLoginTokens }
                                        , case data.requestedBy of
                                            LoginRequestedByBackend ->
                                                Nothing

                                            LoginRequestedByFrontend requestedBy ->
                                                Just requestedBy
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
                                , adminData = getAdminData userId model
                                , reports = getUserReports userId model
                                , isGridReadOnly = model.isGridReadOnly
                                , timeOfDay = Automatic
                                , tileHotkeys = newUser.tileHotkeys
                                , showNotifications = newUser.showNotifications
                                , notifications = []
                                }
                            , { model4
                                | invites = AssocList.remove inviteToken model.invites
                                , users =
                                    IdDict.update2
                                        invite.invitedBy
                                        (\user -> { user | acceptedInvites = IdDict.insert userId () user.acceptedInvites })
                                        model4.users
                              }
                            , Nothing
                            )

                        Nothing ->
                            checkLogin ()

                Nothing ->
                    checkLogin ()

        ( newGrid, cells, newCows ) =
            generateVisibleRegion Nothing viewBounds model2

        model3 : BackendModel
        model3 =
            addSession
                sessionId
                clientId
                viewBounds
                userStatus
                { model2 | grid = newGrid, cows = IdDict.fromList newCows |> IdDict.union model.cows }
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
            , cows = model3.cows
            , cursors = IdDict.filterMap (\_ a -> a.cursor) model3.users
            , users = IdDict.map (\_ a -> backendUserToFrontend a) model3.users
            , inviteTree =
                invitesToInviteTree adminId model3.users
                    |> Maybe.withDefault (InviteTree { userId = adminId, invited = [] })
            , isGridReadOnly = model.isGridReadOnly
            , trainsDisabled = model.trainsDisabled
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
                            }

                NotLoggedIn _ ->
                    { handColor = Cursor.defaultColors
                    , name = DisplayName.default
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
                                { userId = loggedIn.userId
                                , user = frontendUser
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
            { userId = rootUserId
            , invited =
                List.filterMap
                    (\( userId, () ) -> invitesToInviteTree userId users)
                    (IdDict.toList user.acceptedInvites)
            }
                |> InviteTree
                |> Just

        Nothing ->
            Nothing


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

                                    NotLoggedIn _ ->
                                        Nothing
                            }

                        Nothing ->
                            { clientIds = AssocList.singleton clientId viewBounds
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
            , timeOfDay = Automatic
            , tileHotkeys = AssocList.empty
            , showNotifications = False
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
