module Frontend exposing (app, app_)

import AdminPage
import Animal exposing (Animal)
import Array
import AssocList
import Audio exposing (Audio, AudioCmd, AudioData)
import BoundingBox2d exposing (BoundingBox2d)
import Bounds
import Browser
import Change exposing (AreTrainsDisabled(..), Change(..), UserStatus(..))
import Codec
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor exposing (Cursor, CursorSprite(..), CursorType(..))
import Dict exposing (Dict)
import DisplayName
import Duration exposing (Duration)
import Effect.Browser.Dom
import Effect.Browser.Events
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File
import Effect.File.Download
import Effect.File.Select
import Effect.Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Effect.WebGL exposing (Mesh)
import Effect.WebGL.Settings
import Effect.WebGL.Texture
import EmailAddress
import Env
import Flag
import Grid exposing (Grid)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Wheel exposing (DeltaMode(..))
import Id exposing (AnimalId, Id, TrainId, UserId)
import IdDict exposing (IdDict)
import Json.Decode
import Json.Encode
import Keyboard
import Keyboard.Arrows
import Lamdera
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import LoadingPage
import LocalGrid exposing (LocalGrid_)
import LocalModel
import MailEditor exposing (MailStatus(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import PingData
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Ports
import Quantity exposing (Quantity(..))
import Random
import Route
import Shaders exposing (DebrisVertex, MapOverlayVertex, RenderData)
import Sound exposing (Sound(..))
import Sprite exposing (Vertex)
import TextInput exposing (OutMsg(..))
import Tile exposing (Category(..), Tile(..), TileGroup(..))
import Time
import TimeOfDay exposing (TimeOfDay(..))
import Tool exposing (Tool(..))
import Toolbar
import Train exposing (Status(..), Train)
import Types exposing (..)
import Ui exposing (UiEvent)
import Units exposing (WorldUnit)
import Untrusted
import Url exposing (Url)
import Url.Parser
import Vector2d exposing (Vector2d)
import WebGL.Texture


app :
    { init : Url -> Lamdera.Key -> ( Audio.Model FrontendMsg_ FrontendModel_, Cmd (Audio.Msg FrontendMsg_) )
    , view : Audio.Model FrontendMsg_ FrontendModel_ -> Browser.Document (Audio.Msg FrontendMsg_)
    , update :
        Audio.Msg FrontendMsg_
        -> Audio.Model FrontendMsg_ FrontendModel_
        -> ( Audio.Model FrontendMsg_ FrontendModel_, Cmd (Audio.Msg FrontendMsg_) )
    , updateFromBackend :
        ToFrontend
        -> Audio.Model FrontendMsg_ FrontendModel_
        -> ( Audio.Model FrontendMsg_ FrontendModel_, Cmd (Audio.Msg FrontendMsg_) )
    , subscriptions : Audio.Model FrontendMsg_ FrontendModel_ -> Sub (Audio.Msg FrontendMsg_)
    , onUrlRequest : Browser.UrlRequest -> Audio.Msg FrontendMsg_
    , onUrlChange : Url -> Audio.Msg FrontendMsg_
    }
app =
    Effect.Lamdera.frontend Lamdera.sendToBackend app_


app_ =
    Audio.lamderaFrontendWithAudio
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \audioData msg model -> update audioData msg model
        , updateFromBackend = \_ msg model -> updateFromBackend msg model |> (\( a, b ) -> ( a, b, Audio.cmdNone ))
        , subscriptions = subscriptions
        , view = view
        , audio = audio
        , audioPort =
            { toJS = Command.sendToJs "audioPortToJS" Ports.audioPortToJS
            , fromJS = Subscription.fromJs "audioPortFromJS" Ports.audioPortFromJS
            }
        }


audio : AudioData -> FrontendModel_ -> Audio
audio audioData model =
    case model of
        Loaded loaded ->
            audioLoaded audioData loaded

        Loading _ ->
            Audio.silence


audioLoaded : AudioData -> FrontendLoaded -> Audio
audioLoaded audioData model =
    let
        localModel : LocalGrid_
        localModel =
            LocalGrid.localModel model.localModel

        timeOffset =
            PingData.pingOffset model

        playSound sound time =
            Sound.play model sound (Duration.subtractFrom time timeOffset)

        playWithConfig config sound time =
            Sound.playWithConfig audioData model config sound (Duration.subtractFrom time timeOffset)

        allTrains : List ( Id TrainId, Train )
        allTrains =
            IdDict.toList model.trains

        movingTrains : List { playbackRate : Float, volume : Float }
        movingTrains =
            List.filterMap
                (\( _, train ) ->
                    let
                        trainSpeed =
                            Train.speed model.time train
                    in
                    case
                        ( Quantity.abs trainSpeed |> Quantity.lessThan Train.stoppedSpeed
                        , Train.stuckOrDerailed model.time train
                        )
                    of
                        ( False, Train.IsNotStuckOrDerailed ) ->
                            let
                                position =
                                    Train.trainPosition model.time train
                            in
                            Just
                                { playbackRate = 0.9 * (abs (Quantity.unwrap trainSpeed) / Train.defaultMaxSpeed) + 0.1
                                , volume = volume model position * Quantity.unwrap trainSpeed / Train.defaultMaxSpeed |> abs
                                }

                        _ ->
                            Nothing
                )
                allTrains

        mailEditorVolumeScale : Float
        mailEditorVolumeScale =
            clamp
                0
                1
                (case ( model.lastMailEditorToggle, model.page ) of
                    ( Just time, WorldPage _ ) ->
                        Quantity.ratio (Duration.from time model.time) MailEditor.openAnimationLength

                    ( Just time, MailPage _ ) ->
                        1 - Quantity.ratio (Duration.from time model.time) MailEditor.openAnimationLength

                    ( _, AdminPage _ ) ->
                        0

                    ( _, InviteTreePage ) ->
                        0

                    ( Nothing, _ ) ->
                        1
                )
                * 0.75
                + 0.25

        volumeOffset : Float
        volumeOffset =
            mailEditorVolumeScale * 0.14 / ((List.map .volume movingTrains |> List.sum) + 1)

        trainSounds : Audio
        trainSounds =
            case localModel.trainsDisabled of
                TrainsDisabled ->
                    Audio.silence

                TrainsEnabled ->
                    List.map
                        (\train ->
                            playWithConfig
                                (\duration ->
                                    { loop = Just { loopStart = Quantity.zero, loopEnd = duration }
                                    , playbackRate = train.playbackRate
                                    , startAt = Quantity.zero
                                    }
                                )
                                ChugaChuga
                                (Effect.Time.millisToPosix 0)
                                |> Audio.scaleVolume (train.volume * volumeOffset)
                        )
                        movingTrains
                        |> Audio.group
    in
    [ case model.lastTilePlaced of
        Just { time, overwroteTiles, tile } ->
            if tile == EmptyTile then
                playSound EraseSound time |> Audio.scaleVolume 0.4

            else if overwroteTiles then
                playSound CrackleSound time |> Audio.scaleVolume 0.4

            else
                playSound PopSound time |> Audio.scaleVolume 0.4

        _ ->
            Audio.silence
    , trainSounds
    , List.map
        (\( _, train ) ->
            case Train.stuckOrDerailed model.time train of
                Train.IsDerailed derailTime _ ->
                    playSound TrainCrash derailTime
                        |> Audio.scaleVolume (volume model (Train.trainPosition model.time train) * 0.5)

                _ ->
                    Audio.silence
        )
        allTrains
        |> Audio.group
    , List.map
        (\( _, train ) ->
            case Train.status model.time train of
                TeleportingHome time ->
                    playSound TeleportSound time |> Audio.scaleVolume 0.8

                _ ->
                    Audio.silence
        )
        (IdDict.toList model.trains)
        |> Audio.group
    , case model.lastTrainWhistle of
        Just time ->
            playSound TrainWhistleSound time |> Audio.scaleVolume (0.2 * mailEditorVolumeScale)

        Nothing ->
            Audio.silence
    , case model.lastMailEditorToggle of
        Just time ->
            playSound PageTurnSound time |> Audio.scaleVolume 0.8

        Nothing ->
            Audio.silence
    , List.map (playSound WhooshSound) model.lastTileRotation |> Audio.group |> Audio.scaleVolume 0.5
    , case model.page of
        MailPage mailEditor ->
            [ List.map (playSound WhooshSound) mailEditor.lastRotation |> Audio.group |> Audio.scaleVolume 0.5
            , case mailEditor.lastPlacedImage of
                Just time ->
                    playSound PopSound time |> Audio.scaleVolume 0.4

                Nothing ->
                    Audio.silence
            , case mailEditor.lastErase of
                Just time ->
                    playSound EraseSound time |> Audio.scaleVolume 0.4

                Nothing ->
                    Audio.silence
            ]
                |> Audio.group

        _ ->
            Audio.silence
    , case model.lastPlacementError of
        Just time ->
            playSound ErrorSound time |> Audio.scaleVolume 0.4

        Nothing ->
            Audio.silence
    , case model.lastHouseClick of
        Just time ->
            Audio.group
                [ playSound KnockKnockSound time
                , Random.step
                    (Random.uniform
                        OldManSound
                        [ MmhmmSound
                        , NuhHuhSound
                        , HelloSound
                        , Hello2Sound
                        ]
                    )
                    (Effect.Time.posixToMillis time |> Random.initialSeed)
                    |> Tuple.first
                    |> (\sound ->
                            Sound.length audioData model.sounds KnockKnockSound
                                |> Quantity.plus (Duration.milliseconds 400)
                                |> Duration.addTo time
                                |> playSound sound
                       )
                ]
                |> Audio.scaleVolume 0.5

        Nothing ->
            Audio.silence
    , playSound model.music.sound model.music.startTime |> Audio.scaleVolume 0.5
    , playWithConfig
        (\duration ->
            { loop =
                Just
                    { loopStart = Quantity.zero
                    , loopEnd = duration
                    }
            , playbackRate = 1
            , startAt = Quantity.zero
            }
        )
        Ambience0
        (Effect.Time.millisToPosix 0)
    , playSound PopSound (Duration.addTo model.startTime (Duration.milliseconds 100))
        -- Increase the volume on this sound effect to compensate for the volume fade in at the start of the game
        |> Audio.scaleVolume 2
    , case model.lastReceivedMail of
        Just time ->
            playSound Meow time |> Audio.scaleVolume 0.8

        Nothing ->
            Audio.silence
    , case LocalGrid.currentUserId model of
        Just userId ->
            case IdDict.get userId localModel.cursors of
                Just cursor ->
                    case cursor.holdingCow of
                        Just { cowId, pickupTime } ->
                            case IdDict.get cowId localModel.animals of
                                Just animal ->
                                    let
                                        sounds : Nonempty ( Float, Sound )
                                        sounds =
                                            Animal.getData animal.animalType |> .sounds
                                    in
                                    playSound
                                        (Random.step
                                            (Random.weighted (List.Nonempty.head sounds) (List.Nonempty.tail sounds))
                                            (Random.initialSeed (Effect.Time.posixToMillis pickupTime))
                                            |> Tuple.first
                                        )
                                        pickupTime
                                        |> Audio.scaleVolume 0.5

                                Nothing ->
                                    Audio.silence

                        Nothing ->
                            Audio.silence

                Nothing ->
                    Audio.silence

        Nothing ->
            Audio.silence
    , List.map
        (\( time, position ) ->
            let
                tileCenter : Point2d WorldUnit WorldUnit
                tileCenter =
                    Point2d.translateBy
                        (Tile.getData RailTopToLeft_SplitDown
                            |> .size
                            |> Coord.toVector2d
                            |> Vector2d.scaleBy 0.5
                        )
                        (Coord.toPoint2d position)
            in
            playSound RailToggleSound time |> Audio.scaleVolume (0.5 * volume model tileCenter)
        )
        model.railToggles
        |> Audio.group
    , case model.lastReportTilePlaced of
        Just time ->
            playSound PopSound time |> Audio.scaleVolume 0.4

        Nothing ->
            Audio.silence
    , case model.lastReportTileRemoved of
        Just time ->
            playSound EraseSound time |> Audio.scaleVolume 0.4

        Nothing ->
            Audio.silence
    , case model.lightsSwitched of
        Just time ->
            playSound LightSwitch time |> Audio.scaleVolume 0.8

        Nothing ->
            Audio.silence
    , case model.lastHotkeyChange of
        Just time ->
            playSound PopSound time |> Audio.scaleVolume 0.8

        Nothing ->
            Audio.silence
    ]
        |> Audio.group
        |> Audio.scaleVolumeAt [ ( model.startTime, 0 ), ( Duration.addTo model.startTime Duration.second, 1 ) ]


volume : FrontendLoaded -> Point2d WorldUnit WorldUnit -> Float
volume model position =
    let
        boundingBox =
            viewBoundingBox model

        boundingBox2 =
            BoundingBox2d.offsetBy (Units.tileUnit -4) boundingBox |> Maybe.withDefault boundingBox
    in
    if BoundingBox2d.contains position boundingBox2 then
        1

    else
        let
            extrema =
                BoundingBox2d.extrema boundingBox2

            (Quantity minX) =
                extrema.minX

            (Quantity minY) =
                extrema.minY

            (Quantity maxX) =
                extrema.maxX

            (Quantity maxY) =
                extrema.maxY

            { x, y } =
                Point2d.unwrap position

            distance : Float
            distance =
                if x > minX && x < maxX then
                    min (abs (minY - y)) (abs (maxY - y))

                else
                    min (abs (minX - x)) (abs (maxX - x))
        in
        if distance > maxVolumeDistance then
            0

        else
            ((maxVolumeDistance - distance) / maxVolumeDistance) ^ 2


maxVolumeDistance : number
maxVolumeDistance =
    10


init : Url -> Effect.Browser.Navigation.Key -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
init url key =
    let
        { data, cmd } =
            let
                defaultRoute =
                    Route.internalRoute Route.startPointAt
            in
            case Route.decode url of
                Just (Route.InternalRoute a) ->
                    { data = a
                    , cmd =
                        Effect.Browser.Navigation.replaceUrl
                            key
                            (Route.encode (Route.InternalRoute { a | showInbox = False, loginOrInviteToken = Nothing }))
                    }

                Nothing ->
                    { data = { viewPoint = Route.startPointAt, showInbox = False, loginOrInviteToken = Nothing }
                    , cmd = Effect.Browser.Navigation.replaceUrl key (Route.encode defaultRoute)
                    }

        -- We only load in a portion of the grid since we don't know the window size yet. The rest will get loaded in later anyway.
        bounds =
            Bounds.bounds
                (Grid.worldToCellAndLocalCoord data.viewPoint
                    |> Tuple.first
                    |> Coord.plus ( Units.cellUnit -2, Units.cellUnit -2 )
                )
                (Grid.worldToCellAndLocalCoord data.viewPoint
                    |> Tuple.first
                    |> Coord.plus ( Units.cellUnit 2, Units.cellUnit 2 )
                )
    in
    ( Loading
        { key = key
        , windowSize = ( Pixels.pixels 1920, Pixels.pixels 1080 )
        , cssWindowSize = Coord.xy 1920 1080
        , cssCanvasSize = Coord.xy 1920 1080
        , devicePixelRatio = 1
        , zoomFactor = 1
        , time = Nothing
        , viewPoint = data.viewPoint
        , showInbox = data.showInbox
        , mousePosition = Point2d.origin
        , sounds = AssocList.empty
        , musicVolume = 0
        , soundEffectVolume = 0
        , texture = Nothing
        , lightsTexture = Nothing
        , depthTexture = Nothing
        , simplexNoiseLookup = Nothing
        , localModel = LoadingLocalModel []
        , hasCmdKey = False
        }
    , Command.batch
        [ Effect.Lamdera.sendToBackend (ConnectToBackend bounds data.loginOrInviteToken)
        , Command.sendToJs "user_agent_to_js" Ports.user_agent_to_js Json.Encode.null
        , Effect.Task.perform
            (\{ viewport } -> WindowResized (Coord.xy (round viewport.width) (round viewport.height)))
            Effect.Browser.Dom.getViewport
        , Effect.Task.perform (\time -> Duration.addTo time (PingData.pingOffset { pingData = Nothing }) |> ShortIntervalElapsed) Effect.Time.now
        , cmd
        , Ports.getLocalStorage
        ]
    , Audio.cmdNone
    )


update : AudioData -> FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
update audioData msg model =
    case model of
        Loading loadingModel ->
            LoadingPage.update msg loadingModel

        Loaded frontendLoaded ->
            updateLoaded audioData msg frontendLoaded
                |> (\( newModel, cmd ) ->
                        ( if LoadingPage.mouseWorldPosition newModel == LoadingPage.mouseWorldPosition frontendLoaded then
                            newModel

                          else
                            removeLastCursorMove newModel
                                |> updateLocalModel (Change.MoveCursor (LoadingPage.mouseWorldPosition newModel))
                                |> Tuple.first
                        , cmd
                        )
                   )
                |> (\( newModel, cmd ) ->
                        let
                            oldNightFactor : Float
                            oldNightFactor =
                                getNightFactor frontendLoaded

                            newNightFactor : Float
                            newNightFactor =
                                getNightFactor newModel

                            newModel2 =
                                if TimeOfDay.isDayTime oldNightFactor /= TimeOfDay.isDayTime newNightFactor then
                                    { newModel | lightsSwitched = Just newModel.time }

                                else
                                    newModel

                            newTool : Cursor.OtherUsersTool
                            newTool =
                                LocalGrid.currentTool newModel2 |> Tool.toCursor
                        in
                        ( if Tool.toCursor (LocalGrid.currentTool frontendLoaded) == newTool then
                            newModel2

                          else
                            updateLocalModel (Change.ChangeTool newTool) newModel2 |> Tuple.first
                        , cmd
                        )
                   )
                |> LoadingPage.viewBoundsUpdate
                |> Tuple.mapFirst (reportsMeshUpdate frontendLoaded)
                |> (\( a, b ) -> ( Loaded a, b, Audio.cmdNone ))


reportsMeshUpdate : FrontendLoaded -> FrontendLoaded -> FrontendLoaded
reportsMeshUpdate oldModel newModel =
    let
        newReports =
            LoadingPage.getReports newModel.localModel

        newAdminReports =
            LoadingPage.getAdminReports newModel.localModel
    in
    if LoadingPage.getReports oldModel.localModel == newReports && LoadingPage.getAdminReports oldModel.localModel == newAdminReports then
        newModel

    else
        { newModel | reportsMesh = LoadingPage.createReportsMesh newReports newAdminReports }


removeLastCursorMove : FrontendLoaded -> FrontendLoaded
removeLastCursorMove newModel2 =
    let
        localModel =
            LocalModel.unwrap newModel2.localModel
    in
    case ( localModel.localMsgs, newModel2.pendingChanges ) of
        ( (Change.LocalChange eventIdA (Change.MoveCursor _)) :: rest, ( eventIdB, Change.MoveCursor _ ) :: restPending ) ->
            if eventIdA == eventIdB then
                { newModel2
                    | localModel = { localModel | localMsgs = rest } |> LocalModel.unsafe
                    , pendingChanges = restPending
                }

            else
                newModel2

        _ ->
            newModel2


updateLoaded : AudioData -> FrontendMsg_ -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
updateLoaded audioData msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Command.batch [ Effect.Browser.Navigation.pushUrl model.key (Url.toString url) ]
                    )

                Browser.External url ->
                    ( model
                    , Effect.Browser.Navigation.load url
                    )

        UrlChanged url ->
            ( if model.ignoreNextUrlChanged then
                { model | ignoreNextUrlChanged = False }

              else
                case Url.Parser.parse Route.urlParser url of
                    Just (Route.InternalRoute { viewPoint }) ->
                        { model | viewPoint = Coord.toPoint2d viewPoint |> NormalViewPoint }

                    _ ->
                        model
            , Command.none
            )

        NoOpFrontendMsg ->
            ( model, Command.none )

        TextureLoaded _ ->
            ( model, Command.none )

        LightsTextureLoaded _ ->
            ( model, Command.none )

        SimplexLookupTextureLoaded _ ->
            ( model, Command.none )

        KeyMsg keyMsg ->
            ( { model | pressedKeys = Keyboard.update keyMsg model.pressedKeys }, Command.none )

        KeyDown rawKey ->
            case Keyboard.anyKeyOriginal rawKey of
                Just key ->
                    case model.page of
                        MailPage mailEditor ->
                            case MailEditor.handleKeyDown model.time (LocalGrid.ctrlOrMeta model) key mailEditor of
                                Just ( newMailEditor, outMsg ) ->
                                    { model
                                        | page = MailPage newMailEditor
                                        , lastMailEditorToggle = model.lastMailEditorToggle
                                    }
                                        |> handleMailEditorOutMsg outMsg

                                Nothing ->
                                    ( { model
                                        | page = WorldPage LoadingPage.initWorldPage
                                        , lastMailEditorToggle = Just model.time
                                      }
                                    , Command.none
                                    )

                        _ ->
                            case ( model.focus, key ) of
                                ( _, Keyboard.Tab ) ->
                                    ( setFocus
                                        (if LocalGrid.keyDown Keyboard.Shift model then
                                            previousFocus model

                                         else
                                            nextFocus model
                                        )
                                        model
                                    , Command.none
                                    )

                                ( _, Keyboard.F1 ) ->
                                    ( { model | hideUi = not model.hideUi }, Command.none )

                                ( Just id, _ ) ->
                                    case model.currentTool of
                                        TextTool (Just _) ->
                                            keyMsgCanvasUpdate audioData rawKey key model

                                        _ ->
                                            uiUpdate audioData id (Ui.KeyDown rawKey key) model

                                _ ->
                                    keyMsgCanvasUpdate audioData rawKey key model

                Nothing ->
                    ( model, Command.none )

        WindowResized windowSize ->
            LoadingPage.windowResizedUpdate windowSize model

        GotDevicePixelRatio devicePixelRatio ->
            LoadingPage.devicePixelRatioChanged devicePixelRatio model

        MouseDown button mousePosition ->
            let
                hover =
                    hoverAt model mousePosition
            in
            if button == MainButton then
                { model
                    | mouseLeft =
                        MouseButtonDown
                            { start = mousePosition
                            , start_ = Toolbar.screenToWorld model mousePosition
                            , current = mousePosition
                            , hover = hover
                            }
                }
                    |> (\model2 ->
                            case hover of
                                MapHover ->
                                    case LocalGrid.currentTool model2 of
                                        TilePlacerTool { tileGroup, index } ->
                                            ( placeTile False tileGroup index model2, Command.none )

                                        HandTool ->
                                            ( model2, Command.none )

                                        TilePickerTool ->
                                            ( model2, Command.none )

                                        TextTool _ ->
                                            let
                                                position : Coord WorldUnit
                                                position =
                                                    LoadingPage.mouseWorldPosition model
                                                        |> Coord.floorPoint
                                            in
                                            ( { model2
                                                | currentTool =
                                                    { cursorPosition = position, startColumn = Tuple.first position }
                                                        |> Just
                                                        |> TextTool
                                              }
                                            , Command.none
                                            )

                                        ReportTool ->
                                            ( model2, Command.none )

                                UiHover id data ->
                                    uiUpdate
                                        audioData
                                        id
                                        (Ui.MouseDown { elementPosition = data.position })
                                        model2

                                _ ->
                                    ( model2, Command.none )
                       )

            else if button == MiddleButton then
                ( { model
                    | mouseMiddle =
                        MouseButtonDown
                            { start = mousePosition
                            , start_ = Toolbar.screenToWorld model mousePosition
                            , current = mousePosition
                            , hover = hover
                            }
                  }
                , Command.none
                )

            else
                ( model, Command.none )

        MouseUp button mousePosition ->
            case ( button, model.mouseLeft, model.mouseMiddle ) of
                ( MainButton, MouseButtonDown previousMouseState, _ ) ->
                    mainMouseButtonUp audioData mousePosition previousMouseState model

                ( MiddleButton, _, MouseButtonDown mouseState ) ->
                    ( { model
                        | mouseMiddle = MouseButtonUp { current = mousePosition }
                        , viewPoint =
                            case model.page of
                                MailPage _ ->
                                    model.viewPoint

                                WorldPage _ ->
                                    Toolbar.offsetViewPoint model mouseState.hover mouseState.start mousePosition |> NormalViewPoint

                                AdminPage _ ->
                                    model.viewPoint

                                InviteTreePage ->
                                    model.viewPoint
                      }
                    , Command.none
                    )

                ( SecondButton, _, _ ) ->
                    let
                        position =
                            Toolbar.screenToWorld model mousePosition |> Coord.floorPoint

                        maybeTile =
                            Grid.getTile position (LocalGrid.localModel model.localModel).grid
                    in
                    ( { model
                        | contextMenu =
                            Just
                                { userId = Maybe.map .userId maybeTile
                                , position = position
                                , linkCopied = False
                                }
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        MouseWheel event ->
            let
                scrollThreshold : Float
                scrollThreshold =
                    model.scrollThreshold
                        + (case event.deltaMode of
                            DeltaPixel ->
                                event.deltaY

                            DeltaLine ->
                                event.deltaY * 30

                            DeltaPage ->
                                event.deltaY * 1000
                          )

                worldZoom () =
                    if LocalGrid.ctrlOrMeta model then
                        { model
                            | zoomFactor =
                                (if scrollThreshold > 0 then
                                    model.zoomFactor - 1

                                 else
                                    model.zoomFactor + 1
                                )
                                    |> clamp 1 3
                            , scrollThreshold = 0
                        }

                    else
                        case ( scrollThreshold > 0, model.currentTool ) of
                            ( True, TilePlacerTool currentTile ) ->
                                tileRotationHelper audioData 1 currentTile model

                            ( False, TilePlacerTool currentTile ) ->
                                tileRotationHelper audioData -1 currentTile model

                            _ ->
                                { model | scrollThreshold = 0 }
            in
            ( if abs scrollThreshold > 50 then
                case model.page of
                    MailPage mailEditor ->
                        { model
                            | page =
                                MailEditor.scroll (scrollThreshold > 0) audioData model mailEditor |> MailPage
                        }

                    WorldPage _ ->
                        worldZoom ()

                    AdminPage _ ->
                        model

                    InviteTreePage ->
                        model

              else
                { model | scrollThreshold = scrollThreshold }
            , Command.none
            )

        MouseLeave ->
            case model.mouseLeft of
                MouseButtonDown mouseState ->
                    mainMouseButtonUp audioData (LoadingPage.mouseScreenPosition model) mouseState model

                MouseButtonUp _ ->
                    ( model, Command.none )

        MouseMove mousePosition ->
            let
                tileHover_ : Maybe TileGroup
                tileHover_ =
                    case hoverAt model mousePosition of
                        UiHover (ToolButtonHover (TilePlacerToolButton tile)) _ ->
                            Just tile

                        _ ->
                            Nothing

                placeTileHelper model2 =
                    case LocalGrid.currentTool model2 of
                        TilePlacerTool { tileGroup, index } ->
                            placeTile True tileGroup index model2

                        HandTool ->
                            model2

                        TilePickerTool ->
                            model2

                        TextTool _ ->
                            model2

                        ReportTool ->
                            model2
            in
            { model
                | mouseLeft =
                    case model.mouseLeft of
                        MouseButtonDown mouseState ->
                            MouseButtonDown { mouseState | current = mousePosition }

                        MouseButtonUp _ ->
                            MouseButtonUp { current = mousePosition }
                , mouseMiddle =
                    case model.mouseMiddle of
                        MouseButtonDown mouseState ->
                            MouseButtonDown { mouseState | current = mousePosition }

                        MouseButtonUp _ ->
                            MouseButtonUp { current = mousePosition }
                , previousTileHover = tileHover_
            }
                |> (\model2 ->
                        case model2.mouseLeft of
                            MouseButtonDown { hover } ->
                                case hover of
                                    UiBackgroundHover ->
                                        ( model2, Command.none )

                                    TileHover _ ->
                                        ( placeTileHelper model2, Command.none )

                                    TrainHover _ ->
                                        ( placeTileHelper model2, Command.none )

                                    MapHover ->
                                        ( placeTileHelper model2, Command.none )

                                    UiHover uiHover data ->
                                        uiUpdate audioData uiHover (Ui.MouseMove { elementPosition = data.position }) model2

                                    CowHover _ ->
                                        ( placeTileHelper model2, Command.none )

                            _ ->
                                ( model2, Command.none )
                   )

        ShortIntervalElapsed time ->
            let
                actualViewPoint_ =
                    Toolbar.actualViewPoint model

                model2 =
                    { model | time = time, viewPointLastInterval = actualViewPoint_ }

                ( model3, urlChange ) =
                    if actualViewPoint_ /= model.viewPointLastInterval then
                        actualViewPoint_
                            |> Coord.floorPoint
                            |> Route.internalRoute
                            |> Route.encode
                            |> (\a -> replaceUrl a model2)

                    else
                        ( model2, Command.none )

                viewBounds =
                    viewBoundingBox model

                playTrainWhistle =
                    (case model.lastTrainWhistle of
                        Just whistleTime ->
                            Duration.from whistleTime time |> Quantity.greaterThan (Duration.seconds 180)

                        Nothing ->
                            True
                    )
                        && List.any
                            (\( _, train ) -> BoundingBox2d.contains (Train.trainPosition model.time train) viewBounds)
                            (IdDict.toList model.trains)

                musicEnd : Effect.Time.Posix
                musicEnd =
                    Duration.addTo model3.music.startTime (Sound.length audioData model3.sounds model3.music.sound)

                model4 : FrontendLoaded
                model4 =
                    { model3
                        | lastTrainWhistle =
                            if playTrainWhistle then
                                Just time

                            else
                                model.lastTrainWhistle
                        , music =
                            if Duration.from musicEnd time |> Quantity.lessThanZero then
                                model3.music

                            else
                                { startTime = Duration.addTo time (Duration.minutes 3)
                                , sound =
                                    Random.step
                                        (Sound.nextSong (Just model3.music.sound))
                                        (Random.initialSeed (Time.posixToMillis time))
                                        |> Tuple.first
                                }
                    }
            in
            case List.Nonempty.fromList model4.pendingChanges of
                Just nonempty ->
                    ( { model4 | pendingChanges = [] }
                    , Command.batch
                        [ List.Nonempty.reverse nonempty |> GridChange |> Effect.Lamdera.sendToBackend
                        , urlChange
                        ]
                    )

                Nothing ->
                    ( model4, urlChange )

        ToggleAdminEnabledPressed ->
            ( if LocalGrid.currentUserId model == Env.adminUserId then
                { model | adminEnabled = not model.adminEnabled }

              else
                model
            , Command.none
            )

        AnimationFrame localTime ->
            let
                time =
                    Duration.addTo localTime (PingData.pingOffset model)

                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel

                oldViewPoint : Point2d WorldUnit WorldUnit
                oldViewPoint =
                    Toolbar.actualViewPoint model

                newViewPoint : Point2d WorldUnit WorldUnit
                newViewPoint =
                    Point2d.translateBy
                        (Keyboard.Arrows.arrows model.pressedKeys
                            |> (\{ x, y } -> Vector2d.unsafe { x = toFloat x, y = toFloat -y })
                        )
                        oldViewPoint

                movedViewWithArrowKeys : Bool
                movedViewWithArrowKeys =
                    canMoveWithArrowKeys && Keyboard.Arrows.arrows model.pressedKeys /= { x = 0, y = 0 }

                canMoveWithArrowKeys : Bool
                canMoveWithArrowKeys =
                    case model.currentTool of
                        TextTool (Just _) ->
                            False

                        _ ->
                            case model.focus of
                                Just uiHover ->
                                    case uiHover of
                                        EmailAddressTextInputHover ->
                                            False

                                        PrimaryColorInput ->
                                            False

                                        SecondaryColorInput ->
                                            False

                                        InviteEmailAddressTextInput ->
                                            False

                                        DisplayNameTextInput ->
                                            False

                                        MailEditorHover _ ->
                                            False

                                        _ ->
                                            True

                                Nothing ->
                                    True

                model2 =
                    { model
                        | time = time
                        , localTime = localTime
                        , animationElapsedTime = Duration.from model.time time |> Quantity.plus model.animationElapsedTime
                        , trains =
                            case localGrid.trainsDisabled of
                                TrainsDisabled ->
                                    model.trains

                                TrainsEnabled ->
                                    Train.moveTrains
                                        time
                                        (Duration.from model.time time |> Quantity.min Duration.minute |> Duration.subtractFrom time)
                                        model.trains
                                        { grid = localGrid.grid, mail = IdDict.empty }
                        , removedTileParticles =
                            List.filter
                                (\item -> Duration.from item.time model.time |> Quantity.lessThan (Duration.seconds 1))
                                model.removedTileParticles
                        , viewPoint =
                            if movedViewWithArrowKeys then
                                NormalViewPoint newViewPoint

                            else
                                model.viewPoint
                        , scrollThreshold =
                            if abs model.scrollThreshold < 1 then
                                0

                            else if model.scrollThreshold >= 1 then
                                model.scrollThreshold - 1

                            else
                                model.scrollThreshold + 1
                    }

                model3 =
                    case ( ( movedViewWithArrowKeys, model.viewPoint ), model2.mouseLeft, model2.currentTool ) of
                        ( ( True, _ ), MouseButtonDown _, TilePlacerTool currentTile ) ->
                            placeTile True currentTile.tileGroup currentTile.index model2

                        ( ( _, TrainViewPoint _ ), MouseButtonDown _, TilePlacerTool currentTile ) ->
                            placeTile True currentTile.tileGroup currentTile.index model2

                        _ ->
                            model2

                model4 =
                    LoadingPage.updateMeshes model3

                newUi =
                    Toolbar.view model4

                visuallyEqual =
                    Ui.visuallyEqual newUi model4.ui
            in
            ( { model4
                | ui = newUi
                , previousFocus = model4.focus
                , focus =
                    if visuallyEqual then
                        model4.focus

                    else
                        case Maybe.andThen (\id -> Ui.findInput id newUi) model4.focus of
                            Just _ ->
                                model4.focus

                            Nothing ->
                                Nothing
                , uiMesh =
                    if visuallyEqual && model4.focus == model4.previousFocus then
                        model4.uiMesh

                    else
                        Ui.view model4.focus newUi
              }
            , Command.none
            )

        SoundLoaded sound result ->
            ( { model | sounds = AssocList.insert sound result model.sounds }, Command.none )

        VisibilityChanged ->
            ( LoadingPage.setCurrentTool HandToolButton { model | pressedKeys = [] }, Command.none )

        TrainTextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | trainTexture = Just texture }, Command.none )

                Err _ ->
                    ( model, Command.none )

        TrainLightsTextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | trainLightsTexture = Just texture }, Command.none )

                Err _ ->
                    ( model, Command.none )

        PastedText text ->
            case model.focus of
                Just id ->
                    uiUpdate audioData id (Ui.PastedText text) model

                Nothing ->
                    pasteTextTool text model

        GotUserAgentPlatform _ ->
            ( model, Command.none )

        LoadedUserSettings userSettings ->
            ( { model | musicVolume = userSettings.musicVolume, soundEffectVolume = userSettings.soundEffectVolume }
            , Command.none
            )

        GotWebGlFix ->
            ( model, Command.none )

        ImportedMail file ->
            ( model
            , Effect.File.toString file
                |> Effect.Task.andThen
                    (\text ->
                        case Codec.decodeString (Codec.list MailEditor.contentCodec) text of
                            Ok ok ->
                                Effect.Task.succeed ok

                            Err _ ->
                                Effect.Task.fail ()
                    )
                |> Effect.Task.attempt ImportedMail2
            )

        ImportedMail2 result ->
            ( { model
                | page =
                    case model.page of
                        MailPage mailEditor ->
                            MailEditor.importMail result mailEditor |> MailPage

                        _ ->
                            model.page
              }
            , Command.none
            )

        TrainDepthTextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | trainDepthTexture = Just texture }, Command.none )

                Err _ ->
                    ( model, Command.none )

        DepthTextureLoaded _ ->
            ( model, Command.none )


pasteTextTool : String -> FrontendLoaded -> ( FrontendLoaded, Command restriction toMsg msg )
pasteTextTool text model =
    ( case model.currentTool of
        TextTool (Just _) ->
            String.foldl placeChar model (String.left 200 text)

        _ ->
            model
    , Command.none
    )


tileRotationHelper : AudioData -> Int -> { a | tileGroup : TileGroup, index : Int } -> FrontendLoaded -> FrontendLoaded
tileRotationHelper audioData offset tile model =
    if Tile.getTileGroupData tile.tileGroup |> .tiles |> List.Nonempty.length |> (==) 1 then
        model

    else
        { model
            | currentTool =
                { tileGroup = tile.tileGroup
                , index = tile.index + offset
                , mesh =
                    Grid.tileMesh
                        (Toolbar.getTileGroupTile tile.tileGroup (tile.index + offset))
                        Coord.origin
                        1
                        (LoadingPage.getTileColor tile.tileGroup model)
                        |> Sprite.toMesh
                }
                    |> TilePlacerTool
            , lastTileRotation =
                model.time
                    :: List.filter
                        (\time ->
                            Duration.from time model.time
                                |> Quantity.lessThan (Sound.length audioData model.sounds WhooshSound)
                        )
                        model.lastTileRotation
            , scrollThreshold = 0
        }


previousFocus : FrontendLoaded -> Maybe UiHover
previousFocus model =
    case model.focus of
        Just hoverId ->
            Just (Ui.tabBackward hoverId model.ui)

        _ ->
            Nothing


nextFocus : FrontendLoaded -> Maybe UiHover
nextFocus model =
    case model.focus of
        Just hoverId ->
            Just (Ui.tabForward hoverId model.ui)

        _ ->
            Nothing


colorTextInputAdjustText : TextInput.Model -> TextInput.Model
colorTextInputAdjustText model =
    TextInput.replaceState
        (\a ->
            { text = String.left 6 a.text
            , cursorPosition = min 6 a.cursorPosition
            , cursorSize = a.cursorSize
            }
        )
        model


handleKeyDownColorInput :
    Id UserId
    -> (TextInput.Model -> FrontendLoaded -> FrontendLoaded)
    -> (Color -> Colors -> Colors)
    -> Tool
    -> Keyboard.Key
    -> FrontendLoaded
    -> TextInput.Model
    -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
handleKeyDownColorInput userId setTextInputModel updateColor tileGroup key model textInput =
    let
        ( newTextInput, cmd ) =
            TextInput.keyMsg
                (LocalGrid.ctrlOrMeta model)
                (LocalGrid.keyDown Keyboard.Shift model)
                key
                textInput
                |> (\( textInput2, maybeCopied ) ->
                        ( colorTextInputAdjustText textInput2
                        , case maybeCopied of
                            CopyText text ->
                                Ports.copyToClipboard text

                            PasteText ->
                                Ports.readFromClipboardRequest

                            NoOutMsg ->
                                Command.none
                        )
                   )

        ( model2, cmd2 ) =
            handleKeyDownColorInputHelper userId setTextInputModel updateColor tileGroup model newTextInput
    in
    ( model2, Command.batch [ cmd, cmd2 ] )


handleKeyDownColorInputHelper :
    Id UserId
    -> (TextInput.Model -> FrontendLoaded -> FrontendLoaded)
    -> (Color -> Colors -> Colors)
    -> Tool
    -> FrontendLoaded
    -> TextInput.Model
    -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
handleKeyDownColorInputHelper userId setTextInputModel updateColor tool model newTextInput =
    let
        maybeNewColor : Maybe Color
        maybeNewColor =
            Color.fromHexCode newTextInput.current.text
    in
    (case tool of
        TilePlacerTool { tileGroup } ->
            ( { model
                | tileColors =
                    case maybeNewColor of
                        Just color ->
                            AssocList.update
                                tileGroup
                                (\maybeColor ->
                                    (case maybeColor of
                                        Just colors ->
                                            updateColor color colors

                                        Nothing ->
                                            Tile.getTileGroupData tileGroup
                                                |> .defaultColors
                                                |> Tile.defaultToPrimaryAndSecondary
                                                |> updateColor color
                                    )
                                        |> Just
                                )
                                model.tileColors

                        Nothing ->
                            model.tileColors
              }
            , Command.none
            )

        HandTool ->
            case maybeNewColor of
                Just color ->
                    updateLocalModel
                        (updateColor color (LoadingPage.getHandColor userId model) |> Change.ChangeHandColor)
                        model
                        |> handleOutMsg False

                Nothing ->
                    ( model, Command.none )

        TilePickerTool ->
            ( model, Command.none )

        TextTool _ ->
            ( { model
                | tileColors =
                    case maybeNewColor of
                        Just color ->
                            AssocList.update
                                BigTextGroup
                                (\maybeColor ->
                                    (case maybeColor of
                                        Just colors ->
                                            updateColor color colors

                                        Nothing ->
                                            Tile.getTileGroupData BigTextGroup
                                                |> .defaultColors
                                                |> Tile.defaultToPrimaryAndSecondary
                                                |> updateColor color
                                    )
                                        |> Just
                                )
                                model.tileColors

                        Nothing ->
                            model.tileColors
              }
            , Command.none
            )

        ReportTool ->
            ( model, Command.none )
    )
        |> Tuple.mapFirst (setTextInputModel newTextInput)
        |> Tuple.mapFirst
            (\m ->
                case maybeNewColor of
                    Just _ ->
                        { m
                            | currentTool =
                                case m.currentTool of
                                    TilePlacerTool currentTile ->
                                        { tileGroup = currentTile.tileGroup
                                        , index = currentTile.index
                                        , mesh =
                                            Grid.tileMesh
                                                (Toolbar.getTileGroupTile currentTile.tileGroup currentTile.index)
                                                Coord.origin
                                                1
                                                (LoadingPage.getTileColor currentTile.tileGroup m)
                                                |> Sprite.toMesh
                                        }
                                            |> TilePlacerTool

                                    HandTool ->
                                        m.currentTool

                                    TilePickerTool ->
                                        m.currentTool

                                    TextTool _ ->
                                        m.currentTool

                                    ReportTool ->
                                        m.currentTool
                        }

                    Nothing ->
                        m
            )


hoverAt : FrontendLoaded -> Point2d Pixels Pixels -> Hover
hoverAt model mousePosition =
    let
        mousePosition2 : Coord Pixels
        mousePosition2 =
            mousePosition
                |> Coord.roundPoint
    in
    case Ui.hover mousePosition2 model.ui of
        Ui.InputHover data ->
            UiHover data.id { position = data.position }

        Ui.BackgroundHover ->
            UiBackgroundHover

        Ui.NoHover ->
            let
                mouseWorldPosition_ : Point2d WorldUnit WorldUnit
                mouseWorldPosition_ =
                    Toolbar.screenToWorld model mousePosition

                tileHover : Maybe Hover
                tileHover =
                    let
                        localModel : LocalGrid_
                        localModel =
                            LocalGrid.localModel model.localModel
                    in
                    case Grid.getTile (Coord.floorPoint mouseWorldPosition_) localModel.grid of
                        Just tile ->
                            case model.currentTool of
                                HandTool ->
                                    TileHover tile |> Just

                                TilePickerTool ->
                                    TileHover tile |> Just

                                TilePlacerTool _ ->
                                    if LocalGrid.ctrlOrMeta model then
                                        TileHover tile |> Just

                                    else
                                        Nothing

                                TextTool _ ->
                                    if LocalGrid.ctrlOrMeta model then
                                        TileHover tile |> Just

                                    else
                                        Nothing

                                ReportTool ->
                                    TileHover tile |> Just

                        Nothing ->
                            Nothing

                trainHovers : Maybe ( { trainId : Id TrainId, train : Train }, Quantity Float WorldUnit )
                trainHovers =
                    case model.currentTool of
                        TilePlacerTool _ ->
                            Nothing

                        TilePickerTool ->
                            Nothing

                        HandTool ->
                            IdDict.toList model.trains
                                |> List.filterMap
                                    (\( trainId, train ) ->
                                        let
                                            distance =
                                                Train.trainPosition model.time train |> Point2d.distanceFrom mouseWorldPosition_
                                        in
                                        if distance |> Quantity.lessThan (Quantity 0.9) then
                                            Just ( { trainId = trainId, train = train }, distance )

                                        else
                                            Nothing
                                    )
                                |> Quantity.minimumBy Tuple.second

                        TextTool _ ->
                            Nothing

                        ReportTool ->
                            Nothing

                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel

                animalHovers : Maybe ( Id AnimalId, Animal )
                animalHovers =
                    case model.currentTool of
                        TilePlacerTool _ ->
                            Nothing

                        TilePickerTool ->
                            Nothing

                        HandTool ->
                            IdDict.toList localGrid.animals
                                |> List.filter
                                    (\( animalId, animal ) ->
                                        case animalActualPosition animalId model of
                                            Just a ->
                                                if a.isHeld then
                                                    False

                                                else
                                                    Animal.inside mouseWorldPosition_ { animal | position = a.position }

                                            Nothing ->
                                                False
                                    )
                                |> Quantity.maximumBy (\( _, cow ) -> Point2d.yCoordinate cow.position)

                        TextTool _ ->
                            Nothing

                        ReportTool ->
                            Nothing
            in
            case trainHovers of
                Just ( train, _ ) ->
                    TrainHover train

                Nothing ->
                    case animalHovers of
                        Just ( cowId, cow ) ->
                            CowHover { cowId = cowId, cow = cow }

                        Nothing ->
                            case tileHover of
                                Just hover ->
                                    hover

                                Nothing ->
                                    MapHover


replaceUrl : String -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
replaceUrl url model =
    ( { model | ignoreNextUrlChanged = True }, Effect.Browser.Navigation.replaceUrl model.key url )


keyMsgCanvasUpdate : AudioData -> Keyboard.RawKey -> Keyboard.Key -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
keyMsgCanvasUpdate audioData rawKey key model =
    case ( key, LocalGrid.ctrlOrMeta model ) of
        ( Keyboard.Character "z", True ) ->
            case model.currentTool of
                ReportTool ->
                    ( model, Command.none )

                _ ->
                    updateLocalModel Change.LocalUndo model |> handleOutMsg False

        ( Keyboard.Character "Z", True ) ->
            case model.currentTool of
                ReportTool ->
                    ( model, Command.none )

                _ ->
                    updateLocalModel Change.LocalRedo model |> handleOutMsg False

        ( Keyboard.Character "y", True ) ->
            case model.currentTool of
                ReportTool ->
                    ( model, Command.none )

                _ ->
                    updateLocalModel Change.LocalRedo model |> handleOutMsg False

        ( Keyboard.Escape, _ ) ->
            if model.contextMenu /= Nothing then
                ( { model | contextMenu = Nothing }, Command.none )

            else
                case model.page of
                    WorldPage worldPage ->
                        if worldPage.showMap then
                            ( { model | page = WorldPage { worldPage | showMap = False } }, Command.none )

                        else
                            ( case model.currentTool of
                                TilePlacerTool _ ->
                                    LoadingPage.setCurrentTool HandToolButton model

                                TilePickerTool ->
                                    LoadingPage.setCurrentTool HandToolButton model

                                HandTool ->
                                    case isHoldingCow model of
                                        Just { cowId } ->
                                            updateLocalModel (Change.DropCow cowId (LoadingPage.mouseWorldPosition model) model.time) model
                                                |> Tuple.first

                                        Nothing ->
                                            { model
                                                | viewPoint =
                                                    case model.viewPoint of
                                                        TrainViewPoint _ ->
                                                            Toolbar.actualViewPoint model |> NormalViewPoint

                                                        NormalViewPoint _ ->
                                                            model.viewPoint
                                            }

                                TextTool (Just _) ->
                                    LoadingPage.setCurrentTool TextToolButton model

                                TextTool Nothing ->
                                    LoadingPage.setCurrentTool HandToolButton model

                                ReportTool ->
                                    LoadingPage.setCurrentTool HandToolButton model
                            , Command.none
                            )

                    _ ->
                        ( model, Command.none )

        ( Keyboard.Character "v", True ) ->
            case model.currentTool of
                TextTool (Just _) ->
                    ( model, Ports.readFromClipboardRequest )

                _ ->
                    ( model, Command.none )

        ( Keyboard.Spacebar, False ) ->
            case model.currentTool of
                TextTool (Just _) ->
                    ( placeChar ' ' model, Command.none )

                _ ->
                    setTileFromHotkey rawKey " " model

        ( Keyboard.Backspace, False ) ->
            ( case model.currentTool of
                TextTool (Just textTool) ->
                    placeChar
                        ' '
                        { model
                            | currentTool =
                                { textTool | cursorPosition = Coord.plus (Coord.xy -1 0) textTool.cursorPosition }
                                    |> Just
                                    |> TextTool
                        }
                        |> (\m ->
                                { m
                                    | currentTool =
                                        { textTool | cursorPosition = Coord.plus (Coord.xy -1 0) textTool.cursorPosition }
                                            |> Just
                                            |> TextTool
                                }
                           )

                _ ->
                    model
            , Command.none
            )

        ( Keyboard.ArrowLeft, False ) ->
            ( shiftTextCursor (Coord.xy -1 0) model
            , Command.none
            )

        ( Keyboard.ArrowRight, False ) ->
            ( shiftTextCursor (Coord.xy 1 0) model
            , Command.none
            )

        ( Keyboard.ArrowUp, False ) ->
            ( shiftTextCursor (Coord.xy 0 -1) model
            , Command.none
            )

        ( Keyboard.ArrowDown, False ) ->
            ( shiftTextCursor (Coord.xy 0 1) model
            , Command.none
            )

        ( Keyboard.Character string, False ) ->
            case model.currentTool of
                TextTool (Just _) ->
                    ( String.foldl placeChar model string
                    , Command.none
                    )

                TilePlacerTool currentTile ->
                    case string of
                        "q" ->
                            ( tileRotationHelper audioData -1 currentTile model, Command.none )

                        "w" ->
                            ( tileRotationHelper audioData 1 currentTile model, Command.none )

                        "m" ->
                            ( { model
                                | page =
                                    case model.page of
                                        WorldPage worldPage ->
                                            WorldPage { worldPage | showMap = not worldPage.showMap }

                                        _ ->
                                            model.page
                              }
                            , Command.none
                            )

                        _ ->
                            if List.member Keyboard.Shift model.pressedKeys then
                                setHokeyForTile rawKey model

                            else
                                setTileFromHotkey rawKey string model

                _ ->
                    case string of
                        "m" ->
                            ( { model
                                | page =
                                    case model.page of
                                        WorldPage worldPage ->
                                            WorldPage { worldPage | showMap = not worldPage.showMap }

                                        _ ->
                                            model.page
                              }
                            , Command.none
                            )

                        _ ->
                            if List.member Keyboard.Shift model.pressedKeys then
                                setHokeyForTile rawKey model

                            else
                                setTileFromHotkey rawKey string model

        ( Keyboard.Enter, False ) ->
            ( case model.currentTool of
                TextTool (Just _) ->
                    placeChar '\n' model

                _ ->
                    model
            , Command.none
            )

        _ ->
            ( model, Command.none )


shiftTextCursor : Coord WorldUnit -> FrontendLoaded -> FrontendLoaded
shiftTextCursor offset model =
    case model.currentTool of
        TextTool (Just textTool) ->
            case BoundingBox2d.offsetBy (Units.tileUnit -8) (viewBoundingBox model) of
                Just viewBounds ->
                    let
                        newCursorPosition =
                            Coord.plus offset textTool.cursorPosition
                    in
                    { model
                        | currentTool =
                            { textTool | cursorPosition = newCursorPosition }
                                |> Just
                                |> TextTool
                        , viewPoint =
                            if BoundingBox2d.contains (Coord.toPoint2d newCursorPosition) viewBounds then
                                model.viewPoint

                            else
                                Toolbar.actualViewPoint model
                                    |> Point2d.translateBy (Coord.toVector2d offset)
                                    |> NormalViewPoint
                    }

                Nothing ->
                    { model
                        | viewPoint =
                            Toolbar.actualViewPoint model
                                |> Point2d.translateBy (Coord.toVector2d offset)
                                |> NormalViewPoint
                    }

        _ ->
            model


placeChar : Char -> FrontendLoaded -> FrontendLoaded
placeChar char model =
    case model.currentTool of
        TextTool (Just textTool) ->
            case char of
                '\n' ->
                    { model
                        | currentTool =
                            { textTool
                                | cursorPosition =
                                    ( textTool.startColumn
                                    , Tuple.second textTool.cursorPosition |> Quantity.plus (Units.tileUnit 2)
                                    )
                            }
                                |> Just
                                |> TextTool
                    }

                _ ->
                    case Dict.get char Sprite.charToInt of
                        Just charInt ->
                            placeTileAt
                                textTool.cursorPosition
                                False
                                BigTextGroup
                                charInt
                                { model
                                    | currentTool =
                                        { textTool
                                            | cursorPosition =
                                                Coord.plus (Coord.xy 1 0) textTool.cursorPosition
                                        }
                                            |> Just
                                            |> TextTool
                                }

                        _ ->
                            model

        _ ->
            model


categoryHotkeys : Dict String Category
categoryHotkeys =
    Dict.fromList
        [ ( "s", Scenery )
        , ( "b", Buildings )
        , ( "t", Rail )
        , ( "r", Road )
        ]


setHokeyForTile : Keyboard.RawKey -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly toMsg FrontendMsg_ )
setHokeyForTile hotkeyText model =
    case ( Dict.get (Keyboard.rawValue hotkeyText |> .keyCode) Change.tileHotkeyDict, model.currentTool ) of
        ( Just hotkey, TilePlacerTool { tileGroup } ) ->
            if tileGroup == EmptyTileGroup then
                ( model, Command.none )

            else
                updateLocalModel
                    (Change.SetTileHotkey hotkey tileGroup)
                    { model | lastHotkeyChange = Just model.time }
                    |> handleOutMsg False

        _ ->
            ( model, Command.none )


setTileFromHotkey : Keyboard.RawKey -> String -> FrontendLoaded -> ( FrontendLoaded, Command restriction toMsg msg )
setTileFromHotkey rawKey string model =
    ( case Dict.get string categoryHotkeys of
        Just category ->
            { model | selectedTileCategory = category }

        Nothing ->
            let
                localModel =
                    LocalGrid.localModel model.localModel
            in
            if string == " " then
                LoadingPage.setCurrentTool (TilePlacerToolButton EmptyTileGroup) model

            else
                case ( Dict.get (Keyboard.rawValue rawKey |> .keyCode) Change.tileHotkeyDict, localModel.userStatus ) of
                    ( Just tileHotkey, LoggedIn loggedIn ) ->
                        case AssocList.get tileHotkey loggedIn.tileHotkeys of
                            Just tile ->
                                LoadingPage.setCurrentTool (TilePlacerToolButton tile) model

                            Nothing ->
                                model

                    _ ->
                        model
    , Command.none
    )


isHoldingCow : FrontendLoaded -> Maybe { cowId : Id AnimalId, pickupTime : Effect.Time.Posix }
isHoldingCow model =
    let
        localGrid =
            LocalGrid.localModel model.localModel
    in
    case LocalGrid.currentUserId model of
        Just userId ->
            case IdDict.get userId localGrid.cursors of
                Just cursor ->
                    cursor.holdingCow

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


isSmallDistance : { a | start : Point2d Pixels coordinates } -> Point2d Pixels coordinates -> Bool
isSmallDistance previousMouseState mousePosition =
    Vector2d.from previousMouseState.start mousePosition
        |> Vector2d.length
        |> Quantity.lessThan (Pixels.pixels 5)


tileInteraction :
    Id UserId
    -> { tile : Tile, userId : Id UserId, position : Coord WorldUnit, colors : Colors }
    -> FrontendLoaded
    -> Maybe (() -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ ))
tileInteraction currentUserId2 { tile, userId, position } model =
    let
        handleTrainHouse : Maybe (() -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ ))
        handleTrainHouse =
            case
                IdDict.toList model.trains
                    |> List.find (\( _, train ) -> Train.home train == position)
            of
                Just ( trainId, train ) ->
                    case Train.status model.time train of
                        WaitingAtHome ->
                            Just (\() -> clickLeaveHomeTrain trainId model)

                        _ ->
                            Just (\() -> clickTeleportHomeTrain trainId model)

                Nothing ->
                    Nothing

        handleRailSplit =
            Just (\() -> updateLocalModel (Change.ToggleRailSplit position) model |> handleOutMsg False)
    in
    case tile of
        PostOffice ->
            case canOpenMailEditor model of
                Just drafts ->
                    (\() ->
                        if currentUserId2 == userId then
                            ( { model
                                | page =
                                    case model.page of
                                        WorldPage _ ->
                                            MailEditor.init Nothing |> MailPage

                                        _ ->
                                            model.page
                                , lastMailEditorToggle = Just model.time
                              }
                            , Command.none
                            )

                        else
                            let
                                localModel =
                                    LocalGrid.localModel model.localModel
                            in
                            case localModel.users |> IdDict.get userId of
                                Just user ->
                                    ( { model
                                        | page =
                                            case model.page of
                                                WorldPage _ ->
                                                    MailEditor.init
                                                        (Just
                                                            { userId = userId
                                                            , name = user.name
                                                            , draft = IdDict.get userId drafts |> Maybe.withDefault []
                                                            }
                                                        )
                                                        |> MailPage

                                                _ ->
                                                    model.page
                                        , lastMailEditorToggle = Just model.time
                                      }
                                    , Command.none
                                    )

                                Nothing ->
                                    ( model, Command.none )
                    )
                        |> Just

                Nothing ->
                    Nothing

        HouseDown ->
            (\() -> ( { model | lastHouseClick = Just model.time }, Command.none )) |> Just

        HouseLeft ->
            (\() -> ( { model | lastHouseClick = Just model.time }, Command.none )) |> Just

        HouseUp ->
            (\() -> ( { model | lastHouseClick = Just model.time }, Command.none )) |> Just

        HouseRight ->
            (\() -> ( { model | lastHouseClick = Just model.time }, Command.none )) |> Just

        TrainHouseLeft ->
            handleTrainHouse

        TrainHouseRight ->
            handleTrainHouse

        RailBottomToRight_SplitLeft ->
            handleRailSplit

        RailBottomToLeft_SplitUp ->
            handleRailSplit

        RailTopToRight_SplitDown ->
            handleRailSplit

        RailTopToLeft_SplitRight ->
            handleRailSplit

        RailBottomToRight_SplitUp ->
            handleRailSplit

        RailBottomToLeft_SplitRight ->
            handleRailSplit

        RailTopToRight_SplitLeft ->
            handleRailSplit

        RailTopToLeft_SplitDown ->
            handleRailSplit

        RailStrafeLeftToRight_SplitUp ->
            handleRailSplit

        RailStrafeLeftToRight_SplitDown ->
            handleRailSplit

        RailStrafeRightToLeft_SplitUp ->
            handleRailSplit

        RailStrafeRightToLeft_SplitDown ->
            handleRailSplit

        RailStrafeTopToBottom_SplitLeft ->
            handleRailSplit

        RailStrafeTopToBottom_SplitRight ->
            handleRailSplit

        RailStrafeBottomToTop_SplitLeft ->
            handleRailSplit

        RailStrafeBottomToTop_SplitRight ->
            handleRailSplit

        _ ->
            Nothing


mainMouseButtonUp :
    AudioData
    -> Point2d Pixels Pixels
    -> { a | start : Point2d Pixels Pixels, hover : Hover }
    -> FrontendLoaded
    -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
mainMouseButtonUp audioData mousePosition previousMouseState model =
    let
        isSmallDistance2 =
            isSmallDistance previousMouseState mousePosition

        hoverAt2 : Hover
        hoverAt2 =
            hoverAt model mousePosition

        sameUiHover : Maybe UiHover
        sameUiHover =
            case ( hoverAt2, previousMouseState.hover ) of
                ( UiHover new _, UiHover old _ ) ->
                    if new == old then
                        Just new

                    else
                        Nothing

                _ ->
                    Nothing

        model2 =
            { model
                | mouseLeft = MouseButtonUp { current = mousePosition }
                , contextMenu =
                    case hoverAt2 of
                        UiHover _ _ ->
                            model.contextMenu

                        UiBackgroundHover ->
                            model.contextMenu

                        _ ->
                            if isSmallDistance2 then
                                Nothing

                            else
                                model.contextMenu
                , viewPoint =
                    case model.page of
                        WorldPage _ ->
                            case model.mouseMiddle of
                                MouseButtonUp _ ->
                                    case model.currentTool of
                                        TilePlacerTool _ ->
                                            model.viewPoint

                                        HandTool ->
                                            Toolbar.offsetViewPoint
                                                model
                                                previousMouseState.hover
                                                previousMouseState.start
                                                mousePosition
                                                |> NormalViewPoint

                                        TilePickerTool ->
                                            Toolbar.offsetViewPoint
                                                model
                                                previousMouseState.hover
                                                previousMouseState.start
                                                mousePosition
                                                |> NormalViewPoint

                                        TextTool _ ->
                                            model.viewPoint

                                        ReportTool ->
                                            Toolbar.offsetViewPoint
                                                model
                                                previousMouseState.hover
                                                previousMouseState.start
                                                mousePosition
                                                |> NormalViewPoint

                                MouseButtonDown _ ->
                                    model.viewPoint

                        MailPage _ ->
                            model.viewPoint

                        AdminPage _ ->
                            model.viewPoint

                        InviteTreePage ->
                            model.viewPoint
            }
                |> (\m ->
                        case sameUiHover of
                            Just uiHover ->
                                setFocus (Just uiHover) m

                            Nothing ->
                                m
                   )
    in
    case isHoldingCow model2 of
        Just { cowId } ->
            if isSmallDistance2 then
                let
                    ( model3, _ ) =
                        updateLocalModel (Change.DropCow cowId (LoadingPage.mouseWorldPosition model2) model2.time) model2
                in
                ( model3, Command.none )

            else
                ( model2, Command.none )

        Nothing ->
            case hoverAt2 of
                UiBackgroundHover ->
                    ( model2, Command.none )

                TileHover data ->
                    if isSmallDistance2 then
                        case LocalGrid.currentUserId model2 of
                            Just userId ->
                                case LocalGrid.currentTool model2 of
                                    HandTool ->
                                        case tileInteraction userId data model2 of
                                            Just func ->
                                                func ()

                                            Nothing ->
                                                ( model2, Command.none )

                                    TilePickerTool ->
                                        ( case hoverAt2 of
                                            TileHover { tile, colors } ->
                                                case Tile.tileToTileGroup tile of
                                                    Just { tileGroup, index } ->
                                                        LoadingPage.setCurrentToolWithColors
                                                            (TilePlacerTool
                                                                { tileGroup = tileGroup
                                                                , index = index
                                                                , mesh =
                                                                    Grid.tileMesh
                                                                        (Toolbar.getTileGroupTile tileGroup index)
                                                                        Coord.origin
                                                                        1
                                                                        colors
                                                                        |> Sprite.toMesh
                                                                }
                                                            )
                                                            colors
                                                            model2

                                                    Nothing ->
                                                        model2

                                            _ ->
                                                model2
                                        , Command.none
                                        )

                                    TilePlacerTool _ ->
                                        ( model2, Command.none )

                                    TextTool _ ->
                                        ( model2, Command.none )

                                    ReportTool ->
                                        let
                                            position =
                                                LoadingPage.mouseWorldPosition model2 |> Coord.floorPoint
                                        in
                                        (if List.any (\report -> report.position == position) (LoadingPage.getReports model2.localModel) then
                                            updateLocalModel
                                                (Change.RemoveReport position)
                                                { model2 | lastReportTileRemoved = Just model2.time }

                                         else
                                            updateLocalModel
                                                (Change.ReportVandalism
                                                    { position = position
                                                    , reportedUser = data.userId
                                                    }
                                                )
                                                { model2 | lastReportTilePlaced = Just model2.time }
                                        )
                                            |> handleOutMsg False

                            Nothing ->
                                ( model2, Command.none )

                    else
                        ( model2, Command.none )

                TrainHover { trainId, train } ->
                    if isSmallDistance2 then
                        case Train.status model.time train of
                            WaitingAtHome ->
                                clickLeaveHomeTrain trainId model2

                            TeleportingHome _ ->
                                ( model2, Command.none )

                            _ ->
                                case Train.stuckOrDerailed model2.time train of
                                    Train.IsStuck stuckTime ->
                                        if
                                            Duration.from stuckTime model2.time
                                                |> Quantity.lessThan Train.stuckMessageDelay
                                        then
                                            ( setTrainViewPoint trainId model2, Command.none )

                                        else
                                            clickTeleportHomeTrain trainId model2

                                    Train.IsDerailed _ _ ->
                                        clickTeleportHomeTrain trainId model2

                                    Train.IsNotStuckOrDerailed ->
                                        ( setTrainViewPoint trainId model2, Command.none )

                    else
                        ( model2, Command.none )

                MapHover ->
                    if isSmallDistance2 then
                        case LocalGrid.currentTool model2 of
                            ReportTool ->
                                let
                                    position =
                                        LoadingPage.mouseWorldPosition model2 |> Coord.floorPoint
                                in
                                if List.any (\report -> report.position == position) (LoadingPage.getReports model2.localModel) then
                                    updateLocalModel
                                        (Change.RemoveReport position)
                                        { model2 | lastReportTileRemoved = Just model2.time }
                                        |> handleOutMsg False

                                else
                                    ( model2, Command.none )

                            _ ->
                                ( case previousMouseState.hover of
                                    TrainHover { trainId } ->
                                        setTrainViewPoint trainId model2

                                    _ ->
                                        model2
                                , Command.none
                                )

                    else
                        ( model2, Command.none )

                CowHover { cowId } ->
                    if isSmallDistance2 then
                        let
                            ( model3, _ ) =
                                updateLocalModel (Change.PickupCow cowId (LoadingPage.mouseWorldPosition model2) model2.time) model2
                        in
                        ( model3, Command.none )

                    else
                        ( model2, Command.none )

                UiHover id data ->
                    case sameUiHover of
                        Just _ ->
                            uiUpdate
                                audioData
                                id
                                (Ui.MousePressed { elementPosition = data.position })
                                model2

                        Nothing ->
                            ( model2, Command.none )


handleMailEditorOutMsg :
    MailEditor.OutMsg
    -> FrontendLoaded
    -> ( FrontendLoaded, Command FrontendOnly toMsg FrontendMsg_ )
handleMailEditorOutMsg outMsg model =
    (case outMsg of
        MailEditor.NoOutMsg ->
            ( model, LocalGrid.NoOutMsg )

        MailEditor.SubmitMail submitMail ->
            updateLocalModel (Change.SubmitMail submitMail) model

        MailEditor.UpdateDraft updateDraft ->
            updateLocalModel (Change.UpdateDraft updateDraft) model

        MailEditor.ViewedMail mailId ->
            updateLocalModel (Change.ViewedMail mailId) model

        MailEditor.ExportMail content ->
            ( model, LocalGrid.ExportMail content )

        MailEditor.ImportMail ->
            ( model, LocalGrid.ImportMail )
    )
        |> handleOutMsg False


sendInvite : FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend msg )
sendInvite model =
    case ( LocalGrid.localModel model.localModel |> .userStatus, model.inviteSubmitStatus ) of
        ( LoggedIn loggedIn, NotSubmitted _ ) ->
            case Toolbar.validateInviteEmailAddress loggedIn.emailAddress model.inviteTextInput.current.text of
                Ok emailAddress ->
                    ( { model | inviteSubmitStatus = Submitting }
                    , Effect.Lamdera.sendToBackend (SendInviteEmailRequest (Untrusted.untrust emailAddress))
                    )

                Err _ ->
                    ( { model | inviteSubmitStatus = NotSubmitted { pressedSubmit = True } }, Command.none )

        _ ->
            ( model, Command.none )


onPress audioData event updateFunc model =
    case event of
        Ui.MousePressed _ ->
            updateFunc ()

        Ui.KeyDown _ Keyboard.Enter ->
            updateFunc ()

        Ui.KeyDown rawKey key ->
            keyMsgCanvasUpdate audioData rawKey key model

        _ ->
            ( model, Command.none )


uiUpdate : AudioData -> UiHover -> UiEvent -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
uiUpdate audioData id event model =
    case id of
        CloseInviteUser ->
            onPress audioData
                event
                (\() ->
                    ( { model
                        | page =
                            case model.page of
                                WorldPage worldPage ->
                                    WorldPage { worldPage | showInvite = False }

                                _ ->
                                    model.page
                      }
                    , Command.none
                    )
                )
                model

        ShowInviteUser ->
            onPress audioData
                event
                (\() ->
                    ( { model
                        | page =
                            case model.page of
                                WorldPage worldPage ->
                                    WorldPage { worldPage | showInvite = True }

                                _ ->
                                    model.page
                      }
                    , Command.none
                    )
                )
                model

        SubmitInviteUser ->
            onPress audioData event (\() -> sendInvite model) model

        SendEmailButtonHover ->
            onPress audioData event (\() -> sendEmail model) model

        ToolButtonHover tool ->
            onPress audioData event (\() -> ( LoadingPage.setCurrentTool tool model, Command.none )) model

        InviteEmailAddressTextInput ->
            textInputUpdate
                InviteEmailAddressTextInput
                (\_ model2 -> model2)
                (\() -> sendInvite model)
                model.inviteTextInput
                (\a -> { model | inviteTextInput = a })
                event
                model

        EmailAddressTextInputHover ->
            textInputUpdate
                EmailAddressTextInputHover
                (\_ model2 -> model2)
                (\() -> sendEmail model)
                model.loginTextInput
                (\a -> { model | loginTextInput = a })
                event
                model

        PrimaryColorInput ->
            case event of
                Ui.MouseMove { elementPosition } ->
                    ( { model
                        | primaryColorTextInput =
                            TextInput.mouseDownMove
                                (LoadingPage.mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.primaryColorTextInput
                      }
                    , Command.none
                    )

                Ui.MouseDown { elementPosition } ->
                    ( { model
                        | primaryColorTextInput =
                            TextInput.mouseDown
                                (LoadingPage.mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.primaryColorTextInput
                      }
                        |> setFocus (Just PrimaryColorInput)
                    , Command.none
                    )

                Ui.KeyDown _ Keyboard.Escape ->
                    ( setFocus Nothing model, Command.none )

                Ui.KeyDown _ key ->
                    case LocalGrid.currentUserId model of
                        Just userId ->
                            handleKeyDownColorInput
                                userId
                                (\a b -> { b | primaryColorTextInput = a })
                                (\color a -> { a | primaryColor = color })
                                model.currentTool
                                key
                                model
                                model.primaryColorTextInput

                        Nothing ->
                            ( model, Command.none )

                Ui.PastedText text ->
                    case LocalGrid.currentUserId model of
                        Just userId ->
                            TextInput.paste text model.primaryColorTextInput
                                |> colorTextInputAdjustText
                                |> handleKeyDownColorInputHelper
                                    userId
                                    (\a b -> { b | primaryColorTextInput = a })
                                    (\a b -> { b | primaryColor = a })
                                    model.currentTool
                                    model

                        Nothing ->
                            pasteTextTool text model

                _ ->
                    ( model, Command.none )

        SecondaryColorInput ->
            case event of
                Ui.MouseMove { elementPosition } ->
                    ( { model
                        | secondaryColorTextInput =
                            TextInput.mouseDownMove
                                (LoadingPage.mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.secondaryColorTextInput
                      }
                    , Command.none
                    )

                Ui.MouseDown { elementPosition } ->
                    ( { model
                        | secondaryColorTextInput =
                            TextInput.mouseDown
                                (LoadingPage.mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.secondaryColorTextInput
                      }
                        |> setFocus (Just SecondaryColorInput)
                    , Command.none
                    )

                Ui.KeyDown _ Keyboard.Escape ->
                    ( setFocus Nothing model, Command.none )

                Ui.KeyDown _ key ->
                    case LocalGrid.currentUserId model of
                        Just userId ->
                            handleKeyDownColorInput
                                userId
                                (\a b -> { b | secondaryColorTextInput = a })
                                (\color a -> { a | secondaryColor = color })
                                model.currentTool
                                key
                                model
                                model.secondaryColorTextInput

                        Nothing ->
                            ( model, Command.none )

                Ui.PastedText text ->
                    case LocalGrid.currentUserId model of
                        Just userId ->
                            TextInput.paste text model.secondaryColorTextInput
                                |> colorTextInputAdjustText
                                |> handleKeyDownColorInputHelper
                                    userId
                                    (\a b -> { b | secondaryColorTextInput = a })
                                    (\a b -> { b | secondaryColor = a })
                                    model.currentTool
                                    model

                        Nothing ->
                            pasteTextTool text model

                _ ->
                    ( model, Command.none )

        LowerMusicVolume ->
            onPress
                audioData
                event
                (\() -> { model | musicVolume = model.musicVolume - 1 |> max 0 } |> saveUserSettings)
                model

        RaiseMusicVolume ->
            onPress
                audioData
                event
                (\() -> { model | musicVolume = model.musicVolume + 1 |> min Sound.maxVolume } |> saveUserSettings)
                model

        LowerSoundEffectVolume ->
            onPress
                audioData
                event
                (\() -> { model | soundEffectVolume = model.soundEffectVolume - 1 |> max 0 } |> saveUserSettings)
                model

        RaiseSoundEffectVolume ->
            onPress
                audioData
                event
                (\() -> { model | soundEffectVolume = model.soundEffectVolume + 1 |> min Sound.maxVolume } |> saveUserSettings)
                model

        SettingsButton ->
            onPress
                audioData
                event
                (\() ->
                    let
                        localModel =
                            LocalGrid.localModel model.localModel
                    in
                    ( { model
                        | topMenuOpened =
                            case localModel.userStatus of
                                LoggedIn loggedIn ->
                                    TextInput.init
                                        |> TextInput.withText
                                            (case IdDict.get loggedIn.userId localModel.users of
                                                Just user ->
                                                    DisplayName.toString user.name

                                                Nothing ->
                                                    DisplayName.toString DisplayName.default
                                            )
                                        |> SettingsMenu
                                        |> Just

                                NotLoggedIn _ ->
                                    Just LoggedOutSettingsMenu
                      }
                    , Command.none
                    )
                )
                model

        CloseSettings ->
            onPress audioData event (\() -> ( { model | topMenuOpened = Nothing }, Command.none )) model

        DisplayNameTextInput ->
            case model.topMenuOpened of
                Just (SettingsMenu nameTextInput) ->
                    textInputUpdate
                        DisplayNameTextInput
                        (\newTextInput model3 ->
                            let
                                ( model2, outMsg2 ) =
                                    case ( DisplayName.fromString nameTextInput.current.text, DisplayName.fromString newTextInput.current.text ) of
                                        ( Ok old, Ok new ) ->
                                            if old == new then
                                                ( model3, LocalGrid.NoOutMsg )

                                            else
                                                updateLocalModel (Change.ChangeDisplayName new) model3

                                        ( Err _, Ok new ) ->
                                            updateLocalModel (Change.ChangeDisplayName new) model3

                                        _ ->
                                            ( model3, LocalGrid.NoOutMsg )
                            in
                            handleOutMsg False ( model2, outMsg2 ) |> Tuple.first
                        )
                        (\() -> ( model, Command.none ))
                        nameTextInput
                        (\a -> { model | topMenuOpened = Just (SettingsMenu a) })
                        event
                        model

                _ ->
                    ( model, Command.none )

        MailEditorHover mailEditorId ->
            case model.page of
                MailPage mailEditor ->
                    let
                        ( newMailEditor, outMsg ) =
                            MailEditor.uiUpdate
                                model
                                (LoadingPage.mouseScreenPosition model |> Coord.roundPoint)
                                mailEditorId
                                event
                                mailEditor

                        model2 =
                            { model
                                | page =
                                    case newMailEditor of
                                        Just a ->
                                            MailPage a

                                        Nothing ->
                                            WorldPage LoadingPage.initWorldPage
                                , lastMailEditorToggle =
                                    if newMailEditor == Nothing then
                                        Just model.time

                                    else
                                        model.lastMailEditorToggle
                            }
                    in
                    handleMailEditorOutMsg outMsg model2

                _ ->
                    ( model, Command.none )

        YouGotMailButton ->
            onPress audioData event (\() -> ( model, Effect.Lamdera.sendToBackend PostOfficePositionRequest )) model

        ShowMapButton ->
            onPress audioData
                event
                (\() ->
                    ( { model
                        | page =
                            case model.page of
                                WorldPage worldPage ->
                                    WorldPage { worldPage | showMap = not worldPage.showMap }

                                _ ->
                                    model.page
                      }
                    , Command.none
                    )
                )
                model

        AllowEmailNotificationsCheckbox ->
            onPress
                audioData
                event
                (\() ->
                    case LocalGrid.localModel model.localModel |> .userStatus of
                        LoggedIn loggedIn ->
                            updateLocalModel
                                (Change.SetAllowEmailNotifications (not loggedIn.allowEmailNotifications))
                                model
                                |> handleOutMsg False

                        NotLoggedIn _ ->
                            ( model, Command.none )
                )
                model

        UsersOnlineButton ->
            onPress
                audioData
                event
                (\_ -> ( { model | showOnlineUsers = not model.showOnlineUsers }, Command.none ))
                model

        CopyPositionUrlButton ->
            onPress
                audioData
                event
                (\() ->
                    case model.contextMenu of
                        Just contextMenu ->
                            ( { model | contextMenu = Just { contextMenu | linkCopied = True } }
                            , Ports.copyToClipboard (Env.domain ++ Route.encode (Route.internalRoute contextMenu.position))
                            )

                        Nothing ->
                            ( model, Command.none )
                )
                model

        ReportUserButton ->
            onPress
                audioData
                event
                (\() ->
                    case model.contextMenu of
                        Just contextMenu ->
                            case contextMenu.userId of
                                Just userId ->
                                    updateLocalModel
                                        (Change.ReportVandalism { reportedUser = userId, position = contextMenu.position })
                                        model
                                        |> handleOutMsg False

                                Nothing ->
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )
                )
                model

        ZoomInButton ->
            onPress
                audioData
                event
                (\() -> ( { model | zoomFactor = model.zoomFactor + 1 |> min 3 }, Command.none ))
                model

        ZoomOutButton ->
            onPress
                audioData
                event
                (\() -> ( { model | zoomFactor = model.zoomFactor - 1 |> max 1 }, Command.none ))
                model

        RotateLeftButton ->
            onPress
                audioData
                event
                (\() ->
                    ( case model.currentTool of
                        TilePlacerTool currentTile ->
                            tileRotationHelper audioData -1 currentTile model

                        _ ->
                            model
                    , Command.none
                    )
                )
                model

        RotateRightButton ->
            onPress
                audioData
                event
                (\() ->
                    ( case model.currentTool of
                        TilePlacerTool currentTile ->
                            tileRotationHelper audioData 1 currentTile model

                        _ ->
                            model
                    , Command.none
                    )
                )
                model

        AutomaticTimeOfDayButton ->
            onPress
                audioData
                event
                (\() -> updateLocalModel (Change.SetTimeOfDay Automatic) model |> handleOutMsg False)
                model

        AlwaysDayTimeOfDayButton ->
            onPress
                audioData
                event
                (\() -> updateLocalModel (Change.SetTimeOfDay AlwaysDay) model |> handleOutMsg False)
                model

        AlwaysNightTimeOfDayButton ->
            onPress
                audioData
                event
                (\() -> updateLocalModel (Change.SetTimeOfDay AlwaysNight) model |> handleOutMsg False)
                model

        ShowAdminPage ->
            onPress audioData event (\() -> ( { model | page = AdminPage AdminPage.init }, Command.none )) model

        AdminHover adminHover ->
            case model.page of
                AdminPage adminPage ->
                    let
                        ( adminPage2, outMsg ) =
                            AdminPage.update model adminHover event adminPage
                    in
                    case outMsg of
                        AdminPage.NoOutMsg ->
                            ( { model | page = AdminPage adminPage2 }, Command.none )

                        AdminPage.AdminPageClosed ->
                            ( { model | page = WorldPage LoadingPage.initWorldPage }, Command.none )

                        AdminPage.OutMsgAdminChange adminChange ->
                            updateLocalModel
                                (Change.AdminChange adminChange)
                                { model | page = AdminPage adminPage2 }
                                |> handleOutMsg False

                _ ->
                    ( model, Command.none )

        CategoryButton category ->
            onPress audioData event (\() -> ( { model | selectedTileCategory = category }, Command.none )) model

        NotificationsButton ->
            onPress audioData
                event
                (\() -> updateLocalModel (Change.ShowNotifications True) model |> handleOutMsg False)
                model

        CloseNotifications ->
            onPress audioData
                event
                (\() -> updateLocalModel (Change.ShowNotifications False) model |> handleOutMsg False)
                model

        MapChangeNotification coord ->
            onPress
                audioData
                event
                (\() ->
                    ( model
                    , Effect.Browser.Navigation.pushUrl model.key (Route.encode (Route.internalRoute coord))
                    )
                )
                model

        ShowInviteTreeButton ->
            onPress
                audioData
                event
                (\() -> ( { model | page = InviteTreePage }, Command.none ))
                model

        CloseInviteTreeButton ->
            onPress
                audioData
                event
                (\() -> ( { model | page = WorldPage LoadingPage.initWorldPage }, Command.none ))
                model


textInputUpdate :
    UiHover
    -> (TextInput.Model -> FrontendLoaded -> FrontendLoaded)
    -> (() -> ( FrontendLoaded, Command FrontendOnly toMsg msg ))
    -> TextInput.Model
    -> (TextInput.Model -> FrontendLoaded)
    -> UiEvent
    -> FrontendLoaded
    -> ( FrontendLoaded, Command FrontendOnly toMsg msg )
textInputUpdate id textChanged onEnter textInput setTextInput event model =
    case event of
        Ui.PastedText text ->
            let
                textInput2 =
                    TextInput.paste text textInput
            in
            ( setTextInput textInput2 |> textChanged textInput2
            , Command.none
            )

        Ui.MouseDown { elementPosition } ->
            ( TextInput.mouseDown
                (LoadingPage.mouseScreenPosition model |> Coord.roundPoint)
                elementPosition
                textInput
                |> setTextInput
                |> setFocus (Just id)
            , Command.none
            )

        Ui.KeyDown _ Keyboard.Escape ->
            ( setFocus Nothing model, Command.none )

        Ui.KeyDown _ Keyboard.Enter ->
            onEnter ()

        Ui.KeyDown _ key ->
            let
                ( newTextInput, outMsg ) =
                    TextInput.keyMsg
                        (LocalGrid.ctrlOrMeta model)
                        (LocalGrid.keyDown Keyboard.Shift model)
                        key
                        textInput
            in
            ( setTextInput newTextInput |> textChanged newTextInput
            , case outMsg of
                CopyText text ->
                    Ports.copyToClipboard text

                PasteText ->
                    Ports.readFromClipboardRequest

                NoOutMsg ->
                    Command.none
            )

        Ui.MousePressed _ ->
            ( model, Command.none )

        Ui.MouseMove { elementPosition } ->
            case model.mouseLeft of
                MouseButtonDown { current } ->
                    ( TextInput.mouseDownMove (Coord.roundPoint current) elementPosition textInput |> setTextInput
                    , Command.none
                    )

                MouseButtonUp _ ->
                    ( model, Command.none )


saveUserSettings : FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly toMsg msg )
saveUserSettings model =
    ( model, Ports.setLocalStorage { musicVolume = model.musicVolume, soundEffectVolume = model.soundEffectVolume } )


sendEmail : FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
sendEmail model2 =
    case model2.pressedSubmitEmail of
        NotSubmitted _ ->
            case EmailAddress.fromString model2.loginTextInput.current.text of
                Just emailAddress ->
                    ( { model2 | pressedSubmitEmail = Submitting }
                    , Untrusted.untrust emailAddress |> SendLoginEmailRequest |> Effect.Lamdera.sendToBackend
                    )

                Nothing ->
                    ( { model2 | pressedSubmitEmail = NotSubmitted { pressedSubmit = True } }
                    , Command.none
                    )

        Submitting ->
            ( model2, Command.none )

        Submitted _ ->
            ( model2, Command.none )


isPrimaryColorInput : Maybe UiHover -> Bool
isPrimaryColorInput hover =
    case hover of
        Just PrimaryColorInput ->
            True

        _ ->
            False


isSecondaryColorInput : Maybe UiHover -> Bool
isSecondaryColorInput hover =
    case hover of
        Just SecondaryColorInput ->
            True

        _ ->
            False


setFocus : Maybe UiHover -> FrontendLoaded -> FrontendLoaded
setFocus newFocus model =
    { model
        | focus = newFocus
        , currentTool =
            case model.currentTool of
                TextTool _ ->
                    if newFocus == Nothing then
                        model.currentTool

                    else
                        TextTool Nothing

                _ ->
                    model.currentTool
        , primaryColorTextInput =
            case LocalGrid.currentUserId model of
                Just userId ->
                    if isPrimaryColorInput model.focus && not (isPrimaryColorInput newFocus) then
                        case model.currentTool of
                            TilePlacerTool { tileGroup } ->
                                model.primaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (LoadingPage.getTileColor tileGroup model).primaryColor)

                            TilePickerTool ->
                                model.primaryColorTextInput

                            HandTool ->
                                TextInput.withText
                                    (Color.toHexCode (LoadingPage.getHandColor userId model).primaryColor)
                                    model.primaryColorTextInput

                            TextTool _ ->
                                model.primaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (LoadingPage.getTileColor BigTextGroup model).primaryColor)

                            ReportTool ->
                                model.primaryColorTextInput

                    else if not (isPrimaryColorInput model.focus) && isPrimaryColorInput newFocus then
                        TextInput.selectAll model.primaryColorTextInput

                    else
                        model.primaryColorTextInput

                Nothing ->
                    model.primaryColorTextInput
        , secondaryColorTextInput =
            case LocalGrid.currentUserId model of
                Just userId ->
                    if isSecondaryColorInput model.focus && not (isSecondaryColorInput newFocus) then
                        case model.currentTool of
                            TilePlacerTool { tileGroup } ->
                                model.secondaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (LoadingPage.getTileColor tileGroup model).secondaryColor)

                            TilePickerTool ->
                                model.secondaryColorTextInput

                            HandTool ->
                                TextInput.withText
                                    (Color.toHexCode (LoadingPage.getHandColor userId model).secondaryColor)
                                    model.secondaryColorTextInput

                            TextTool _ ->
                                model.secondaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (LoadingPage.getTileColor BigTextGroup model).secondaryColor)

                            ReportTool ->
                                model.secondaryColorTextInput

                    else if not (isSecondaryColorInput model.focus) && isSecondaryColorInput newFocus then
                        TextInput.selectAll model.secondaryColorTextInput

                    else
                        model.secondaryColorTextInput

                Nothing ->
                    model.secondaryColorTextInput
    }


clickLeaveHomeTrain : Id TrainId -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly toMsg FrontendMsg_ )
clickLeaveHomeTrain trainId model =
    updateLocalModel (Change.LeaveHomeTrainRequest trainId model.time) model
        |> handleOutMsg False


clickTeleportHomeTrain : Id TrainId -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly toMsg FrontendMsg_ )
clickTeleportHomeTrain trainId model =
    updateLocalModel (Change.TeleportHomeTrainRequest trainId model.time) model
        |> handleOutMsg False


setTrainViewPoint : Id TrainId -> FrontendLoaded -> FrontendLoaded
setTrainViewPoint trainId model =
    { model
        | viewPoint =
            TrainViewPoint
                { trainId = trainId
                , startViewPoint = Toolbar.actualViewPoint model
                , startTime = model.time
                }
    }


canOpenMailEditor : FrontendLoaded -> Maybe (IdDict UserId (List MailEditor.Content))
canOpenMailEditor model =
    case ( model.page, model.currentTool, LocalGrid.localModel model.localModel |> .userStatus ) of
        ( WorldPage _, HandTool, LoggedIn loggedIn ) ->
            Just loggedIn.mailDrafts

        _ ->
            Nothing


updateLocalModel : Change.LocalChange -> FrontendLoaded -> ( FrontendLoaded, LocalGrid.OutMsg )
updateLocalModel msg model =
    let
        ( newLocalModel, outMsg ) =
            LocalGrid.update (LocalChange model.eventIdCounter msg) model.localModel
    in
    case LocalGrid.localModel model.localModel |> .userStatus of
        LoggedIn _ ->
            ( { model
                | pendingChanges = ( model.eventIdCounter, msg ) :: model.pendingChanges
                , localModel = newLocalModel
                , eventIdCounter = Id.increment model.eventIdCounter
              }
            , outMsg
            )

        NotLoggedIn _ ->
            ( { model
                | localModel =
                    -- If we are not logged in then we don't send any msgs to the server and therefore don't want to keep all of the msgs in the localMsgs list
                    LocalModel.unwrap newLocalModel
                        |> (\a -> LocalModel.unsafe { a | localMsgs = [], model = a.localModel })
              }
            , LocalGrid.NoOutMsg
            )


placeTile : Bool -> TileGroup -> Int -> FrontendLoaded -> FrontendLoaded
placeTile isDragPlacement tileGroup index model =
    let
        tile =
            Toolbar.getTileGroupTile tileGroup index

        tileData =
            Tile.getData tile
    in
    placeTileAt (LoadingPage.cursorPosition tileData model) isDragPlacement tileGroup index model


placeTileAt : Coord WorldUnit -> Bool -> TileGroup -> Int -> FrontendLoaded -> FrontendLoaded
placeTileAt cursorPosition_ isDragPlacement tileGroup index model =
    case LocalGrid.currentUserId model of
        Just userId ->
            let
                tile =
                    Toolbar.getTileGroupTile tileGroup index

                hasCollision : Bool
                hasCollision =
                    case model.lastTilePlaced of
                        Just lastPlaced ->
                            Tile.hasCollision cursorPosition_ tile lastPlaced.position lastPlaced.tile

                        Nothing ->
                            False

                colors =
                    LoadingPage.getTileColor tileGroup model

                change =
                    { position = cursorPosition_
                    , change = tile
                    , userId = userId
                    , colors = colors
                    , time = model.time
                    }

                grid : Grid
                grid =
                    LocalGrid.localModel model.localModel |> .grid
            in
            if isDragPlacement && hasCollision then
                model

            else if not (LoadingPage.canPlaceTile model.time change model.trains grid) then
                if tile == EmptyTile then
                    { model
                        | lastTilePlaced =
                            Just
                                { time =
                                    case model.lastTilePlaced of
                                        Just lastTilePlaced ->
                                            if
                                                Duration.from lastTilePlaced.time model.time
                                                    |> Quantity.lessThan (Duration.milliseconds 100)
                                            then
                                                lastTilePlaced.time

                                            else
                                                model.time

                                        Nothing ->
                                            model.time
                                , overwroteTiles = False
                                , tile = tile
                                , position = cursorPosition_
                                }
                    }

                else
                    { model
                        | lastPlacementError =
                            case model.lastPlacementError of
                                Just time ->
                                    if Duration.from time model.time |> Quantity.lessThan (Duration.milliseconds 150) then
                                        model.lastPlacementError

                                    else
                                        Just model.time

                                Nothing ->
                                    Just model.time
                    }

            else
                let
                    model2 =
                        if Duration.from model.undoAddLast model.time |> Quantity.greaterThan (Duration.seconds 0.5) then
                            updateLocalModel Change.LocalAddUndo { model | undoAddLast = model.time } |> Tuple.first

                        else
                            model

                    ( model3, outMsg ) =
                        updateLocalModel
                            (Change.LocalGridChange
                                { position = cursorPosition_
                                , change = tile
                                , colors = colors
                                , time = model.time
                                }
                            )
                            model2

                    removedTiles : List RemovedTileParticle
                    removedTiles =
                        case outMsg of
                            LocalGrid.TilesRemoved tiles ->
                                List.filterMap
                                    (\removedTile ->
                                        if removedTile.tile == EmptyTile then
                                            Nothing

                                        else
                                            Just
                                                { tile = removedTile.tile
                                                , time = model.time
                                                , position = removedTile.position
                                                , colors = removedTile.colors
                                                }
                                    )
                                    tiles

                            _ ->
                                []
                in
                { model3
                    | lastTilePlaced =
                        Just
                            { time =
                                case model.lastTilePlaced of
                                    Just lastTilePlaced ->
                                        if
                                            Duration.from lastTilePlaced.time model.time
                                                |> Quantity.lessThan (Duration.milliseconds 100)
                                        then
                                            lastTilePlaced.time

                                        else
                                            model.time

                                    Nothing ->
                                        model.time
                            , overwroteTiles = List.isEmpty removedTiles |> not
                            , tile = tile
                            , position = cursorPosition_
                            }
                    , removedTileParticles = removedTiles ++ model3.removedTileParticles
                    , debrisMesh = createDebrisMesh model.startTime (removedTiles ++ model3.removedTileParticles)
                    , trains =
                        case Train.handleAddingTrain model3.trains userId tile cursorPosition_ of
                            Just ( trainId, train ) ->
                                IdDict.insert trainId train model.trains

                            Nothing ->
                                model.trains
                }

        Nothing ->
            model


createDebrisMesh : Effect.Time.Posix -> List RemovedTileParticle -> Effect.WebGL.Mesh DebrisVertex
createDebrisMesh appStartTime removedTiles =
    let
        list : List RemovedTileParticle
        list =
            removedTiles
                |> List.sortBy
                    (\{ position, tile } ->
                        let
                            ( _, Quantity y ) =
                                position

                            ( _, Quantity height ) =
                                Tile.getData tile |> .size
                        in
                        y + height
                    )
    in
    List.concatMap
        (\{ position, tile, time, colors } ->
            let
                data =
                    Tile.getData tile
            in
            createDebrisMeshHelper
                position
                data.texturePosition
                data.size
                colors
                (case tile of
                    BigText _ ->
                        2

                    _ ->
                        1
                )
                appStartTime
                time
        )
        list
        |> Sprite.toMesh


createDebrisMeshHelper :
    Coord WorldUnit
    -> Coord unit
    -> Coord unit
    -> Colors
    -> Int
    -> Effect.Time.Posix
    -> Effect.Time.Posix
    -> List DebrisVertex
createDebrisMeshHelper position texturePosition ( Quantity textureW, Quantity textureH ) colors scale appStartTime time =
    let
        primaryColor2 =
            Color.toInt colors.primaryColor |> toFloat

        secondaryColor2 =
            Color.toInt colors.secondaryColor |> toFloat

        time2 =
            Duration.from appStartTime time |> Duration.inSeconds
    in
    List.concatMap
        (\x2 ->
            List.concatMap
                (\y2 ->
                    let
                        ( x3, y3 ) =
                            Coord.xy x2 y2 |> Coord.multiply Units.tileSize |> Coord.toTuple

                        initialSpeed : Vec2
                        initialSpeed =
                            Random.step
                                (Random.map2
                                    (\randomX randomY ->
                                        Vec2.vec2
                                            ((toFloat x2 + 0.5 - toFloat textureW / 2) * 100 + randomX)
                                            (((toFloat y2 + 0.5 - toFloat textureH / 2) * 100) + randomY - 100)
                                    )
                                    (Random.float -40 40)
                                    (Random.float -40 40)
                                )
                                (Random.initialSeed (Effect.Time.posixToMillis time + x2 * 3 + y2 * 5))
                                |> Tuple.first

                        ( w, h ) =
                            Units.tileSize |> Coord.divide (Coord.xy scale scale) |> Coord.toTuple

                        ( tx, ty ) =
                            Coord.plus (Coord.xy x3 y3 |> Coord.divide (Coord.xy scale scale)) texturePosition |> Coord.toTuple

                        ( x4, y4 ) =
                            Coord.multiply Units.tileSize position
                                |> Coord.plus (Coord.xy x3 y3)
                                |> Coord.toTuple

                        ( width, height ) =
                            Coord.toTuple Units.tileSize
                    in
                    [ { position = Vec2.vec2 (toFloat x4) (toFloat y4)
                      , texturePosition = toFloat tx + Sprite.textureWidth * toFloat ty
                      , primaryColor = primaryColor2
                      , secondaryColor = secondaryColor2
                      , initialSpeed = initialSpeed
                      , startTime = time2
                      }
                    , { position = Vec2.vec2 (toFloat (x4 + width)) (toFloat y4)
                      , texturePosition = toFloat (tx + w) + Sprite.textureWidth * toFloat ty
                      , primaryColor = primaryColor2
                      , secondaryColor = secondaryColor2
                      , initialSpeed = initialSpeed
                      , startTime = time2
                      }
                    , { position = Vec2.vec2 (toFloat (x4 + width)) (toFloat (y4 + height))
                      , texturePosition = toFloat (tx + w) + Sprite.textureWidth * toFloat (ty + h)
                      , primaryColor = primaryColor2
                      , secondaryColor = secondaryColor2
                      , initialSpeed = initialSpeed
                      , startTime = time2
                      }
                    , { position = Vec2.vec2 (toFloat x4) (toFloat (y4 + height))
                      , texturePosition = toFloat tx + Sprite.textureWidth * toFloat (ty + h)
                      , primaryColor = primaryColor2
                      , secondaryColor = secondaryColor2
                      , initialSpeed = initialSpeed
                      , startTime = time2
                      }
                    ]
                )
                (List.range 0 (textureH - 1))
        )
        (List.range 0 (textureW - 1))


updateFromBackend : ToFrontend -> FrontendModel_ -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
updateFromBackend msg model =
    case ( model, msg ) of
        ( Loading loading, LoadingData loadingData ) ->
            ( Loading
                { loading
                    | localModel =
                        case loading.localModel of
                            LoadingLocalModel [] ->
                                LoadedLocalModel
                                    { localModel = LocalGrid.init loadingData
                                    , trains = loadingData.trains
                                    , mail = loadingData.mail
                                    }

                            LoadingLocalModel (first :: rest) ->
                                LoadedLocalModel
                                    { localModel =
                                        LocalGrid.init loadingData
                                            |> LocalGrid.updateFromBackend (Nonempty first rest)
                                            |> Tuple.first
                                    , trains = loadingData.trains
                                    , mail = loadingData.mail
                                    }

                            LoadedLocalModel _ ->
                                loading.localModel
                }
            , Command.none
            )

        ( Loading loading, ChangeBroadcast changes ) ->
            ( (case loading.localModel of
                LoadingLocalModel pendingChanges ->
                    { loading | localModel = pendingChanges ++ List.Nonempty.toList changes |> LoadingLocalModel }

                LoadedLocalModel loadedLocalModel ->
                    { loading
                        | localModel =
                            LoadedLocalModel
                                { localModel = LocalGrid.updateFromBackend changes loadedLocalModel.localModel |> Tuple.first
                                , trains = loadedLocalModel.trains
                                , mail = loadedLocalModel.mail
                                }
                    }
              )
                |> Loading
            , Command.none
            )

        ( Loaded loaded, _ ) ->
            updateLoadedFromBackend msg loaded
                |> Tuple.mapFirst (reportsMeshUpdate loaded)
                |> Tuple.mapFirst Loaded

        _ ->
            ( model, Command.none )


handleOutMsg :
    Bool
    -> ( FrontendLoaded, LocalGrid.OutMsg )
    -> ( FrontendLoaded, Command FrontendOnly toMsg FrontendMsg_ )
handleOutMsg isFromBackend ( model, outMsg ) =
    case outMsg of
        LocalGrid.NoOutMsg ->
            ( model, Command.none )

        LocalGrid.TilesRemoved _ ->
            ( model, Command.none )

        LocalGrid.OtherUserCursorMoved { userId, previousPosition } ->
            ( { model
                | previousCursorPositions =
                    case previousPosition of
                        Just previousPosition2 ->
                            IdDict.insert
                                userId
                                { position = previousPosition2, time = model.time }
                                model.previousCursorPositions

                        Nothing ->
                            IdDict.remove userId model.previousCursorPositions
              }
            , Command.none
            )

        LocalGrid.HandColorOrNameChanged userId ->
            ( case LocalGrid.localModel model.localModel |> .users |> IdDict.get userId of
                Just user ->
                    { model
                        | handMeshes =
                            IdDict.insert
                                userId
                                (Cursor.meshes
                                    (if Just userId == LocalGrid.currentUserId model then
                                        Nothing

                                     else
                                        Just ( userId, user.name )
                                    )
                                    user.handColor
                                )
                                model.handMeshes
                    }

                Nothing ->
                    model
            , Command.none
            )

        LocalGrid.RailToggledByAnother position ->
            ( handleRailToggleSound position model, Command.none )

        LocalGrid.RailToggledBySelf position ->
            ( if isFromBackend then
                model

              else
                handleRailToggleSound position model
            , Command.none
            )

        LocalGrid.TeleportTrainHome trainId ->
            ( { model | trains = IdDict.update2 trainId (Train.startTeleportingHome model.time) model.trains }
            , Command.none
            )

        LocalGrid.TrainLeaveHome trainId ->
            ( { model | trains = IdDict.update2 trainId (Train.leaveHome model.time) model.trains }
            , Command.none
            )

        LocalGrid.TrainsUpdated diff ->
            ( { model
                | trains =
                    IdDict.toList diff
                        |> List.filterMap
                            (\( trainId, diff_ ) ->
                                case IdDict.get trainId model.trains |> Train.applyDiff diff_ of
                                    Just newTrain ->
                                        Just ( trainId, newTrain )

                                    Nothing ->
                                        Nothing
                            )
                        |> IdDict.fromList
              }
            , Command.none
            )

        LocalGrid.ReceivedMail ->
            ( { model | lastReceivedMail = Just model.time }, Command.none )

        LocalGrid.ExportMail content ->
            ( model
            , Effect.File.Download.string
                "letter.json"
                "application/json"
                (Codec.encodeToString 2 (Codec.list MailEditor.contentCodec) content)
            )

        LocalGrid.ImportMail ->
            ( model, Effect.File.Select.file [ "application/json" ] ImportedMail )


handleRailToggleSound : Coord WorldUnit -> FrontendLoaded -> FrontendLoaded
handleRailToggleSound position model =
    { model
        | railToggles =
            ( model.time, position )
                :: List.filter
                    (\( time, _ ) ->
                        Duration.from time model.time
                            |> Quantity.lessThan Duration.second
                    )
                    model.railToggles
    }


updateLoadedFromBackend : ToFrontend -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
updateLoadedFromBackend msg model =
    case msg of
        LoadingData loadingData ->
            ( { model
                | localModel = LocalGrid.init loadingData
                , trains = loadingData.trains
                , isReconnecting = False
                , pendingChanges = []
              }
            , Command.none
            )

        ChangeBroadcast changes ->
            let
                ( newLocalModel, outMsgs ) =
                    LocalGrid.updateFromBackend changes model.localModel
            in
            List.foldl
                (\outMsg ( state, cmd ) ->
                    let
                        ( model2, cmd2 ) =
                            handleOutMsg True ( state, outMsg )
                    in
                    ( model2, Command.batch [ cmd, cmd2 ] )
                )
                ( { model | localModel = newLocalModel }, Command.none )
                outMsgs

        UnsubscribeEmailConfirmed ->
            ( model, Command.none )

        PingResponse serverTime ->
            case model.pingStartTime of
                Just pingStartTime ->
                    let
                        keepPinging =
                            (pingCount < 5)
                                || (newHighEstimate
                                        |> Quantity.minus newLowEstimate
                                        |> Quantity.greaterThan (Duration.milliseconds 200)
                                   )

                        {- The time stored in the model is potentially out of date by an animation frame. We want to make sure our high estimate overestimates rather than underestimates the true time so we add an extra animation frame here. -}
                        localTimeHighEstimate =
                            Duration.addTo (actualTime model) (Duration.milliseconds (1000 / 60))

                        serverTime2 =
                            serverTime

                        ( newLowEstimate, newHighEstimate, pingCount ) =
                            case model.pingData of
                                Just oldPingData ->
                                    ( Duration.from serverTime2 pingStartTime |> Quantity.max oldPingData.lowEstimate
                                    , Duration.from serverTime2 localTimeHighEstimate |> Quantity.min oldPingData.highEstimate
                                    , oldPingData.pingCount + 1
                                    )

                                Nothing ->
                                    ( Duration.from serverTime2 pingStartTime
                                    , Duration.from serverTime2 localTimeHighEstimate
                                    , 1
                                    )
                    in
                    ( { model
                        | pingData =
                            -- This seems to happen if the user tabs away. I'm not sure how to prevent it so here we just start over if we end up in this state.
                            if newHighEstimate |> Quantity.lessThan newLowEstimate then
                                Nothing

                            else
                                Just
                                    { roundTripTime = Duration.from pingStartTime (actualTime model)
                                    , lowEstimate = newLowEstimate
                                    , highEstimate = newHighEstimate
                                    , serverTime = serverTime2
                                    , sendTime = pingStartTime
                                    , receiveTime = actualTime model
                                    , pingCount = pingCount
                                    }
                        , pingStartTime =
                            if keepPinging then
                                Just (actualTime model)

                            else
                                Nothing
                      }
                    , if keepPinging then
                        Effect.Lamdera.sendToBackend PingRequest

                      else
                        Command.none
                    )

                Nothing ->
                    ( model, Command.none )

        SendLoginEmailResponse emailAddress ->
            ( { model
                | pressedSubmitEmail =
                    case model.pressedSubmitEmail of
                        Submitting ->
                            Submitted emailAddress

                        NotSubmitted _ ->
                            model.pressedSubmitEmail

                        Submitted _ ->
                            model.pressedSubmitEmail
              }
            , Command.none
            )

        SendInviteEmailResponse emailAddress ->
            ( { model
                | inviteSubmitStatus =
                    case model.inviteSubmitStatus of
                        NotSubmitted _ ->
                            model.inviteSubmitStatus

                        Submitting ->
                            Submitted emailAddress

                        Submitted _ ->
                            model.inviteSubmitStatus
              }
            , Command.none
            )

        DebugResponse debugText ->
            ( { model | debugText = debugText }, Command.none )

        PostOfficePositionResponse maybePosition ->
            case maybePosition of
                Just position ->
                    let
                        postOfficeSize =
                            Tile.getData PostOffice |> .size |> Coord.toVector2d |> Vector2d.scaleBy 0.5
                    in
                    ( { model
                        | viewPoint =
                            Coord.toPoint2d position |> Point2d.translateBy postOfficeSize |> NormalViewPoint
                      }
                    , Command.none
                    )

                Nothing ->
                    ( model, Command.none )

        ClientConnected ->
            let
                bounds =
                    LoadingPage.loadingCellBounds model
            in
            ( { model | isReconnecting = True }
            , ConnectToBackend bounds Nothing |> Effect.Lamdera.sendToBackend
            )

        CheckConnectionBroadcast ->
            ( { model | lastCheckConnection = model.time }, Command.none )


actualTime : FrontendLoaded -> Effect.Time.Posix
actualTime model =
    Duration.addTo model.localTime debugTimeOffset


debugTimeOffset =
    Duration.seconds 0


view : AudioData -> FrontendModel_ -> Browser.Document FrontendMsg_
view audioData model =
    { title =
        case model of
            Loading _ ->
                "Town Collab"

            Loaded loaded ->
                if Toolbar.isDisconnected loaded then
                    "Town Collab (disconnected)"

                else
                    "Town Collab"
    , body =
        [ case model of
            Loading loadingModel ->
                LoadingPage.loadingCanvasView loadingModel

            Loaded loadedModel ->
                canvasView audioData loadedModel
        , case model of
            Loading _ ->
                Html.text ""

            Loaded loadedModel ->
                Html.text loadedModel.debugText
        , Html.node "style" [] [ Html.text "body { overflow: hidden; margin: 0; }" ]
        ]
    }


viewBoundingBox : FrontendLoaded -> BoundingBox2d WorldUnit WorldUnit
viewBoundingBox model =
    BoundingBox2d.from
        (Toolbar.screenToWorld model Point2d.origin)
        (Toolbar.screenToWorld model (Coord.toPoint2d model.windowSize))


cursorSprite : Hover -> FrontendLoaded -> { cursorType : CursorType, scale : Int }
cursorSprite hover model =
    case LocalGrid.currentUserId model of
        Just userId ->
            let
                helper () =
                    case model.page of
                        MailPage mailEditor ->
                            case hover of
                                UiHover (MailEditorHover uiHover) _ ->
                                    MailEditor.cursorSprite model.windowSize uiHover mailEditor

                                _ ->
                                    { cursorType = DefaultCursor, scale = 1 }

                        AdminPage _ ->
                            { cursorType =
                                case hover of
                                    UiHover _ _ ->
                                        PointerCursor

                                    _ ->
                                        DefaultCursor
                            , scale = 1
                            }

                        WorldPage _ ->
                            { cursorType =
                                if isHoldingCow model /= Nothing then
                                    CursorSprite PinchSpriteCursor

                                else
                                    case LocalGrid.currentTool model of
                                        TilePlacerTool _ ->
                                            case hover of
                                                UiBackgroundHover ->
                                                    DefaultCursor

                                                TileHover _ ->
                                                    NoCursor

                                                TrainHover _ ->
                                                    NoCursor

                                                MapHover ->
                                                    NoCursor

                                                CowHover _ ->
                                                    NoCursor

                                                UiHover _ _ ->
                                                    PointerCursor

                                        HandTool ->
                                            case hover of
                                                UiBackgroundHover ->
                                                    DefaultCursor

                                                TileHover data ->
                                                    case tileInteraction userId data model of
                                                        Just _ ->
                                                            CursorSprite PointerSpriteCursor

                                                        Nothing ->
                                                            CursorSprite DefaultSpriteCursor

                                                TrainHover _ ->
                                                    CursorSprite PointerSpriteCursor

                                                MapHover ->
                                                    CursorSprite DefaultSpriteCursor

                                                CowHover _ ->
                                                    CursorSprite PointerSpriteCursor

                                                UiHover _ _ ->
                                                    PointerCursor

                                        TilePickerTool ->
                                            case hover of
                                                UiBackgroundHover ->
                                                    DefaultCursor

                                                TileHover _ ->
                                                    CursorSprite EyeDropperSpriteCursor

                                                TrainHover _ ->
                                                    CursorSprite EyeDropperSpriteCursor

                                                MapHover ->
                                                    CursorSprite EyeDropperSpriteCursor

                                                CowHover _ ->
                                                    CursorSprite EyeDropperSpriteCursor

                                                UiHover _ _ ->
                                                    PointerCursor

                                        TextTool _ ->
                                            case hover of
                                                UiBackgroundHover ->
                                                    DefaultCursor

                                                TileHover _ ->
                                                    CursorSprite TextSpriteCursor

                                                TrainHover _ ->
                                                    CursorSprite TextSpriteCursor

                                                MapHover ->
                                                    CursorSprite TextSpriteCursor

                                                CowHover _ ->
                                                    CursorSprite TextSpriteCursor

                                                UiHover _ _ ->
                                                    PointerCursor

                                        ReportTool ->
                                            case hover of
                                                UiBackgroundHover ->
                                                    DefaultCursor

                                                TileHover _ ->
                                                    CursorSprite GavelSpriteCursor

                                                TrainHover _ ->
                                                    CursorSprite GavelSpriteCursor

                                                MapHover ->
                                                    CursorSprite GavelSpriteCursor

                                                CowHover _ ->
                                                    CursorSprite GavelSpriteCursor

                                                UiHover _ _ ->
                                                    PointerCursor
                            , scale = 1
                            }

                        InviteTreePage ->
                            { cursorType =
                                case hover of
                                    UiHover _ _ ->
                                        PointerCursor

                                    _ ->
                                        DefaultCursor
                            , scale = 1
                            }
            in
            case isDraggingView hover model of
                Just mouse ->
                    if isSmallDistance mouse (LoadingPage.mouseScreenPosition model) then
                        helper ()

                    else
                        { cursorType = CursorSprite DragScreenSpriteCursor, scale = 1 }

                Nothing ->
                    helper ()

        Nothing ->
            { cursorType =
                case hover of
                    UiHover _ _ ->
                        PointerCursor

                    _ ->
                        DefaultCursor
            , scale = 1
            }


isDraggingView :
    Hover
    -> FrontendLoaded
    ->
        Maybe
            { start : Point2d Pixels Pixels
            , start_ : Point2d WorldUnit WorldUnit
            , current : Point2d Pixels Pixels
            , hover : Hover
            }
isDraggingView hover model =
    case ( model.page, model.mouseLeft, model.mouseMiddle ) of
        ( WorldPage _, _, MouseButtonDown a ) ->
            Just a

        ( WorldPage _, MouseButtonDown a, _ ) ->
            case model.currentTool of
                TilePlacerTool _ ->
                    Nothing

                TilePickerTool ->
                    if Toolbar.canDragView hover then
                        Just a

                    else
                        Nothing

                HandTool ->
                    if Toolbar.canDragView hover then
                        Just a

                    else
                        Nothing

                TextTool _ ->
                    Nothing

                ReportTool ->
                    if Toolbar.canDragView hover then
                        Just a

                    else
                        Nothing

        _ ->
            Nothing


shaderTime : { a | startTime : Time.Posix, time : Time.Posix } -> Float
shaderTime model =
    Duration.from model.startTime model.time |> Duration.inSeconds


getNightFactor : FrontendLoaded -> Float
getNightFactor model =
    let
        localGrid =
            LocalGrid.localModel model.localModel

        timeOfDay : TimeOfDay
        timeOfDay =
            case localGrid.userStatus of
                LoggedIn loggedIn ->
                    loggedIn.timeOfDay

                NotLoggedIn notLoggedIn ->
                    notLoggedIn.timeOfDay
    in
    TimeOfDay.nightFactor timeOfDay model.time


staticMatrix windowWidth windowHeight zoom =
    Mat4.makeScale3 (toFloat zoom * 2 / toFloat windowWidth) (toFloat zoom * -2 / toFloat windowHeight) 1


drawWorldPreview :
    Coord Pixels
    -> Coord Pixels
    -> Point2d WorldUnit WorldUnit
    -> Int
    -> RenderData
    -> Float
    -> FrontendLoaded
    -> List Effect.WebGL.Entity
drawWorldPreview viewportPosition viewportSize viewPosition viewZoom renderData nightFactor model =
    let
        ( windowWidth, windowHeight ) =
            Coord.toTuple model.windowSize

        staticViewMatrix2 : Mat4
        staticViewMatrix2 =
            staticMatrix windowWidth windowHeight viewZoom
                |> Mat4.translate3
                    (toFloat ((Coord.xRaw viewportPosition + Coord.xRaw viewportSize // 2) - windowWidth // 2)
                        |> round
                        |> toFloat
                        |> (*) (1 / toFloat viewZoom)
                    )
                    (toFloat ((Coord.yRaw viewportPosition + Coord.yRaw viewportSize // 2) - windowHeight // 2)
                        |> round
                        |> toFloat
                        |> (*) (1 / toFloat viewZoom)
                    )
                    0

        viewPoint : { x : Float, y : Float }
        viewPoint =
            Point2d.unwrap viewPosition

        offset : Vector2d WorldUnit WorldUnit
        offset =
            Units.pixelToTile viewportSize |> Coord.toVector2d |> Vector2d.scaleBy 0.5

        viewBounds : BoundingBox2d WorldUnit WorldUnit
        viewBounds =
            BoundingBox2d.from
                (viewPosition |> Point2d.translateBy (Vector2d.reverse offset))
                (viewPosition |> Point2d.translateBy offset)
    in
    drawWorld
        False
        { lights = renderData.lights
        , texture = renderData.texture
        , depth = renderData.depth
        , nightFactor = nightFactor
        , staticViewMatrix = staticViewMatrix2
        , viewMatrix =
            staticViewMatrix2
                |> Mat4.translate3
                    (toFloat <| round (-viewPoint.x * toFloat Units.tileWidth))
                    (toFloat <| round (-viewPoint.y * toFloat Units.tileHeight))
                    0
        , time = renderData.time
        , scissors =
            { left = Coord.xRaw viewportPosition
            , bottom = (windowHeight - Coord.yRaw viewportPosition) - Coord.yRaw viewportSize
            , width = Coord.xRaw viewportSize
            , height = Coord.yRaw viewportSize
            }
        }
        windowWidth
        windowHeight
        MapHover
        viewBounds
        model


canvasView : AudioData -> FrontendLoaded -> Html FrontendMsg_
canvasView audioData model =
    case
        ( Effect.WebGL.Texture.unwrap model.texture
        , Effect.WebGL.Texture.unwrap model.lightsTexture
        , Effect.WebGL.Texture.unwrap model.depthTexture
        )
    of
        ( Just texture, Just lightsTexture, Just depth ) ->
            let
                viewBounds_ : BoundingBox2d WorldUnit WorldUnit
                viewBounds_ =
                    viewBoundingBox model

                ( windowWidth, windowHeight ) =
                    Coord.toTuple model.windowSize

                ( cssWindowWidth, cssWindowHeight ) =
                    Coord.toTuple model.cssCanvasSize

                { x, y } =
                    Point2d.unwrap (Toolbar.actualViewPoint model)

                hoverAt2 : Hover
                hoverAt2 =
                    hoverAt model (LoadingPage.mouseScreenPosition model)

                showMousePointer =
                    cursorSprite hoverAt2 model

                staticViewMatrix =
                    staticMatrix windowWidth windowHeight model.zoomFactor

                renderData : RenderData
                renderData =
                    { lights = lightsTexture
                    , texture = texture
                    , depth = depth
                    , nightFactor = getNightFactor model
                    , staticViewMatrix = staticViewMatrix
                    , viewMatrix =
                        staticViewMatrix
                            |> Mat4.translate3
                                (negate <| toFloat <| round (x * toFloat Units.tileWidth))
                                (negate <| toFloat <| round (y * toFloat Units.tileHeight))
                                0
                    , time = shaderTime model
                    , scissors = { left = 0, bottom = 0, width = windowWidth, height = windowHeight }
                    }

                textureSize : Vec2
                textureSize =
                    WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
            in
            Effect.WebGL.toHtmlWith
                [ Effect.WebGL.alpha False
                , Effect.WebGL.clearColor 1 1 1 1
                , Effect.WebGL.depth 1
                ]
                ([ Html.Attributes.width windowWidth
                 , Html.Attributes.height windowHeight
                 , Cursor.htmlAttribute showMousePointer.cursorType
                 , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
                 , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
                 , Html.Events.preventDefaultOn "keydown" (Json.Decode.succeed ( NoOpFrontendMsg, True ))
                 , Html.Events.Extra.Wheel.onWheel MouseWheel
                 ]
                    ++ LoadingPage.mouseListeners model
                )
                (drawWorld True renderData windowWidth windowHeight hoverAt2 viewBounds_ model
                    ++ drawTilePlacer renderData audioData model
                    ++ (case model.page of
                            MailPage _ ->
                                [ MailEditor.backgroundLayer renderData ]

                            _ ->
                                []
                       )
                    ++ [ Effect.WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            model.uiMesh
                            { view =
                                Mat4.makeScale3 (2 / toFloat windowWidth) (-2 / toFloat windowHeight) 1
                                    |> Coord.translateMat4 (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                            , texture = texture
                            , lights = lightsTexture
                            , depth = depth
                            , textureSize = textureSize
                            , color = Vec4.vec4 1 1 1 1
                            , userId = Shaders.noUserIdSelected
                            , time = shaderTime model
                            , night = renderData.nightFactor * 0.5
                            }
                       ]
                    ++ (case hoverAt2 of
                            UiHover id data ->
                                case id of
                                    MapChangeNotification changeAt ->
                                        drawWorldPreview
                                            (Coord.xy Toolbar.notificationsViewWidth (Coord.yRaw data.position))
                                            (Coord.scalar 2 LocalGrid.notificationViewportHalfSize |> Units.tileToPixel)
                                            (Coord.toPoint2d changeAt)
                                            1
                                            renderData
                                            renderData.nightFactor
                                            model

                                    _ ->
                                        []

                            _ ->
                                []
                       )
                    ++ drawMap model
                    ++ (case model.page of
                            MailPage mailEditor ->
                                let
                                    ( mailPosition, mailSize ) =
                                        case Ui.findInput (MailEditorHover MailEditor.MailButton) model.ui of
                                            Just (Ui.ButtonType mailButton) ->
                                                ( mailButton.position, mailButton.data.cachedSize )

                                            _ ->
                                                ( Coord.origin, Coord.origin )
                                in
                                MailEditor.drawMail
                                    renderData
                                    mailPosition
                                    mailSize
                                    (LoadingPage.mouseScreenPosition model)
                                    windowWidth
                                    windowHeight
                                    model
                                    mailEditor

                            _ ->
                                []
                       )
                    ++ (case LocalGrid.currentUserId model of
                            Just userId ->
                                drawCursor renderData showMousePointer userId model

                            Nothing ->
                                []
                       )
                )

        _ ->
            Html.text ""


drawWorld :
    Bool
    -> RenderData
    -> Int
    -> Int
    -> Hover
    -> BoundingBox2d WorldUnit WorldUnit
    -> FrontendLoaded
    -> List Effect.WebGL.Entity
drawWorld isFirstDraw renderData windowWidth windowHeight hoverAt2 viewBounds_ model =
    let
        { x, y } =
            Point2d.unwrap (Toolbar.actualViewPoint model)

        localGrid : LocalGrid_
        localGrid =
            LocalGrid.localModel model.localModel

        textureSize : Vec2
        textureSize =
            WebGL.Texture.size renderData.texture |> Coord.tuple |> Coord.toVec2

        viewBounds3 =
            BoundingBox2d.extrema viewBounds_

        ( minXOffset, minYOffset ) =
            Coord.tuple ( -2, -2 ) |> Units.cellToTile |> Tuple.mapBoth Quantity.toFloatQuantity Quantity.toFloatQuantity

        gridViewBounds : BoundingBox2d WorldUnit WorldUnit
        gridViewBounds =
            BoundingBox2d.fromExtrema
                { minX = viewBounds3.minX |> Quantity.plus minXOffset
                , minY = viewBounds3.minY |> Quantity.plus minYOffset
                , maxX = viewBounds3.maxX
                , maxY = viewBounds3.maxY
                }

        meshes : Dict ( Int, Int ) { foreground : Mesh Vertex, background : Mesh Vertex }
        meshes =
            Dict.filter
                (\key _ ->
                    Coord.tuple key
                        |> Units.cellToTile
                        |> Coord.toPoint2d
                        |> (\p -> BoundingBox2d.contains p gridViewBounds)
                )
                model.meshes
    in
    (if isFirstDraw then
        []

     else
        [ Shaders.clearDepth renderData.scissors ]
    )
        ++ Shaders.drawBackground renderData meshes
        ++ drawForeground renderData model.contextMenu model.currentTool hoverAt2 meshes
        ++ Shaders.drawWaterReflection renderData model
        ++ (case
                ( Maybe.andThen Effect.WebGL.Texture.unwrap model.trainTexture
                , Maybe.andThen Effect.WebGL.Texture.unwrap model.trainLightsTexture
                , Maybe.andThen Effect.WebGL.Texture.unwrap model.trainDepthTexture
                )
            of
                ( Just trainTexture, Just trainLights, Just trainDepth ) ->
                    Train.draw
                        { lights = trainLights
                        , texture = trainTexture
                        , depth = trainDepth
                        , nightFactor = getNightFactor model
                        , viewMatrix =
                            Mat4.makeScale3 (toFloat model.zoomFactor * 2 / toFloat windowWidth) (toFloat model.zoomFactor * -2 / toFloat windowHeight) 1
                                |> Mat4.translate3
                                    (negate <| toFloat <| round (x * toFloat Units.tileWidth))
                                    (negate <| toFloat <| round (y * toFloat Units.tileHeight))
                                    0
                        , staticViewMatrix = renderData.staticViewMatrix
                        , time = shaderTime model
                        , scissors = renderData.scissors
                        }
                        (case model.contextMenu of
                            Just contextMenu ->
                                contextMenu.userId

                            Nothing ->
                                Nothing
                        )
                        model.time
                        localGrid.mail
                        model.trains
                        viewBounds_

                _ ->
                    []
           )
        ++ drawAnimals renderData model
        ++ drawFlags renderData model
        ++ [ Effect.WebGL.entityWith
                [ Shaders.blend, Shaders.scissorBox renderData.scissors ]
                Shaders.debrisVertexShader
                Shaders.fragmentShader
                model.debrisMesh
                { view = renderData.viewMatrix
                , texture = renderData.texture
                , lights = renderData.lights
                , depth = renderData.depth
                , textureSize = textureSize
                , time = renderData.time
                , time2 = renderData.time
                , color = Vec4.vec4 1 1 1 1
                , night = renderData.nightFactor
                }
           , drawReports renderData model.reportsMesh
           ]
        ++ drawOtherCursors renderData model
        ++ Train.drawSpeechBubble renderData model.time model.trains


drawReports : RenderData -> Effect.WebGL.Mesh Vertex -> Effect.WebGL.Entity
drawReports { nightFactor, lights, texture, viewMatrix, depth } reportsMesh =
    Effect.WebGL.entityWith
        [ Shaders.blend ]
        Shaders.vertexShader
        Shaders.fragmentShader
        reportsMesh
        { view = viewMatrix
        , texture = texture
        , lights = lights
        , depth = depth
        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
        , color = Vec4.vec4 1 1 1 1
        , userId = Shaders.noUserIdSelected
        , time = 0
        , night = nightFactor
        }


drawAnimals : RenderData -> FrontendLoaded -> List Effect.WebGL.Entity
drawAnimals { nightFactor, lights, texture, viewMatrix, depth, time, scissors } model =
    let
        localGrid : LocalGrid_
        localGrid =
            LocalGrid.localModel model.localModel

        viewBounds_ : BoundingBox2d WorldUnit WorldUnit
        viewBounds_ =
            viewBoundingBox model

        ( textureW, textureH ) =
            WebGL.Texture.size texture
    in
    List.filterMap
        (\( cowId, animal ) ->
            case animalActualPosition cowId model of
                Just { position } ->
                    if BoundingBox2d.contains position viewBounds_ then
                        let
                            point =
                                Point2d.unwrap position

                            ( sizeW, sizeH ) =
                                Coord.toTuple animalData.size

                            animalData =
                                Animal.getData animal.animalType
                        in
                        Effect.WebGL.entityWith
                            [ Shaders.blend, Shaders.scissorBox scissors ]
                            Shaders.instancedVertexShader
                            Shaders.fragmentShader
                            Train.instancedMesh
                            { view = viewMatrix
                            , texture = texture
                            , lights = lights
                            , depth = depth
                            , textureSize = Vec2.vec2 (toFloat textureW) (toFloat textureH)
                            , color = Vec4.vec4 1 1 1 1
                            , userId = Shaders.noUserIdSelected
                            , time = time
                            , opacityAndUserId0 = Sprite.opaque
                            , position0 =
                                Vec3.vec3
                                    (toFloat Units.tileWidth * point.x - toFloat (sizeW // 2) |> round |> toFloat)
                                    (toFloat Units.tileHeight * point.y - toFloat (sizeH // 2) |> round |> toFloat)
                                    0
                            , primaryColor0 = Color.toInt Color.white |> toFloat
                            , secondaryColor0 = Color.toInt Color.black |> toFloat
                            , size0 = Vec2.vec2 (toFloat sizeW) (toFloat sizeH)
                            , texturePosition0 =
                                Coord.xRaw animalData.texturePosition
                                    + textureW
                                    * Coord.yRaw animalData.texturePosition
                                    |> toFloat
                            , night = nightFactor
                            }
                            |> Just

                    else
                        Nothing

                Nothing ->
                    Nothing
        )
        (IdDict.toList localGrid.animals)


drawFlags : RenderData -> FrontendLoaded -> List Effect.WebGL.Entity
drawFlags { nightFactor, lights, texture, viewMatrix, depth, time, scissors } model =
    List.filterMap
        (\flag ->
            let
                flagMesh2 =
                    if flag.isReceived then
                        Flag.receivingMailFlagMeshes

                    else
                        Flag.sendingMailFlagMeshes
            in
            case
                Array.get
                    (Effect.Time.posixToMillis model.time |> toFloat |> (*) 0.005 |> round |> modBy 3)
                    flagMesh2
            of
                Just flagMesh_ ->
                    let
                        flagPosition =
                            Point2d.unwrap flag.position
                    in
                    Effect.WebGL.entityWith
                        [ Shaders.blend, Shaders.scissorBox scissors ]
                        Shaders.vertexShader
                        Shaders.fragmentShader
                        flagMesh_
                        { view =
                            Mat4.makeTranslate3
                                (flagPosition.x * toFloat Units.tileWidth)
                                (flagPosition.y * toFloat Units.tileHeight)
                                0
                                |> Mat4.mul viewMatrix
                        , texture = texture
                        , lights = lights
                        , depth = depth
                        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                        , color = Vec4.vec4 1 1 1 1
                        , userId = Shaders.noUserIdSelected
                        , time = time
                        , night = nightFactor
                        }
                        |> Just

                Nothing ->
                    Nothing
        )
        (getFlags model)


drawTilePlacer : RenderData -> AudioData -> FrontendLoaded -> List Effect.WebGL.Entity
drawTilePlacer { nightFactor, lights, viewMatrix, texture, depth, time } audioData model =
    let
        textureSize =
            WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
    in
    case ( hoverAt model (LoadingPage.mouseScreenPosition model), LocalGrid.currentTool model, LocalGrid.currentUserId model ) of
        ( MapHover, TilePlacerTool currentTile, Just userId ) ->
            let
                currentTile2 : Tile
                currentTile2 =
                    Toolbar.getTileGroupTile currentTile.tileGroup currentTile.index

                mousePosition : Coord WorldUnit
                mousePosition =
                    LoadingPage.mouseWorldPosition model
                        |> Coord.floorPoint
                        |> Coord.minus (tileSize |> Coord.divide (Coord.tuple ( 2, 2 )))

                ( mouseX, mouseY ) =
                    Coord.toTuple mousePosition

                tileSize =
                    Tile.getData currentTile2 |> .size

                offsetX : Float
                offsetX =
                    case model.lastTilePlaced of
                        Just lastPlacedTile ->
                            let
                                timeElapsed =
                                    Duration.from lastPlacedTile.time model.time
                            in
                            if
                                (timeElapsed
                                    |> Quantity.lessThan (Sound.length audioData model.sounds EraseSound)
                                )
                                    && (lastPlacedTile.tile == EmptyTile)
                            then
                                timeElapsed
                                    |> Duration.inSeconds
                                    |> (*) 40
                                    |> cos
                                    |> (*) 2

                            else
                                lastPlacementOffset audioData model

                        Nothing ->
                            lastPlacementOffset audioData model
            in
            [ Effect.WebGL.entityWith
                [ Shaders.blend ]
                Shaders.vertexShader
                Shaders.fragmentShader
                currentTile.mesh
                { view =
                    viewMatrix
                        |> Mat4.translate3
                            (toFloat mouseX * toFloat Units.tileWidth + offsetX)
                            (toFloat mouseY * toFloat Units.tileHeight)
                            0
                , texture = texture
                , lights = lights
                , depth = depth
                , textureSize = textureSize
                , color =
                    if currentTile.tileGroup == EmptyTileGroup then
                        Vec4.vec4 1 1 1 1

                    else if
                        LoadingPage.canPlaceTile
                            model.time
                            { position = mousePosition
                            , change = currentTile2
                            , userId = userId
                            , colors =
                                { primaryColor = Color.rgb255 0 0 0
                                , secondaryColor = Color.rgb255 255 255 255
                                }
                            , time = model.time
                            }
                            model.trains
                            (LocalGrid.localModel model.localModel |> .grid)
                    then
                        Vec4.vec4 1 1 1 0.5

                    else
                        Vec4.vec4 1 0 0 0.5
                , userId = Shaders.noUserIdSelected
                , time = time
                , night = nightFactor
                }
            ]

        ( MapHover, TextTool (Just textTool), Just userId ) ->
            [ Effect.WebGL.entityWith
                [ Shaders.blend ]
                Shaders.vertexShader
                Shaders.fragmentShader
                Cursor.textCursorMesh2
                { view =
                    Coord.translateMat4
                        (Coord.multiply Units.tileSize textTool.cursorPosition)
                        viewMatrix
                , texture = texture
                , lights = lights
                , depth = depth
                , textureSize = textureSize
                , color =
                    if
                        LoadingPage.canPlaceTile
                            model.time
                            { position = textTool.cursorPosition
                            , change = BigText 'A'
                            , userId = userId
                            , colors =
                                { primaryColor = Color.rgb255 0 0 0
                                , secondaryColor = Color.rgb255 255 255 255
                                }
                            , time = model.time
                            }
                            model.trains
                            (LocalGrid.localModel model.localModel |> .grid)
                    then
                        Vec4.vec4 0 0 0 0.5

                    else
                        Vec4.vec4 1 0 0 0.5
                , userId = Shaders.noUserIdSelected
                , time = time
                , night = nightFactor
                }
            ]

        _ ->
            []


drawMap : FrontendLoaded -> List Effect.WebGL.Entity
drawMap model =
    case ( model.page, Effect.WebGL.Texture.unwrap model.simplexNoiseLookup ) of
        ( WorldPage worldPage, Just simplexNoiseLookup ) ->
            if worldPage.showMap then
                let
                    grid : Grid
                    grid =
                        LocalGrid.localModel model.localModel |> .grid

                    viewPoint =
                        Toolbar.actualViewPoint model |> Point2d.unwrap

                    mapSize : Int
                    mapSize =
                        Toolbar.mapSize model.windowSize

                    ( windowWidth, windowHeight ) =
                        Coord.toTuple model.windowSize |> Tuple.mapBoth toFloat toFloat

                    settings =
                        [ Effect.WebGL.Settings.scissor
                            ((windowWidth - toFloat mapSize) / 2 |> floor)
                            ((windowHeight - toFloat mapSize) / 2 |> floor)
                            mapSize
                            mapSize
                        , Shaders.blend
                        ]

                    mapTerrainSize =
                        Quantity.unwrap Shaders.mapSize

                    mapTerrainSizeChunks =
                        mapTerrainSize // 4 + 1
                in
                Effect.WebGL.entityWith
                    []
                    Shaders.worldMapVertexShader
                    Shaders.worldMapFragmentShader
                    Shaders.mapSquare
                    { view =
                        Mat4.makeScale3 (toFloat mapSize * 2 / windowWidth) (toFloat mapSize * -2 / windowHeight) 1
                            |> Mat4.translate3 -0.5 -0.5 -0.5
                    , texture = simplexNoiseLookup
                    , cellPosition =
                        Toolbar.actualViewPoint model
                            |> Grid.worldToCellPoint
                            |> Point2d.unwrap
                            |> Vec2.fromRecord
                    }
                    :: List.map
                        (\index ->
                            let
                                x =
                                    4 * modBy mapTerrainSizeChunks index + floor (viewPoint.x / 16) - 2 * mapTerrainSizeChunks

                                y =
                                    4 * (index // mapTerrainSizeChunks) + floor (viewPoint.y / 16) - 2 * mapTerrainSizeChunks

                                getMapPixelData : Int -> Int -> Vec2
                                getMapPixelData x2 y2 =
                                    case Grid.getCell (Coord.xy (x2 + x) (y2 + y)) grid of
                                        Just cell ->
                                            GridCell.mapPixelData cell

                                        Nothing ->
                                            Vec2.vec2 0 0
                            in
                            Effect.WebGL.entityWith
                                settings
                                Shaders.worldMapOverlayVertexShader
                                Shaders.worldMapOverlayFragmentShader
                                mapOverlayMesh
                                { view =
                                    Mat4.makeScale3
                                        (toFloat mapSize * 2 / (mapTerrainSize * windowWidth))
                                        (toFloat mapSize * -2 / (mapTerrainSize * windowHeight))
                                        1
                                        |> Mat4.translate3
                                            (-viewPoint.x / 16 + toFloat x)
                                            (-viewPoint.y / 16 + toFloat y)
                                            0
                                , pixelData_0_0 = getMapPixelData 0 0
                                , pixelData_1_0 = getMapPixelData 1 0
                                , pixelData_2_0 = getMapPixelData 2 0
                                , pixelData_3_0 = getMapPixelData 3 0
                                , pixelData_0_1 = getMapPixelData 0 1
                                , pixelData_1_1 = getMapPixelData 1 1
                                , pixelData_2_1 = getMapPixelData 2 1
                                , pixelData_3_1 = getMapPixelData 3 1
                                , pixelData_0_2 = getMapPixelData 0 2
                                , pixelData_1_2 = getMapPixelData 1 2
                                , pixelData_2_2 = getMapPixelData 2 2
                                , pixelData_3_2 = getMapPixelData 3 2
                                , pixelData_0_3 = getMapPixelData 0 3
                                , pixelData_1_3 = getMapPixelData 1 3
                                , pixelData_2_3 = getMapPixelData 2 3
                                , pixelData_3_3 = getMapPixelData 3 3
                                }
                        )
                        (List.range 0 (mapTerrainSizeChunks * mapTerrainSizeChunks - 1))

            else
                []

        _ ->
            []


mapOverlayMesh : Effect.WebGL.Mesh MapOverlayVertex
mapOverlayMesh =
    let
        size =
            16
    in
    List.range 0 (size * size - 1)
        |> List.concatMap
            (\index ->
                let
                    offset : Vec2
                    offset =
                        Vec2.vec2 (toFloat (modBy size index)) (toFloat (index // size))
                in
                [ { position = Vec2.vec2 0 0
                  , offset = offset
                  }
                , { position = Vec2.vec2 1 0
                  , offset = offset
                  }
                , { position = Vec2.vec2 1 1
                  , offset = offset
                  }
                , { position = Vec2.vec2 0 1
                  , offset = offset
                  }
                ]
            )
        |> Sprite.toMesh


lastPlacementOffset : AudioData -> FrontendLoaded -> Float
lastPlacementOffset audioData model =
    case model.lastPlacementError of
        Just time ->
            let
                timeElapsed =
                    Duration.from time model.time
            in
            if
                timeElapsed
                    |> Quantity.lessThan (Sound.length audioData model.sounds ErrorSound)
            then
                timeElapsed
                    |> Duration.inSeconds
                    |> (*) 40
                    |> cos
                    |> (*) 2

            else
                0

        Nothing ->
            0


drawOtherCursors : RenderData -> FrontendLoaded -> List Effect.WebGL.Entity
drawOtherCursors { nightFactor, lights, texture, viewMatrix, depth, time, scissors } model =
    let
        localGrid =
            LocalGrid.localModel model.localModel

        viewBounds_ : BoundingBox2d WorldUnit WorldUnit
        viewBounds_ =
            viewBoundingBox model |> BoundingBox2d.expandBy (Units.tileUnit 2)
    in
    (case LocalGrid.currentUserId model of
        Just userId ->
            IdDict.remove userId localGrid.cursors

        Nothing ->
            localGrid.cursors
    )
        |> IdDict.toList
        |> List.filterMap
            (\( userId, cursor ) ->
                let
                    cursorPosition2 =
                        cursorActualPosition False userId cursor model

                    point : { x : Float, y : Float }
                    point =
                        Point2d.unwrap cursorPosition2
                in
                case ( BoundingBox2d.contains cursorPosition2 viewBounds_, IdDict.get userId model.handMeshes ) of
                    ( True, Just mesh ) ->
                        Effect.WebGL.entityWith
                            [ Shaders.blend, Shaders.scissorBox scissors ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            (Cursor.getSpriteMesh
                                (case cursor.holdingCow of
                                    Just _ ->
                                        PinchSpriteCursor

                                    Nothing ->
                                        Cursor.fromOtherUsersTool cursor.currentTool
                                )
                                mesh
                            )
                            { view =
                                Mat4.makeTranslate3
                                    (round (point.x * toFloat Units.tileWidth * toFloat model.zoomFactor)
                                        |> toFloat
                                        |> (*) (1 / toFloat model.zoomFactor)
                                    )
                                    (round (point.y * toFloat Units.tileHeight * toFloat model.zoomFactor)
                                        |> toFloat
                                        |> (*) (1 / toFloat model.zoomFactor)
                                    )
                                    0
                                    |> Mat4.mul viewMatrix
                            , texture = texture
                            , lights = lights
                            , depth = depth
                            , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                            , color = Vec4.vec4 1 1 1 1
                            , userId = Shaders.noUserIdSelected
                            , time = time
                            , night = nightFactor
                            }
                            |> Just

                    _ ->
                        Nothing
            )


drawCursor :
    RenderData
    -> { cursorType : CursorType, scale : Int }
    -> Id UserId
    -> FrontendLoaded
    -> List Effect.WebGL.Entity
drawCursor { nightFactor, lights, texture, viewMatrix, depth, time } showMousePointer userId model =
    case IdDict.get userId (LocalGrid.localModel model.localModel).cursors of
        Just cursor ->
            case showMousePointer.cursorType of
                CursorSprite mousePointer ->
                    let
                        point =
                            cursorActualPosition True userId cursor model
                                |> Point2d.unwrap
                    in
                    case IdDict.get userId model.handMeshes of
                        Just mesh ->
                            let
                                scale =
                                    toFloat showMousePointer.scale
                            in
                            [ Effect.WebGL.entityWith
                                [ Shaders.blend ]
                                Shaders.vertexShader
                                Shaders.fragmentShader
                                (Cursor.getSpriteMesh mousePointer mesh)
                                { view =
                                    Mat4.makeTranslate3
                                        (round (point.x * toFloat Units.tileWidth * toFloat model.zoomFactor)
                                            |> toFloat
                                            |> (*) (1 / toFloat model.zoomFactor)
                                        )
                                        (round (point.y * toFloat Units.tileHeight * toFloat model.zoomFactor)
                                            |> toFloat
                                            |> (*) (1 / toFloat model.zoomFactor)
                                        )
                                        0
                                        |> Mat4.scale3 scale scale 1
                                        |> Mat4.mul viewMatrix
                                , texture = texture
                                , lights = lights
                                , depth = depth
                                , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                                , color = Vec4.vec4 1 1 1 1
                                , userId = Shaders.noUserIdSelected
                                , time = time
                                , night = nightFactor
                                }
                            ]

                        Nothing ->
                            []

                _ ->
                    []

        Nothing ->
            []


cursorActualPosition : Bool -> Id UserId -> Cursor -> FrontendLoaded -> Point2d WorldUnit WorldUnit
cursorActualPosition isCurrentUser userId cursor model =
    if isCurrentUser then
        cursor.position

    else
        case ( cursor.currentTool, IdDict.get userId model.previousCursorPositions ) of
            ( Cursor.TextTool (Just textTool), _ ) ->
                Coord.toPoint2d textTool.cursorPosition
                    |> Point2d.translateBy (Vector2d.unsafe { x = 0, y = 0.5 })

            ( _, Just previous ) ->
                Point2d.interpolateFrom
                    previous.position
                    cursor.position
                    (Quantity.ratio
                        (Duration.from previous.time model.time)
                        shortDelayDuration
                        |> clamp 0 1
                    )

            _ ->
                cursor.position


getFlags : FrontendLoaded -> List { position : Point2d WorldUnit WorldUnit, isReceived : Bool }
getFlags model =
    let
        localModel =
            LocalGrid.localModel model.localModel

        hasMailWaitingPickup : Id UserId -> Bool
        hasMailWaitingPickup userId =
            MailEditor.getMailFrom userId localModel.mail
                |> List.filter (\( _, mail ) -> mail.status == MailWaitingPickup)
                |> List.isEmpty
                |> not

        hasReceivedNewMail : Id UserId -> Bool
        hasReceivedNewMail userId =
            MailEditor.getMailTo userId localModel.mail
                |> List.filter
                    (\( _, mail ) ->
                        case mail.status of
                            MailReceived _ ->
                                True

                            _ ->
                                False
                    )
                |> List.isEmpty
                |> not
    in
    Bounds.coordRangeFold
        (\coord postOffices ->
            case Grid.getCell coord localModel.grid of
                Just cell ->
                    List.concatMap
                        (\tile ->
                            (if hasMailWaitingPickup tile.userId then
                                [ { position =
                                        Grid.cellAndLocalCoordToWorld ( coord, tile.position )
                                            |> Coord.toPoint2d
                                            |> Point2d.translateBy Flag.postOfficeSendingMailFlagOffset
                                  , isReceived = False
                                  }
                                ]

                             else
                                []
                            )
                                ++ (if hasReceivedNewMail tile.userId then
                                        [ { position =
                                                Grid.cellAndLocalCoordToWorld ( coord, tile.position )
                                                    |> Coord.toPoint2d
                                                    |> Point2d.translateBy Flag.postOfficeReceivedMailFlagOffset
                                          , isReceived = True
                                          }
                                        ]

                                    else
                                        []
                                   )
                        )
                        (GridCell.getPostOffices cell)
                        ++ postOffices

                Nothing ->
                    postOffices
        )
        identity
        localModel.viewBounds
        []


drawForeground :
    RenderData
    -> Maybe ContextMenu
    -> Tool
    -> Hover
    -> Dict ( Int, Int ) { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    -> List Effect.WebGL.Entity
drawForeground { nightFactor, lights, viewMatrix, texture, depth, time, scissors } maybeContextMenu currentTool2 hoverAt2 meshes =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                Effect.WebGL.entityWith
                    [ Effect.WebGL.Settings.cullFace Effect.WebGL.Settings.back
                    , Shaders.depthTest
                    , Shaders.blend
                    , Shaders.scissorBox scissors
                    ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    mesh.foreground
                    { view = viewMatrix
                    , texture = texture
                    , lights = lights
                    , depth = depth
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , color = Vec4.vec4 1 1 1 1
                    , userId =
                        case maybeContextMenu of
                            Just contextMenu ->
                                case contextMenu.userId of
                                    Just userId ->
                                        Id.toInt userId |> toFloat

                                    Nothing ->
                                        -3

                            Nothing ->
                                case currentTool2 of
                                    ReportTool ->
                                        case hoverAt2 of
                                            TileHover { userId } ->
                                                Id.toInt userId |> toFloat

                                            _ ->
                                                -3

                                    _ ->
                                        -3
                    , time = time
                    , night = nightFactor
                    }
            )


shortDelayDuration : Duration
shortDelayDuration =
    Duration.milliseconds 100


subscriptions : AudioData -> FrontendModel_ -> Subscription FrontendOnly FrontendMsg_
subscriptions _ model =
    Subscription.batch
        [ Ports.gotDevicePixelRatio GotDevicePixelRatio
        , Effect.Browser.Events.onResize (\width height -> WindowResized (Coord.xy width height))
        , Effect.Browser.Events.onAnimationFrame AnimationFrame
        , Keyboard.downs KeyDown
        , Ports.readFromClipboardResponse PastedText
        , case model of
            Loading _ ->
                Subscription.batch
                    [ Subscription.fromJs
                        "user_agent_from_js"
                        Ports.user_agent_from_js
                        (\value ->
                            Json.Decode.decodeValue Json.Decode.string value
                                |> Result.withDefault ""
                                |> GotUserAgentPlatform
                        )
                    , Ports.gotWebGlFix GotWebGlFix
                    ]

            Loaded loaded ->
                Subscription.batch
                    [ Subscription.map KeyMsg Keyboard.subscriptions
                    , Effect.Time.every
                        shortDelayDuration
                        (\time -> Duration.addTo time (PingData.pingOffset loaded) |> ShortIntervalElapsed)
                    , Effect.Browser.Events.onVisibilityChange (\_ -> VisibilityChanged)
                    ]
        , Subscription.fromJs "mouse_leave" Ports.mouse_leave (\_ -> MouseLeave)
        , Ports.gotLocalStorage LoadedUserSettings
        ]


animalActualPosition : Id AnimalId -> FrontendLoaded -> Maybe { position : Point2d WorldUnit WorldUnit, isHeld : Bool }
animalActualPosition animalId model =
    let
        localGrid =
            LocalGrid.localModel model.localModel
    in
    case
        IdDict.toList localGrid.cursors
            |> List.find (\( _, cursor ) -> Just animalId == Maybe.map .cowId cursor.holdingCow)
    of
        Just ( userId, cursor ) ->
            { position =
                cursorActualPosition (Just userId == LocalGrid.currentUserId model) userId cursor model
                    |> Point2d.translateBy (Vector2d.unsafe { x = 0, y = 0.2 })
            , isHeld = True
            }
                |> Just

        Nothing ->
            case IdDict.get animalId localGrid.animals of
                Just animal ->
                    Just { position = animal.position, isHeld = False }

                Nothing ->
                    Nothing
