module Frontend exposing
    ( app
    , app_
    , init
    , update
    , updateFromBackend
    , view
    )

import Array exposing (Array)
import AssocList
import Audio exposing (Audio, AudioCmd, AudioData)
import BoundingBox2d exposing (BoundingBox2d)
import Bounds exposing (Bounds)
import Browser
import Change exposing (Change(..), Cow, UserStatus(..))
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cow
import Cursor exposing (Cursor, CursorMeshes, CursorSprite(..), CursorType(..))
import Dict exposing (Dict)
import DisplayName
import Duration exposing (Duration)
import Effect.Browser.Dom
import Effect.Browser.Events exposing (Visibility(..))
import Effect.Browser.Navigation
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Effect.WebGL exposing (Shader)
import Effect.WebGL.Settings
import Effect.WebGL.Settings.DepthTest
import Effect.WebGL.Texture exposing (Texture)
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
import Id exposing (CowId, Id, TrainId, UserId)
import IdDict exposing (IdDict)
import Image
import Json.Decode
import Json.Encode
import Keyboard
import Keyboard.Arrows
import Lamdera
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import LocalGrid exposing (LocalGrid, LocalGrid_)
import LocalModel exposing (LocalModel)
import MailEditor exposing (FrontendMail, MailStatus(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector4 as Vec4
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Ports
import Quantity exposing (Quantity(..), Rate)
import Random
import Route
import Set exposing (Set)
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound(..))
import Sprite
import Terrain
import TextInput exposing (OutMsg(..))
import Tile exposing (CollisionMask(..), DefaultColor(..), RailPathType(..), Tile(..), TileData, TileGroup(..))
import Time
import Toolbar
import Train exposing (Status(..), Train)
import Types exposing (..)
import Ui exposing (UiEvent)
import Units exposing (CellUnit, MailPixelUnit, TileLocalUnit, WorldUnit)
import Untrusted
import Url exposing (Url)
import Url.Parser exposing ((<?>))
import Vector2d exposing (Vector2d)
import WebGL.Texture


app =
    Effect.Lamdera.frontend Lamdera.sendToBackend app_


app_ =
    Audio.lamderaFrontendWithAudio
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \audioData msg model -> update audioData msg model |> (\( a, b ) -> ( a, b, Audio.cmdNone ))
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

        movingTrains : List { playbackRate : Float, volume : Float }
        movingTrains =
            List.filterMap
                (\( _, train ) ->
                    let
                        trainSpeed =
                            Train.speed model.time train
                    in
                    if Quantity.abs trainSpeed |> Quantity.lessThan Train.stoppedSpeed then
                        Nothing

                    else
                        let
                            position =
                                Train.trainPosition model.time train
                        in
                        Just
                            { playbackRate = 0.9 * (abs (Quantity.unwrap trainSpeed) / Train.defaultMaxSpeed) + 0.1
                            , volume = volume model position * Quantity.unwrap trainSpeed / Train.defaultMaxSpeed |> abs
                            }
                )
                (IdDict.toList model.trains)

        mailEditorVolumeScale : Float
        mailEditorVolumeScale =
            clamp
                0
                1
                (case ( model.lastMailEditorToggle, model.mailEditor ) of
                    ( Just time, Nothing ) ->
                        Quantity.ratio (Duration.from time model.time) MailEditor.openAnimationLength

                    ( Just time, Just _ ) ->
                        1 - Quantity.ratio (Duration.from time model.time) MailEditor.openAnimationLength

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
    , case model.mailEditor of
        Just mailEditor ->
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

        Nothing ->
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
    , case currentUserId model of
        Just userId ->
            case IdDict.get userId localModel.cursors of
                Just cursor ->
                    case cursor.holdingCow of
                        Just { pickupTime } ->
                            playSound
                                (Random.step
                                    (Random.weighted
                                        ( 1 / 6, Moo0 )
                                        [ ( 1 / 6, Moo1 )
                                        , ( 1 / 12, Moo2 )
                                        , ( 1 / 12, Moo3 )
                                        , ( 1 / 6, Moo4 )
                                        , ( 1 / 6, Moo5 )
                                        , ( 1 / 6, Moo6 )
                                        ]
                                    )
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
    ]
        |> Audio.group
        |> Audio.scaleVolumeAt [ ( model.startTime, 0 ), ( Duration.addTo model.startTime Duration.second, 1 ) ]


volume : FrontendLoaded -> Point2d WorldUnit WorldUnit -> Float
volume model position =
    let
        boundingBox =
            viewBoundingBox model
    in
    if BoundingBox2d.contains position boundingBox then
        1

    else
        let
            extrema =
                BoundingBox2d.extrema boundingBox

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


maxVolumeDistance =
    10


tryLoading : FrontendLoading -> Maybe (() -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ ))
tryLoading frontendLoading =
    case frontendLoading.localModel of
        LoadingLocalModel _ ->
            Nothing

        LoadedLocalModel loadedLocalModel ->
            Maybe.map3
                (\time texture simplexNoiseLookup () ->
                    loadedInit time frontendLoading texture simplexNoiseLookup loadedLocalModel
                )
                frontendLoading.time
                frontendLoading.texture
                frontendLoading.simplexNoiseLookup


defaultTileHotkeys : Dict String TileGroup
defaultTileHotkeys =
    Dict.fromList
        [ ( " ", EmptyTileGroup )
        , ( "1", HouseGroup )
        , ( "q", LogCabinGroup )
        , ( "a", ApartmentGroup )
        , ( "2", HospitalGroup )
        , ( "w", PostOfficeGroup )
        , ( "s", StatueGroup )
        , ( "3", RailStraightGroup )
        , ( "e", RailTurnGroup )
        , ( "d", RailTurnLargeGroup )
        , ( "4", RailStrafeGroup )
        , ( "r", RailStrafeSmallGroup )
        , ( "f", RailCrossingGroup )
        , ( "5", TrainHouseGroup )
        , ( "t", SidewalkGroup )
        , ( "g", SidewalkRailGroup )
        , ( "6", RailTurnSplitGroup )
        , ( "y", RailTurnSplitMirrorGroup )
        , ( "h", RoadStraightGroup )
        , ( "7", RoadTurnGroup )
        , ( "u", Road4WayGroup )
        , ( "j", RoadSidewalkCrossingGroup )
        , ( "8", Road3WayGroup )
        , ( "i", RoadRailCrossingGroup )
        , ( "k", RoadDeadendGroup )
        , ( "9", BusStopGroup )
        , ( "o", FenceStraightGroup )
        , ( "l", HedgeRowGroup )
        , ( "0", HedgeCornerGroup )
        , ( "p", HedgePillarGroup )
        , ( ";", PineTreeGroup )
        , ( "-", RockGroup )
        , ( "=", FlowersGroup )
        ]


loadedInit :
    Effect.Time.Posix
    -> FrontendLoading
    -> Texture
    -> Texture
    -> LoadedLocalModel_
    -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
loadedInit time loading texture simplexNoiseLookup loadedLocalModel =
    let
        currentTile =
            HandTool

        defaultTileColors =
            AssocList.empty

        currentUserId2 =
            currentUserId loadedLocalModel

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = loadedLocalModel.localModel
            , trains = loadedLocalModel.trains
            , meshes = Dict.empty
            , viewPoint = Coord.toPoint2d loading.viewPoint |> NormalViewPoint
            , viewPointLastInterval = Point2d.origin
            , texture = texture
            , simplexNoiseLookup = simplexNoiseLookup
            , trainTexture = Nothing
            , pressedKeys = []
            , windowSize = loading.windowSize
            , cssWindowSize = loading.cssWindowSize
            , cssCanvasSize = loading.cssCanvasSize
            , devicePixelRatio = loading.devicePixelRatio
            , zoomFactor = loading.zoomFactor
            , mouseLeft = MouseButtonUp { current = loading.mousePosition }
            , mouseMiddle = MouseButtonUp { current = loading.mousePosition }
            , pendingChanges = []
            , undoAddLast = Effect.Time.millisToPosix 0
            , time = time
            , startTime = time
            , adminEnabled = False
            , animationElapsedTime = Duration.seconds 0
            , ignoreNextUrlChanged = False
            , lastTilePlaced = Nothing
            , sounds = loading.sounds
            , musicVolume = loading.musicVolume
            , soundEffectVolume = loading.soundEffectVolume
            , removedTileParticles = []
            , debrisMesh = Shaders.triangleFan []
            , lastTrainWhistle = Nothing
            , mailEditor =
                case ( loading.showInbox, LocalGrid.localModel loadedLocalModel.localModel |> .userStatus ) of
                    ( True, LoggedIn _ ) ->
                        MailEditor.init Nothing |> Just

                    _ ->
                        Nothing
            , lastMailEditorToggle = Nothing
            , currentTool = currentTile
            , lastTileRotation = []
            , lastPlacementError = Nothing
            , tileHotkeys = defaultTileHotkeys
            , ui = Ui.none
            , uiMesh = Shaders.triangleFan []
            , previousTileHover = Nothing
            , lastHouseClick = Nothing
            , eventIdCounter = Id.fromInt 0
            , pingData = Nothing
            , pingStartTime = Just time
            , localTime = time
            , scrollThreshold = 0
            , tileColors = defaultTileColors
            , primaryColorTextInput = TextInput.init
            , secondaryColorTextInput = TextInput.init
            , focus = Nothing
            , previousFocus = Nothing
            , music =
                { startTime = Duration.addTo time (Duration.seconds 10)
                , sound =
                    Random.step
                        (Sound.nextSong Nothing)
                        (Random.initialSeed (Time.posixToMillis time))
                        |> Tuple.first
                }
            , previousCursorPositions = IdDict.empty
            , handMeshes =
                LocalGrid.localModel loadedLocalModel.localModel
                    |> .users
                    |> IdDict.map
                        (\userId user ->
                            Cursor.meshes
                                (if currentUserId2 == Just userId then
                                    Nothing

                                 else
                                    Just ( userId, user.name )
                                )
                                user.handColor
                        )
            , hasCmdKey = loading.hasCmdKey
            , loginTextInput = TextInput.init
            , pressedSubmitEmail = NotSubmitted { pressedSubmit = False }
            , topMenuOpened = Nothing
            , inviteTextInput = TextInput.init
            , inviteSubmitStatus = NotSubmitted { pressedSubmit = False }
            , railToggles = []
            , debugText = ""
            , lastReceivedMail = Nothing
            , isReconnecting = False
            , lastCheckConnection = time
            , showMap = False
            , showInviteTree = False
            , selectedUserId = Nothing
            }
                |> setCurrentTool HandToolButton
    in
    ( updateMeshes model model
    , Command.batch
        [ Effect.WebGL.Texture.loadWith
            { magnify = Effect.WebGL.Texture.nearest
            , minify = Effect.WebGL.Texture.nearest
            , horizontalWrap = Effect.WebGL.Texture.clampToEdge
            , verticalWrap = Effect.WebGL.Texture.clampToEdge
            , flipY = False
            }
            "/trains.png"
            |> Effect.Task.attempt TrainTextureLoaded
        , Effect.Lamdera.sendToBackend PingRequest
        ]
    )
        |> viewBoundsUpdate
        |> Tuple.mapFirst Loaded


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
        , Effect.WebGL.Texture.loadWith
            { magnify = Effect.WebGL.Texture.nearest
            , minify = Effect.WebGL.Texture.nearest
            , horizontalWrap = Effect.WebGL.Texture.clampToEdge
            , verticalWrap = Effect.WebGL.Texture.clampToEdge
            , flipY = False
            }
            "/texture.png"
            |> Effect.Task.attempt TextureLoaded
        , Effect.Task.attempt SimplexLookupTextureLoaded loadSimplexTexture
        , Ports.getLocalStorage
        ]
    , Sound.load SoundLoaded
    )


loadSimplexTexture : Effect.Task.Task FrontendOnly Effect.WebGL.Texture.Error Texture
loadSimplexTexture =
    let
        table =
            Terrain.permutationTable

        {- Copied from Simplex.grad3 -}
        grad3 : List Int
        grad3 =
            [ 1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1, 0, 1, 0, 1, -1, 0, 1, 1, 0, -1, -1, 0, -1, 0, 1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1 ]
                |> List.map (\a -> a + 1)
    in
    Effect.WebGL.Texture.loadWith
        { magnify = Effect.WebGL.Texture.nearest
        , minify = Effect.WebGL.Texture.nearest
        , horizontalWrap = Effect.WebGL.Texture.clampToEdge
        , verticalWrap = Effect.WebGL.Texture.clampToEdge
        , flipY = False
        }
        (Image.fromList2d
            [ Array.toList table.perm
            , Array.toList table.permMod12
            , grad3 ++ List.repeat (512 - List.length grad3) 0
            ]
            |> Image.toPngUrl
        )


update : AudioData -> FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
update audioData msg model =
    case model of
        Loading loadingModel ->
            case msg of
                WindowResized windowSize ->
                    windowResizedUpdate windowSize loadingModel |> Tuple.mapFirst Loading

                GotDevicePixelRatio devicePixelRatio ->
                    devicePixelRatioChanged devicePixelRatio loadingModel
                        |> Tuple.mapFirst Loading

                SoundLoaded sound result ->
                    ( Loading { loadingModel | sounds = AssocList.insert sound result loadingModel.sounds }, Command.none )

                TextureLoaded result ->
                    case result of
                        Ok texture ->
                            ( Loading { loadingModel | texture = Just texture }, Command.none )

                        Err _ ->
                            ( model, Command.none )

                SimplexLookupTextureLoaded result ->
                    case result of
                        Ok texture ->
                            ( Loading { loadingModel | simplexNoiseLookup = Just texture }, Command.none )

                        Err _ ->
                            ( model, Command.none )

                MouseMove mousePosition ->
                    ( Loading { loadingModel | mousePosition = mousePosition }, Command.none )

                MouseUp MainButton mousePosition ->
                    if insideStartButton mousePosition loadingModel then
                        case tryLoading loadingModel of
                            Just a ->
                                a ()

                            Nothing ->
                                ( model, Command.none )

                    else
                        ( model, Command.none )

                KeyDown rawKey ->
                    case Keyboard.anyKeyOriginal rawKey of
                        Just Keyboard.Enter ->
                            case tryLoading loadingModel of
                                Just a ->
                                    a ()

                                Nothing ->
                                    ( model, Command.none )

                        _ ->
                            ( model, Command.none )

                AnimationFrame time ->
                    ( Loading { loadingModel | time = Just time }, Command.none )

                GotUserAgentPlatform userAgentPlatform ->
                    ( Loading { loadingModel | hasCmdKey = String.startsWith "mac" (String.toLower userAgentPlatform) }
                    , Command.none
                    )

                LoadedUserSettings userSettings ->
                    ( Loading
                        { loadingModel
                            | musicVolume = userSettings.musicVolume
                            , soundEffectVolume = userSettings.soundEffectVolume
                        }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        Loaded frontendLoaded ->
            updateLoaded audioData msg frontendLoaded
                |> (\( newModel, cmd ) ->
                        ( if mouseWorldPosition newModel == mouseWorldPosition frontendLoaded then
                            newModel

                          else
                            removeLastCursorMove newModel
                                |> updateLocalModel (Change.MoveCursor (mouseWorldPosition newModel))
                                |> Tuple.first
                        , cmd
                        )
                   )
                |> (\( newModel, cmd ) ->
                        let
                            toolToCursorTool tool =
                                case tool of
                                    HandTool ->
                                        Cursor.HandTool

                                    TilePlacerTool { tileGroup } ->
                                        if tileGroup == EmptyTileGroup then
                                            Cursor.EraserTool

                                        else
                                            Cursor.TilePlacerTool

                                    TilePickerTool ->
                                        Cursor.TilePickerTool

                                    TextTool (Just textTool) ->
                                        Cursor.TextTool (Just { cursorPosition = textTool.cursorPosition })

                                    TextTool Nothing ->
                                        Cursor.TextTool Nothing

                            newTool : Cursor.OtherUsersTool
                            newTool =
                                currentTool newModel |> toolToCursorTool
                        in
                        ( if toolToCursorTool (currentTool frontendLoaded) == newTool then
                            newModel

                          else
                            updateLocalModel (Change.ChangeTool newTool) newModel |> Tuple.first
                        , cmd
                        )
                   )
                |> Tuple.mapFirst (updateMeshes frontendLoaded)
                |> viewBoundsUpdate
                |> Tuple.mapFirst Loaded


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

        SimplexLookupTextureLoaded _ ->
            ( model, Command.none )

        KeyMsg keyMsg ->
            ( { model | pressedKeys = Keyboard.update keyMsg model.pressedKeys }, Command.none )

        KeyDown rawKey ->
            case Keyboard.anyKeyOriginal rawKey of
                Just key ->
                    case model.mailEditor of
                        Just mailEditor ->
                            ( case MailEditor.handleKeyDown model.time (ctrlOrMeta model) key mailEditor of
                                Just ( newMailEditor, outMsg ) ->
                                    { model
                                        | mailEditor = Just newMailEditor
                                        , lastMailEditorToggle = model.lastMailEditorToggle
                                    }
                                        |> handleMailEditorOutMsg outMsg

                                Nothing ->
                                    { model
                                        | mailEditor = Nothing
                                        , lastMailEditorToggle = Just model.time
                                    }
                            , Command.none
                            )

                        Nothing ->
                            case ( model.focus, key ) of
                                ( _, Keyboard.Tab ) ->
                                    ( setFocus
                                        (if keyDown Keyboard.Shift model then
                                            previousFocus model

                                         else
                                            nextFocus model
                                        )
                                        model
                                    , Command.none
                                    )

                                ( Just id, _ ) ->
                                    uiUpdate id (Ui.KeyDown key) model

                                _ ->
                                    keyMsgCanvasUpdate key model

                Nothing ->
                    ( model, Command.none )

        WindowResized windowSize ->
            windowResizedUpdate windowSize model

        GotDevicePixelRatio devicePixelRatio ->
            devicePixelRatioChanged devicePixelRatio model

        MouseDown button mousePosition ->
            let
                hover =
                    hoverAt model mousePosition

                mousePosition2 : Coord Pixels
                mousePosition2 =
                    mousePosition
                        |> Coord.roundPoint
            in
            if button == MainButton then
                { model
                    | mouseLeft =
                        MouseButtonDown
                            { start = mousePosition
                            , start_ = screenToWorld model mousePosition
                            , current = mousePosition
                            , hover = hover
                            }
                }
                    |> (\model2 ->
                            case hover of
                                MapHover ->
                                    case currentTool model2 of
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
                                                    mouseWorldPosition model
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

                                UiHover id data ->
                                    uiUpdate
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
                            , start_ = screenToWorld model mousePosition
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
                    mainMouseButtonUp mousePosition previousMouseState model

                ( MiddleButton, _, MouseButtonDown mouseState ) ->
                    ( { model
                        | mouseMiddle = MouseButtonUp { current = mousePosition }
                        , viewPoint =
                            case model.mailEditor of
                                Just _ ->
                                    model.viewPoint

                                Nothing ->
                                    offsetViewPoint model mouseState.hover mouseState.start mousePosition |> NormalViewPoint
                      }
                    , Command.none
                    )

                ( SecondButton, _, _ ) ->
                    let
                        maybeTile =
                            Grid.getTile
                                (screenToWorld model mousePosition |> Coord.floorPoint)
                                (LocalGrid.localModel model.localModel).grid
                    in
                    ( { model
                        | selectedUserId =
                            case maybeTile of
                                Just tile ->
                                    Just tile.userId

                                Nothing ->
                                    Nothing
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
            in
            ( if abs scrollThreshold > 50 then
                case model.mailEditor of
                    Just mailEditor ->
                        { model
                            | mailEditor =
                                MailEditor.scroll (scrollThreshold > 0) audioData model mailEditor |> Just
                        }

                    Nothing ->
                        if ctrlOrMeta model then
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

              else
                { model | scrollThreshold = scrollThreshold }
            , Command.none
            )

        MouseLeave ->
            case model.mouseLeft of
                MouseButtonDown mouseState ->
                    mainMouseButtonUp (mouseScreenPosition model) mouseState model

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
                    case currentTool model2 of
                        TilePlacerTool { tileGroup, index } ->
                            placeTile True tileGroup index model2

                        HandTool ->
                            model2

                        TilePickerTool ->
                            model2

                        TextTool _ ->
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
                                        uiUpdate uiHover (Ui.MouseMove { elementPosition = data.position }) model2

                                    CowHover _ ->
                                        ( placeTileHelper model2, Command.none )

                            _ ->
                                ( model2, Command.none )
                   )

        ShortIntervalElapsed time ->
            let
                actualViewPoint_ =
                    actualViewPoint model

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

        ZoomFactorPressed zoomFactor ->
            ( model |> (\m -> { m | zoomFactor = zoomFactor }), Command.none )

        ToggleAdminEnabledPressed ->
            ( if currentUserId model == Env.adminUserId then
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
                    actualViewPoint model

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

                                        SendEmailButtonHover ->
                                            True

                                        PrimaryColorInput ->
                                            False

                                        SecondaryColorInput ->
                                            False

                                        ToolButtonHover _ ->
                                            True

                                        ShowInviteUser ->
                                            True

                                        CloseInviteUser ->
                                            True

                                        SubmitInviteUser ->
                                            True

                                        InviteEmailAddressTextInput ->
                                            False

                                        LowerMusicVolume ->
                                            True

                                        RaiseMusicVolume ->
                                            True

                                        LowerSoundEffectVolume ->
                                            True

                                        RaiseSoundEffectVolume ->
                                            True

                                        SettingsButton ->
                                            True

                                        CloseSettings ->
                                            True

                                        DisplayNameTextInput ->
                                            False

                                        MailEditorHover _ ->
                                            False

                                        YouGotMailButton ->
                                            True

                                        ShowMapButton ->
                                            True

                                        AllowEmailNotificationsCheckbox ->
                                            True

                                        ResetConnectionsButton ->
                                            True

                                        UsersOnlineButton ->
                                            True

                                Nothing ->
                                    True

                model2 =
                    { model
                        | time = time
                        , localTime = localTime
                        , animationElapsedTime = Duration.from model.time time |> Quantity.plus model.animationElapsedTime
                        , trains =
                            IdDict.map
                                (\trainId train ->
                                    Train.moveTrain
                                        trainId
                                        Train.defaultMaxSpeed
                                        model.time
                                        time
                                        { grid = localGrid.grid, mail = IdDict.empty }
                                        train
                                )
                                model.trains
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

                newUi =
                    Toolbar.view model3
            in
            ( { model3
                | ui = newUi
                , previousFocus = model3.focus
                , uiMesh =
                    if Ui.visuallyEqual newUi model3.ui && model3.focus == model3.previousFocus then
                        model3.uiMesh

                    else
                        Ui.view model3.focus newUi
              }
            , Command.none
            )

        SoundLoaded sound result ->
            ( { model | sounds = AssocList.insert sound result model.sounds }, Command.none )

        VisibilityChanged ->
            ( setCurrentTool HandToolButton { model | pressedKeys = [] }, Command.none )

        TrainTextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | trainTexture = Just texture }, Command.none )

                Err _ ->
                    ( model, Command.none )

        PastedText text ->
            case model.focus of
                Just id ->
                    uiUpdate id (Ui.PastedText text) model

                Nothing ->
                    pasteTextTool text model

        GotUserAgentPlatform _ ->
            ( model, Command.none )

        LoadedUserSettings userSettings ->
            ( { model | musicVolume = userSettings.musicVolume, soundEffectVolume = userSettings.soundEffectVolume }
            , Command.none
            )


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
                        (getTileColor tile.tileGroup model)
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
                (ctrlOrMeta model)
                (keyDown Keyboard.Shift model)
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
                    ( updateLocalModel
                        (updateColor color (getHandColor userId model) |> Change.ChangeHandColor)
                        model
                        |> handleOutMsg False
                    , Command.none
                    )

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
                                                (getTileColor currentTile.tileGroup m)
                                                |> Sprite.toMesh
                                        }
                                            |> TilePlacerTool

                                    HandTool ->
                                        m.currentTool

                                    TilePickerTool ->
                                        m.currentTool

                                    TextTool record ->
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
                    screenToWorld model mousePosition

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
                                    if ctrlOrMeta model then
                                        TileHover tile |> Just

                                    else
                                        Nothing

                                TextTool _ ->
                                    if ctrlOrMeta model then
                                        TileHover tile |> Just

                                    else
                                        Nothing

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

                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel

                cowHovers : Maybe ( Id CowId, Cow )
                cowHovers =
                    case model.currentTool of
                        TilePlacerTool _ ->
                            Nothing

                        TilePickerTool ->
                            Nothing

                        HandTool ->
                            IdDict.toList localGrid.cows
                                |> List.filter
                                    (\( cowId, _ ) ->
                                        case cowActualPosition cowId model of
                                            Just a ->
                                                if a.isHeld then
                                                    False

                                                else
                                                    Cow.insideCow mouseWorldPosition_ a.position

                                            Nothing ->
                                                False
                                    )
                                |> Quantity.maximumBy (\( _, cow ) -> Point2d.yCoordinate cow.position)

                        TextTool _ ->
                            Nothing
            in
            case trainHovers of
                Just ( train, _ ) ->
                    TrainHover train

                Nothing ->
                    case cowHovers of
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


ctrlOrMeta : { a | pressedKeys : List Keyboard.Key } -> Bool
ctrlOrMeta model =
    keyDown Keyboard.Control model || keyDown Keyboard.Meta model


keyMsgCanvasUpdate : Keyboard.Key -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
keyMsgCanvasUpdate key model =
    case ( key, ctrlOrMeta model ) of
        ( Keyboard.Character "z", True ) ->
            ( updateLocalModel Change.LocalUndo model |> Tuple.first, Command.none )

        ( Keyboard.Character "Z", True ) ->
            ( updateLocalModel Change.LocalRedo model |> Tuple.first, Command.none )

        ( Keyboard.Character "y", True ) ->
            ( updateLocalModel Change.LocalRedo model |> Tuple.first, Command.none )

        ( Keyboard.Escape, _ ) ->
            if model.showMap then
                ( { model | showMap = False }, Command.none )

            else
                ( case model.currentTool of
                    TilePlacerTool _ ->
                        setCurrentTool HandToolButton model

                    TilePickerTool ->
                        setCurrentTool HandToolButton model

                    HandTool ->
                        case isHoldingCow model of
                            Just { cowId } ->
                                updateLocalModel (Change.DropCow cowId (mouseWorldPosition model) model.time) model
                                    |> Tuple.first

                            Nothing ->
                                { model
                                    | viewPoint =
                                        case model.viewPoint of
                                            TrainViewPoint _ ->
                                                actualViewPoint model |> NormalViewPoint

                                            NormalViewPoint _ ->
                                                model.viewPoint
                                }

                    TextTool (Just _) ->
                        setCurrentTool TextToolButton model

                    TextTool Nothing ->
                        setCurrentTool HandToolButton model
                , Command.none
                )

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
                    setTileFromHotkey " " model

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

                _ ->
                    setTileFromHotkey string model

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
                                actualViewPoint model
                                    |> Point2d.translateBy (Coord.toVector2d offset)
                                    |> NormalViewPoint
                    }

                Nothing ->
                    { model
                        | viewPoint =
                            actualViewPoint model
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


setTileFromHotkey : String -> FrontendLoaded -> ( FrontendLoaded, Command restriction toMsg msg )
setTileFromHotkey string model =
    ( case Dict.get string model.tileHotkeys of
        Just tile ->
            setCurrentTool (TilePlacerToolButton tile) model

        Nothing ->
            model
    , Command.none
    )


getTileColor : TileGroup -> { a | tileColors : AssocList.Dict TileGroup Colors } -> Colors
getTileColor tileGroup model =
    case AssocList.get tileGroup model.tileColors of
        Just a ->
            a

        Nothing ->
            Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary


setCurrentTool : ToolButton -> FrontendLoaded -> FrontendLoaded
setCurrentTool tool model =
    let
        colors =
            case tool of
                TilePlacerToolButton tileGroup ->
                    getTileColor tileGroup model

                HandToolButton ->
                    case currentUserId model of
                        Just userId ->
                            getHandColor userId model

                        Nothing ->
                            Cursor.defaultColors

                TilePickerToolButton ->
                    { primaryColor = Color.white, secondaryColor = Color.black }

                TextToolButton ->
                    getTileColor BigTextGroup model
    in
    setCurrentToolWithColors tool colors model


setCurrentToolWithColors : ToolButton -> Colors -> FrontendLoaded -> FrontendLoaded
setCurrentToolWithColors tool colors model =
    { model
        | currentTool =
            case tool of
                TilePlacerToolButton tileGroup ->
                    TilePlacerTool
                        { tileGroup = tileGroup
                        , index = 0
                        , mesh = Grid.tileMesh (Toolbar.getTileGroupTile tileGroup 0) Coord.origin 1 colors |> Sprite.toMesh
                        }

                HandToolButton ->
                    HandTool

                TilePickerToolButton ->
                    TilePickerTool

                TextToolButton ->
                    TextTool Nothing
        , primaryColorTextInput = TextInput.init |> TextInput.withText (Color.toHexCode colors.primaryColor)
        , secondaryColorTextInput = TextInput.init |> TextInput.withText (Color.toHexCode colors.secondaryColor)
        , tileColors =
            case tool of
                TilePlacerToolButton tileGroup ->
                    AssocList.insert tileGroup colors model.tileColors

                HandToolButton ->
                    model.tileColors

                TilePickerToolButton ->
                    model.tileColors

                TextToolButton ->
                    AssocList.insert BigTextGroup colors model.tileColors
    }


isHoldingCow : FrontendLoaded -> Maybe { cowId : Id CowId, pickupTime : Effect.Time.Posix }
isHoldingCow model =
    let
        localGrid =
            LocalGrid.localModel model.localModel
    in
    case currentUserId model of
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
        handleTrainHouse : Maybe (() -> ( FrontendLoaded, Command FrontendOnly ToBackend frontendMsg ))
        handleTrainHouse =
            case
                IdDict.toList model.trains
                    |> List.find (\( _, train ) -> Train.home train == position)
            of
                Just ( trainId, train ) ->
                    case Train.status model.time train of
                        WaitingAtHome ->
                            Just (\() -> ( clickLeaveHomeTrain trainId model, Command.none ))

                        _ ->
                            Just (\() -> ( clickTeleportHomeTrain trainId model, Command.none ))

                Nothing ->
                    Nothing

        handleRailSplit =
            Just
                (\() ->
                    ( updateLocalModel (Change.ToggleRailSplit position) model |> handleOutMsg False, Command.none )
                )
    in
    case tile of
        PostOffice ->
            case canOpenMailEditor model of
                Just drafts ->
                    (\() ->
                        if currentUserId2 == userId then
                            ( { model
                                | mailEditor = MailEditor.init Nothing |> Just
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
                                        | mailEditor =
                                            MailEditor.init
                                                (Just
                                                    { userId = userId
                                                    , name = user.name
                                                    , draft = IdDict.get userId drafts |> Maybe.withDefault []
                                                    }
                                                )
                                                |> Just
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

        _ ->
            Nothing


mainMouseButtonUp :
    Point2d Pixels Pixels
    -> { a | start : Point2d Pixels Pixels, hover : Hover }
    -> FrontendLoaded
    -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
mainMouseButtonUp mousePosition previousMouseState model =
    let
        isSmallDistance2 =
            isSmallDistance previousMouseState mousePosition

        hoverAt2 : Hover
        hoverAt2 =
            hoverAt model mousePosition

        model2 =
            { model
                | mouseLeft = MouseButtonUp { current = mousePosition }
                , viewPoint =
                    case ( model.mailEditor, model.mouseMiddle ) of
                        ( Nothing, MouseButtonUp _ ) ->
                            case model.currentTool of
                                TilePlacerTool _ ->
                                    model.viewPoint

                                HandTool ->
                                    offsetViewPoint
                                        model
                                        previousMouseState.hover
                                        previousMouseState.start
                                        mousePosition
                                        |> NormalViewPoint

                                TilePickerTool ->
                                    offsetViewPoint
                                        model
                                        previousMouseState.hover
                                        previousMouseState.start
                                        mousePosition
                                        |> NormalViewPoint

                                TextTool _ ->
                                    model.viewPoint

                        _ ->
                            model.viewPoint
            }
                |> (\m ->
                        if isSmallDistance2 then
                            setFocus (getUiHover hoverAt2) m

                        else
                            m
                   )
    in
    if isSmallDistance2 then
        case isHoldingCow model2 of
            Just { cowId } ->
                let
                    ( model3, _ ) =
                        updateLocalModel (Change.DropCow cowId (mouseWorldPosition model2) model2.time) model2
                in
                ( model3, Command.none )

            Nothing ->
                case hoverAt2 of
                    UiBackgroundHover ->
                        ( model2, Command.none )

                    TileHover data ->
                        case currentUserId model2 of
                            Just userId ->
                                case currentTool model2 of
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
                                                    Just tileGroup ->
                                                        setCurrentToolWithColors (TilePlacerToolButton tileGroup) colors model2

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

                            Nothing ->
                                ( model2, Command.none )

                    TrainHover { trainId, train } ->
                        case Train.status model.time train of
                            WaitingAtHome ->
                                ( clickLeaveHomeTrain trainId model2, Command.none )

                            TeleportingHome _ ->
                                ( model2, Command.none )

                            _ ->
                                case Train.isStuck model2.time train of
                                    Just stuckTime ->
                                        if Duration.from stuckTime model2.time |> Quantity.lessThan stuckMessageDelay then
                                            ( setTrainViewPoint trainId model2, Command.none )

                                        else
                                            ( clickTeleportHomeTrain trainId model2, Command.none )

                                    Nothing ->
                                        ( setTrainViewPoint trainId model2, Command.none )

                    MapHover ->
                        ( case previousMouseState.hover of
                            TrainHover { trainId, train } ->
                                setTrainViewPoint trainId model2

                            _ ->
                                model2
                        , Command.none
                        )

                    CowHover { cowId } ->
                        let
                            ( model3, _ ) =
                                updateLocalModel (Change.PickupCow cowId (mouseWorldPosition model2) model2.time) model2
                        in
                        ( model3, Command.none )

                    UiHover id data ->
                        uiUpdate
                            id
                            (Ui.MousePressed { elementPosition = data.position })
                            model2

    else
        ( model2, Command.none )


handleMailEditorOutMsg : MailEditor.OutMsg -> FrontendLoaded -> FrontendLoaded
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


onPress event updateFunc model =
    case event of
        Ui.MousePressed data ->
            updateFunc data

        Ui.KeyDown key ->
            keyMsgCanvasUpdate key model

        _ ->
            ( model, Command.none )


uiUpdate : UiHover -> UiEvent -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
uiUpdate id event model =
    case id of
        CloseInviteUser ->
            onPress event (\_ -> ( { model | topMenuOpened = Nothing }, Command.none )) model

        ShowInviteUser ->
            onPress event (\_ -> ( { model | topMenuOpened = Just InviteMenu }, Command.none )) model

        SubmitInviteUser ->
            onPress event (\_ -> sendInvite model) model

        SendEmailButtonHover ->
            onPress event (\_ -> sendEmail model) model

        ToolButtonHover tool ->
            onPress event (\_ -> ( setCurrentTool tool model, Command.none )) model

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
                                (mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.primaryColorTextInput
                      }
                    , Command.none
                    )

                Ui.MouseDown { elementPosition } ->
                    ( { model
                        | primaryColorTextInput =
                            TextInput.mouseDown
                                (mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.primaryColorTextInput
                      }
                        |> setFocus (Just PrimaryColorInput)
                    , Command.none
                    )

                Ui.KeyDown Keyboard.Escape ->
                    ( setFocus Nothing model, Command.none )

                Ui.KeyDown key ->
                    case currentUserId model of
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
                    case currentUserId model of
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
                                (mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.secondaryColorTextInput
                      }
                    , Command.none
                    )

                Ui.MouseDown { elementPosition } ->
                    ( { model
                        | secondaryColorTextInput =
                            TextInput.mouseDown
                                (mouseScreenPosition model |> Coord.roundPoint)
                                elementPosition
                                model.secondaryColorTextInput
                      }
                        |> setFocus (Just SecondaryColorInput)
                    , Command.none
                    )

                Ui.KeyDown Keyboard.Escape ->
                    ( setFocus Nothing model, Command.none )

                Ui.KeyDown key ->
                    case currentUserId model of
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
                    case currentUserId model of
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
                event
                (\_ -> { model | musicVolume = model.musicVolume - 1 |> max 0 } |> saveUserSettings)
                model

        RaiseMusicVolume ->
            onPress
                event
                (\_ -> { model | musicVolume = model.musicVolume + 1 |> min Sound.maxVolume } |> saveUserSettings)
                model

        LowerSoundEffectVolume ->
            onPress
                event
                (\_ -> { model | soundEffectVolume = model.soundEffectVolume - 1 |> max 0 } |> saveUserSettings)
                model

        RaiseSoundEffectVolume ->
            onPress
                event
                (\_ -> { model | soundEffectVolume = model.soundEffectVolume + 1 |> min Sound.maxVolume } |> saveUserSettings)
                model

        SettingsButton ->
            onPress
                event
                (\_ ->
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

                                NotLoggedIn ->
                                    Just LoggedOutSettingsMenu
                      }
                    , Command.none
                    )
                )
                model

        CloseSettings ->
            onPress event (\_ -> ( { model | topMenuOpened = Nothing }, Command.none )) model

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
                            handleOutMsg False ( model2, outMsg2 )
                        )
                        (\_ -> ( model, Command.none ))
                        nameTextInput
                        (\a -> { model | topMenuOpened = Just (SettingsMenu a) })
                        event
                        model

                _ ->
                    ( model, Command.none )

        MailEditorHover mailEditorId ->
            case model.mailEditor of
                Just mailEditor ->
                    let
                        ( newMailEditor, outMsg ) =
                            MailEditor.uiUpdate
                                model
                                (mouseScreenPosition model |> Coord.roundPoint)
                                mailEditorId
                                event
                                mailEditor

                        model2 =
                            { model
                                | mailEditor = newMailEditor
                                , lastMailEditorToggle =
                                    if newMailEditor == Nothing then
                                        Just model.time

                                    else
                                        model.lastMailEditorToggle
                            }
                    in
                    ( handleMailEditorOutMsg outMsg model2
                    , Command.none
                    )

                Nothing ->
                    ( model, Command.none )

        YouGotMailButton ->
            onPress event (\_ -> ( model, Effect.Lamdera.sendToBackend PostOfficePositionRequest )) model

        ShowMapButton ->
            onPress event (\_ -> ( { model | showMap = not model.showMap }, Command.none )) model

        AllowEmailNotificationsCheckbox ->
            onPress
                event
                (\_ ->
                    ( case LocalGrid.localModel model.localModel |> .userStatus of
                        LoggedIn loggedIn ->
                            updateLocalModel
                                (Change.SetAllowEmailNotifications (not loggedIn.allowEmailNotifications))
                                model
                                |> handleOutMsg False

                        NotLoggedIn ->
                            model
                    , Command.none
                    )
                )
                model

        ResetConnectionsButton ->
            onPress
                event
                (\_ -> ( updateLocalModel Change.AdminResetSessions model |> handleOutMsg False, Command.none ))
                model

        UsersOnlineButton ->
            onPress event (\_ -> ( { model | showInviteTree = not model.showInviteTree }, Command.none )) model


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
                (mouseScreenPosition model |> Coord.roundPoint)
                elementPosition
                textInput
                |> setTextInput
                |> setFocus (Just id)
            , Command.none
            )

        Ui.KeyDown Keyboard.Escape ->
            ( setFocus Nothing model, Command.none )

        Ui.KeyDown Keyboard.Enter ->
            onEnter ()

        Ui.KeyDown key ->
            let
                ( newTextInput, outMsg ) =
                    TextInput.keyMsg
                        (ctrlOrMeta model)
                        (keyDown Keyboard.Shift model)
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
            case currentUserId model of
                Just userId ->
                    if isPrimaryColorInput model.focus && not (isPrimaryColorInput newFocus) then
                        case model.currentTool of
                            TilePlacerTool { tileGroup } ->
                                model.primaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (getTileColor tileGroup model).primaryColor)

                            TilePickerTool ->
                                model.primaryColorTextInput

                            HandTool ->
                                TextInput.withText
                                    (Color.toHexCode (getHandColor userId model).primaryColor)
                                    model.primaryColorTextInput

                            TextTool _ ->
                                model.primaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (getTileColor BigTextGroup model).primaryColor)

                    else if not (isPrimaryColorInput model.focus) && isPrimaryColorInput newFocus then
                        TextInput.selectAll model.primaryColorTextInput

                    else
                        model.primaryColorTextInput

                Nothing ->
                    model.primaryColorTextInput
        , secondaryColorTextInput =
            case currentUserId model of
                Just userId ->
                    if isSecondaryColorInput model.focus && not (isSecondaryColorInput newFocus) then
                        case model.currentTool of
                            TilePlacerTool { tileGroup } ->
                                model.secondaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (getTileColor tileGroup model).secondaryColor)

                            TilePickerTool ->
                                model.secondaryColorTextInput

                            HandTool ->
                                TextInput.withText
                                    (Color.toHexCode (getHandColor userId model).secondaryColor)
                                    model.secondaryColorTextInput

                            TextTool _ ->
                                model.secondaryColorTextInput
                                    |> TextInput.withText (Color.toHexCode (getTileColor BigTextGroup model).secondaryColor)

                    else if not (isSecondaryColorInput model.focus) && isSecondaryColorInput newFocus then
                        TextInput.selectAll model.secondaryColorTextInput

                    else
                        model.secondaryColorTextInput

                Nothing ->
                    model.secondaryColorTextInput
    }


clickLeaveHomeTrain : Id TrainId -> FrontendLoaded -> FrontendLoaded
clickLeaveHomeTrain trainId model =
    updateLocalModel (Change.LeaveHomeTrainRequest trainId model.time) model
        |> handleOutMsg False


clickTeleportHomeTrain : Id TrainId -> FrontendLoaded -> FrontendLoaded
clickTeleportHomeTrain trainId model =
    updateLocalModel (Change.TeleportHomeTrainRequest trainId model.time) model
        |> handleOutMsg False


setTrainViewPoint : Id TrainId -> FrontendLoaded -> FrontendLoaded
setTrainViewPoint trainId model =
    { model
        | viewPoint =
            TrainViewPoint
                { trainId = trainId
                , startViewPoint = actualViewPoint model
                , startTime = model.time
                }
    }


canOpenMailEditor : FrontendLoaded -> Maybe (IdDict UserId (List MailEditor.Content))
canOpenMailEditor model =
    case ( model.mailEditor, model.currentTool, LocalGrid.localModel model.localModel |> .userStatus ) of
        ( Nothing, HandTool, LoggedIn loggedIn ) ->
            Just loggedIn.mailDrafts

        _ ->
            Nothing


updateLocalModel : Change.LocalChange -> FrontendLoaded -> ( FrontendLoaded, LocalGrid.OutMsg )
updateLocalModel msg model =
    case LocalGrid.localModel model.localModel |> .userStatus of
        LoggedIn _ ->
            let
                ( newLocalModel, outMsg ) =
                    LocalGrid.update (LocalChange model.eventIdCounter msg) model.localModel
            in
            ( { model
                | pendingChanges = ( model.eventIdCounter, msg ) :: model.pendingChanges
                , localModel = newLocalModel
                , eventIdCounter = Id.increment model.eventIdCounter
              }
            , outMsg
            )

        NotLoggedIn ->
            ( model, LocalGrid.NoOutMsg )


screenToWorld : FrontendLoaded -> Point2d Pixels Pixels -> Point2d WorldUnit WorldUnit
screenToWorld model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> point2dAt2 (scaleForScreenToWorld model)
        >> Point2d.placeIn (Units.screenFrame (actualViewPoint model))


worldToScreen : FrontendLoaded -> Point2d WorldUnit WorldUnit -> Point2d Pixels Pixels
worldToScreen model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5 |> Vector2d.reverse)
        << point2dAt2_ (scaleForScreenToWorld model)
        << Point2d.relativeTo (Units.screenFrame (actualViewPoint model))


vector2dAt2 :
    ( Quantity Float (Rate sourceUnits destinationUnits)
    , Quantity Float (Rate sourceUnits destinationUnits)
    )
    -> Vector2d sourceUnits coordinates
    -> Vector2d destinationUnits coordinates
vector2dAt2 ( Quantity rateX, Quantity rateY ) vector =
    let
        { x, y } =
            Vector2d.unwrap vector
    in
    { x = x * rateX
    , y = y * rateY
    }
        |> Vector2d.unsafe


point2dAt2 :
    ( Quantity Float (Rate sourceUnits destinationUnits)
    , Quantity Float (Rate sourceUnits destinationUnits)
    )
    -> Point2d sourceUnits coordinates
    -> Point2d destinationUnits coordinates
point2dAt2 ( Quantity rateX, Quantity rateY ) point =
    let
        { x, y } =
            Point2d.unwrap point
    in
    { x = x * rateX
    , y = y * rateY
    }
        |> Point2d.unsafe


point2dAt2_ :
    ( Quantity Float (Rate sourceUnits destinationUnits)
    , Quantity Float (Rate sourceUnits destinationUnits)
    )
    -> Point2d sourceUnits coordinates
    -> Point2d destinationUnits coordinates
point2dAt2_ ( Quantity rateX, Quantity rateY ) point =
    let
        { x, y } =
            Point2d.unwrap point
    in
    { x = x / rateX
    , y = y / rateY
    }
        |> Point2d.unsafe


scaleForScreenToWorld : { a | devicePixelRatio : Float, zoomFactor : Int } -> ( Quantity Float units, Quantity Float units )
scaleForScreenToWorld model =
    ( 1 / (toFloat model.zoomFactor * toFloat Units.tileWidth) |> Quantity
    , 1 / (toFloat model.zoomFactor * toFloat Units.tileHeight) |> Quantity
    )


windowResizedUpdate :
    Coord CssPixel
    -> { b | cssWindowSize : Coord CssPixel, windowSize : Coord Pixels, cssCanvasSize : Coord CssPixel, devicePixelRatio : Float }
    ->
        ( { b | cssWindowSize : Coord CssPixel, windowSize : Coord Pixels, cssCanvasSize : Coord CssPixel, devicePixelRatio : Float }
        , Command FrontendOnly ToBackend msg
        )
windowResizedUpdate cssWindowSize model =
    let
        { cssCanvasSize, windowSize } =
            findPixelPerfectSize2 { devicePixelRatio = model.devicePixelRatio, cssWindowSize = cssWindowSize }
    in
    ( { model | cssWindowSize = cssWindowSize, cssCanvasSize = cssCanvasSize, windowSize = windowSize }
    , Command.sendToJs
        "martinsstewart_elm_device_pixel_ratio_to_js"
        Ports.martinsstewart_elm_device_pixel_ratio_to_js
        Json.Encode.null
    )


devicePixelRatioChanged devicePixelRatio model =
    let
        { cssCanvasSize, windowSize } =
            findPixelPerfectSize2 { devicePixelRatio = devicePixelRatio, cssWindowSize = model.cssWindowSize }
    in
    ( { model | devicePixelRatio = devicePixelRatio, cssCanvasSize = cssCanvasSize, windowSize = windowSize }
    , Command.none
    )


mouseWorldPosition : FrontendLoaded -> Point2d WorldUnit WorldUnit
mouseWorldPosition model =
    mouseScreenPosition model |> screenToWorld model


mouseScreenPosition : { a | mouseLeft : MouseButtonState } -> Point2d Pixels Pixels
mouseScreenPosition model =
    case model.mouseLeft of
        MouseButtonDown { current } ->
            current

        MouseButtonUp { current } ->
            current


cursorPosition : TileData WorldUnit -> FrontendLoaded -> Coord WorldUnit
cursorPosition tileData model =
    mouseWorldPosition model
        |> Coord.floorPoint
        |> Coord.minus (tileData.size |> Coord.divide (Coord.tuple ( 2, 2 )))


placeTile : Bool -> TileGroup -> Int -> FrontendLoaded -> FrontendLoaded
placeTile isDragPlacement tileGroup index model =
    let
        tile =
            Toolbar.getTileGroupTile tileGroup index

        tileData =
            Tile.getData tile
    in
    placeTileAt (cursorPosition tileData model) isDragPlacement tileGroup index model


placeTileAt : Coord WorldUnit -> Bool -> TileGroup -> Int -> FrontendLoaded -> FrontendLoaded
placeTileAt cursorPosition_ isDragPlacement tileGroup index model =
    case currentUserId model of
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
                    getTileColor tileGroup model

                change =
                    { position = cursorPosition_
                    , change = tile
                    , userId = userId
                    , colors = colors
                    }

                grid : Grid
                grid =
                    LocalGrid.localModel model.localModel |> .grid
            in
            if isDragPlacement && hasCollision then
                model

            else if not (canPlaceTile model.time change model.trains grid) then
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
                                }
                            )
                            model2

                    removedTiles : List RemovedTileParticle
                    removedTiles =
                        case outMsg of
                            LocalGrid.TilesRemoved tiles ->
                                List.map
                                    (\removedTile ->
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


canPlaceTile : Effect.Time.Posix -> Grid.GridChange -> IdDict TrainId Train -> Grid -> Bool
canPlaceTile time change trains grid =
    if Grid.canPlaceTile change then
        let
            { removed } =
                Grid.addChange change grid
        in
        case Train.canRemoveTiles time removed trains of
            Ok _ ->
                True

            Err _ ->
                False

    else
        False


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
    List.map
        (\{ position, tile, time, colors } ->
            let
                data =
                    Tile.getData tile
            in
            (case data.texturePosition of
                Just texturePosition ->
                    createDebrisMeshHelper
                        position
                        texturePosition
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

                Nothing ->
                    []
            )
                ++ (case data.texturePositionTopLayer of
                        Just topLayer ->
                            createDebrisMeshHelper
                                position
                                topLayer.texturePosition
                                data.size
                                colors
                                1
                                appStartTime
                                time

                        Nothing ->
                            []
                   )
        )
        list
        |> List.concat
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


keyDown : Keyboard.Key -> { a | pressedKeys : List Keyboard.Key } -> Bool
keyDown key { pressedKeys } =
    List.any ((==) key) pressedKeys


updateMeshes : FrontendLoaded -> FrontendLoaded -> FrontendLoaded
updateMeshes oldModel newModel =
    let
        oldCells : Dict ( Int, Int ) GridCell.Cell
        oldCells =
            LocalGrid.localModel oldModel.localModel |> .grid |> Grid.allCellsDict

        localModel : LocalGrid_
        localModel =
            LocalGrid.localModel newModel.localModel

        newCells : Dict ( Int, Int ) GridCell.Cell
        newCells =
            localModel.grid |> Grid.allCellsDict

        currentTile model =
            case currentTool model of
                TilePlacerTool { tileGroup, index } ->
                    let
                        tile =
                            Toolbar.getTileGroupTile tileGroup index

                        position : Coord WorldUnit
                        position =
                            cursorPosition (Tile.getData tile) model

                        ( cellPosition, localPosition ) =
                            Grid.worldToCellAndLocalCoord position
                    in
                    { tile = tile
                    , position = position
                    , cellPosition =
                        Grid.closeNeighborCells cellPosition localPosition
                            |> List.map Tuple.first
                            |> (::) cellPosition
                            |> List.map Coord.toTuple
                            |> Set.fromList
                    , colors =
                        { primaryColor = Color.rgb255 0 0 0
                        , secondaryColor = Color.rgb255 255 255 255
                        }
                    }
                        |> Just

                HandTool ->
                    Nothing

                TilePickerTool ->
                    Nothing

                TextTool _ ->
                    Nothing

        oldCurrentTile : Maybe { tile : Tile, position : Coord WorldUnit, cellPosition : Set ( Int, Int ), colors : Colors }
        oldCurrentTile =
            currentTile oldModel

        newCurrentTile : Maybe { tile : Tile, position : Coord WorldUnit, cellPosition : Set ( Int, Int ), colors : Colors }
        newCurrentTile =
            currentTile newModel

        currentTileUnchanged : Bool
        currentTileUnchanged =
            oldCurrentTile == newCurrentTile

        newMaybeUserId =
            currentUserId newModel

        newMesh : Maybe (Effect.WebGL.Mesh Vertex) -> GridCell.Cell -> ( Int, Int ) -> { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
        newMesh backgroundMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.tuple rawCoord
            in
            { foreground =
                Grid.foregroundMesh2
                    (case ( newCurrentTile, newMaybeUserId ) of
                        ( Just newCurrentTile_, Just userId ) ->
                            if
                                canPlaceTile
                                    newModel.time
                                    { userId = userId
                                    , position = newCurrentTile_.position
                                    , change = newCurrentTile_.tile
                                    , colors = newCurrentTile_.colors
                                    }
                                    newModel.trains
                                    localModel.grid
                            then
                                newCurrentTile

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    coord
                    newMaybeUserId
                    (LocalGrid.localModel newModel.localModel |> .users)
                    (GridCell.getToggledRailSplit newCell)
                    (GridCell.flatten newCell)
            , background =
                case backgroundMesh of
                    Just background ->
                        background

                    Nothing ->
                        Grid.backgroundMesh coord
            }
    in
    { newModel
        | meshes =
            Dict.map
                (\coord newCell ->
                    case Dict.get coord oldCells of
                        Just oldCell ->
                            if oldCell == newCell then
                                if
                                    ((Maybe.map .cellPosition newCurrentTile
                                        |> Maybe.withDefault Set.empty
                                        |> Set.member coord
                                     )
                                        || (Maybe.map .cellPosition oldCurrentTile
                                                |> Maybe.withDefault Set.empty
                                                |> Set.member coord
                                           )
                                    )
                                        && not currentTileUnchanged
                                then
                                    newMesh (Dict.get coord newModel.meshes |> Maybe.map .background) newCell coord

                                else
                                    case Dict.get coord newModel.meshes of
                                        Just mesh ->
                                            mesh

                                        Nothing ->
                                            newMesh Nothing newCell coord

                            else
                                newMesh (Dict.get coord newModel.meshes |> Maybe.map .background) newCell coord

                        Nothing ->
                            newMesh (Dict.get coord newModel.meshes |> Maybe.map .background) newCell coord
                )
                newCells
    }


getUiHover : Hover -> Maybe UiHover
getUiHover hover =
    case hover of
        UiHover id _ ->
            Just id

        _ ->
            Nothing


loadingCellBounds : FrontendLoaded -> Bounds CellUnit
loadingCellBounds model =
    let
        { minX, minY, maxX, maxY } =
            viewLoadingBoundingBox model |> BoundingBox2d.extrema

        min_ =
            Point2d.xy minX minY |> Coord.floorPoint |> Grid.worldToCellAndLocalCoord |> Tuple.first

        max_ =
            Point2d.xy maxX maxY
                |> Coord.floorPoint
                |> Grid.worldToCellAndLocalCoord
                |> Tuple.first
                |> Coord.plus ( Units.cellUnit 1, Units.cellUnit 1 )

        bounds =
            Bounds.bounds min_ max_
    in
    bounds


viewBoundsUpdate : ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ ) -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
viewBoundsUpdate ( model, cmd ) =
    let
        bounds =
            loadingCellBounds model
    in
    if LocalGrid.localModel model.localModel |> .viewBounds |> Bounds.containsBounds bounds then
        ( model, cmd )

    else
        ( { model
            | localModel =
                LocalGrid.update
                    (ClientChange (Change.ViewBoundsChange bounds [] []))
                    model.localModel
                    |> Tuple.first
          }
        , Command.batch [ cmd, Effect.Lamdera.sendToBackend (ChangeViewBounds bounds) ]
        )


canDragView : Hover -> Bool
canDragView hover =
    case hover of
        TileHover _ ->
            True

        TrainHover _ ->
            True

        UiBackgroundHover ->
            False

        MapHover ->
            True

        CowHover _ ->
            True

        UiHover _ _ ->
            False


offsetViewPoint :
    FrontendLoaded
    -> Hover
    -> Point2d Pixels Pixels
    -> Point2d Pixels Pixels
    -> Point2d WorldUnit WorldUnit
offsetViewPoint model hover mouseStart mouseCurrent =
    if canDragView hover then
        let
            delta : Vector2d WorldUnit WorldUnit
            delta =
                Vector2d.from mouseCurrent mouseStart
                    |> vector2dAt2 (scaleForScreenToWorld model)
                    |> Vector2d.placeIn (Units.screenFrame viewPoint2)

            viewPoint2 =
                actualViewPointHelper model
        in
        Point2d.translateBy delta viewPoint2

    else
        actualViewPointHelper model


actualViewPoint : FrontendLoaded -> Point2d WorldUnit WorldUnit
actualViewPoint model =
    case ( model.mailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( Nothing, _, MouseButtonDown { start, current, hover } ) ->
            offsetViewPoint model hover start current

        ( Nothing, MouseButtonDown { start, current, hover }, _ ) ->
            case model.currentTool of
                TilePlacerTool _ ->
                    actualViewPointHelper model

                TilePickerTool ->
                    offsetViewPoint model hover start current

                HandTool ->
                    offsetViewPoint model hover start current

                TextTool _ ->
                    actualViewPointHelper model

        _ ->
            actualViewPointHelper model


actualViewPointHelper : FrontendLoaded -> Point2d WorldUnit WorldUnit
actualViewPointHelper model =
    case model.viewPoint of
        NormalViewPoint viewPoint ->
            viewPoint

        TrainViewPoint trainViewPoint ->
            case IdDict.get trainViewPoint.trainId model.trains of
                Just train ->
                    let
                        t =
                            Quantity.ratio
                                (Duration.from trainViewPoint.startTime model.time)
                                (Duration.milliseconds 600)
                                |> min 1
                    in
                    Point2d.interpolateFrom trainViewPoint.startViewPoint (Train.trainPosition model.time train) t

                Nothing ->
                    trainViewPoint.startViewPoint


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
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst (updateMeshes loaded) |> Tuple.mapFirst Loaded

        _ ->
            ( model, Command.none )


handleOutMsg : Bool -> ( FrontendLoaded, LocalGrid.OutMsg ) -> FrontendLoaded
handleOutMsg isFromBackend ( model, outMsg ) =
    case outMsg of
        LocalGrid.NoOutMsg ->
            model

        LocalGrid.TilesRemoved _ ->
            model

        LocalGrid.OtherUserCursorMoved { userId, previousPosition } ->
            { model
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

        LocalGrid.HandColorOrNameChanged userId ->
            case LocalGrid.localModel model.localModel |> .users |> IdDict.get userId of
                Just user ->
                    { model
                        | handMeshes =
                            IdDict.insert
                                userId
                                (Cursor.meshes
                                    (if Just userId == currentUserId model then
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

        LocalGrid.RailToggledByAnother position ->
            handleRailToggleSound position model

        LocalGrid.RailToggledBySelf position ->
            if isFromBackend then
                model

            else
                handleRailToggleSound position model

        LocalGrid.TeleportTrainHome trainId ->
            { model | trains = IdDict.update trainId (Maybe.map (Train.startTeleportingHome model.time)) model.trains }

        LocalGrid.TrainLeaveHome trainId ->
            { model | trains = IdDict.update trainId (Maybe.map (Train.leaveHome model.time)) model.trains }

        LocalGrid.TrainsUpdated diff ->
            { model
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

        LocalGrid.ReceivedMail ->
            { model | lastReceivedMail = Just model.time }


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
            ( List.foldl
                (\outMsg state -> handleOutMsg True ( state, outMsg ))
                { model | localModel = newLocalModel }
                outMsgs
            , Command.none
            )

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
                    loadingCellBounds model
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
                loadingCanvasView loadingModel

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


currentUserId : { a | localModel : LocalModel Change LocalGrid } -> Maybe (Id UserId)
currentUserId model =
    case LocalGrid.localModel model.localModel |> .userStatus of
        LoggedIn loggedIn ->
            Just loggedIn.userId

        NotLoggedIn ->
            Nothing


findPixelPerfectSize2 :
    { devicePixelRatio : Float, cssWindowSize : Coord CssPixel }
    -> { cssCanvasSize : Coord CssPixel, windowSize : Coord Pixels }
findPixelPerfectSize2 frontendModel =
    let
        findValue : Quantity Int CssPixel -> ( Int, Int )
        findValue value =
            List.range 0 9
                |> List.map ((+) (Quantity.unwrap value))
                |> List.find
                    (\v ->
                        let
                            a =
                                toFloat v * frontendModel.devicePixelRatio
                        in
                        a == toFloat (round a) && modBy 2 (round a) == 0
                    )
                |> Maybe.map (\v -> ( v, toFloat v * frontendModel.devicePixelRatio |> round ))
                |> Maybe.withDefault ( Quantity.unwrap value, toFloat (Quantity.unwrap value) * frontendModel.devicePixelRatio |> round )

        ( w, actualW ) =
            findValue (Tuple.first frontendModel.cssWindowSize)

        ( h, actualH ) =
            findValue (Tuple.second frontendModel.cssWindowSize)
    in
    { cssCanvasSize = Coord.xy w h, windowSize = Coord.xy actualW actualH }


viewLoadingBoundingBox : FrontendLoaded -> BoundingBox2d WorldUnit WorldUnit
viewLoadingBoundingBox model =
    let
        viewMin =
            screenToWorld model Point2d.origin
                |> Point2d.translateBy
                    (Coord.tuple ( -2, -2 )
                        |> Units.cellToTile
                        |> Coord.toVector2d
                    )

        viewMax =
            screenToWorld model (Coord.toPoint2d model.windowSize)
    in
    BoundingBox2d.from viewMin viewMax


viewBoundingBox : FrontendLoaded -> BoundingBox2d WorldUnit WorldUnit
viewBoundingBox model =
    BoundingBox2d.from (screenToWorld model Point2d.origin) (screenToWorld model (Coord.toPoint2d model.windowSize))


loadingCanvasView : FrontendLoading -> Html FrontendMsg_
loadingCanvasView model =
    let
        ( windowWidth, windowHeight ) =
            Coord.toTuple model.windowSize

        ( cssWindowWidth, cssWindowHeight ) =
            Coord.toTuple model.cssCanvasSize

        loadingTextPosition2 =
            loadingTextPosition model.windowSize

        isHovering =
            insideStartButton model.mousePosition model

        showMousePointer =
            isHovering
    in
    Effect.WebGL.toHtmlWith
        [ Effect.WebGL.alpha False
        , Effect.WebGL.clearColor 1 1 1 1
        , Effect.WebGL.depth 1
        ]
        ([ Html.Attributes.width windowWidth
         , Html.Attributes.height windowHeight
         , Html.Attributes.style "cursor"
            (if showMousePointer then
                "pointer"

             else
                "default"
            )
         , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
         , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
         ]
            ++ mouseListeners model
        )
        (case Maybe.andThen Effect.WebGL.Texture.unwrap model.texture of
            Just texture ->
                let
                    textureSize =
                        WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                in
                Effect.WebGL.entityWith
                    [ Shaders.blend ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    touchDevicesNotSupportedMesh
                    { view =
                        Mat4.makeScale3
                            (2 / toFloat windowWidth)
                            (-2 / toFloat windowHeight)
                            1
                            |> Coord.translateMat4 (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                            |> Coord.translateMat4 (touchDevicesNotSupportedPosition model.windowSize)
                    , texture = texture
                    , textureSize = textureSize
                    , color = Vec4.vec4 1 1 1 1
                    , userId = Shaders.noUserIdSelected
                    , time = 0
                    }
                    :: (case tryLoading model of
                            Just _ ->
                                [ Effect.WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.vertexShader
                                    Shaders.fragmentShader
                                    (if isHovering then
                                        startButtonHighlightMesh

                                     else
                                        startButtonMesh
                                    )
                                    { view =
                                        Mat4.makeScale3
                                            (2 / toFloat windowWidth)
                                            (-2 / toFloat windowHeight)
                                            1
                                            |> Coord.translateMat4 (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                                            |> Coord.translateMat4 loadingTextPosition2
                                    , texture = texture
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    , userId = Shaders.noUserIdSelected
                                    , time = 0
                                    }
                                ]

                            Nothing ->
                                [ Effect.WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.vertexShader
                                    Shaders.fragmentShader
                                    loadingTextMesh
                                    { view =
                                        Mat4.makeScale3
                                            (2 / toFloat windowWidth)
                                            (-2 / toFloat windowHeight)
                                            1
                                            |> Coord.translateMat4
                                                (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                                            |> Coord.translateMat4 (loadingTextPosition model.windowSize)
                                    , texture = texture
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    , userId = Shaders.noUserIdSelected
                                    , time = 0
                                    }
                                ]
                       )

            Nothing ->
                []
        )


insideStartButton : Point2d Pixels Pixels -> { a | devicePixelRatio : Float, windowSize : Coord Pixels } -> Bool
insideStartButton mousePosition model =
    let
        mousePosition2 : Coord Pixels
        mousePosition2 =
            mousePosition
                |> Coord.roundPoint

        loadingTextPosition2 =
            loadingTextPosition model.windowSize
    in
    Bounds.fromCoordAndSize loadingTextPosition2 loadingTextSize |> Bounds.contains mousePosition2


loadingTextPosition : Coord units -> Coord units
loadingTextPosition windowSize =
    windowSize
        |> Coord.divide (Coord.xy 2 2)
        |> Coord.minus (Coord.divide (Coord.xy 2 2) loadingTextSize)


loadingTextSize : Coord units
loadingTextSize =
    Coord.xy 336 54


loadingTextMesh : Effect.WebGL.Mesh Vertex
loadingTextMesh =
    Sprite.text Color.black 2 "Loading..." Coord.origin
        |> Sprite.toMesh


touchDevicesNotSupportedPosition : Coord units -> Coord units
touchDevicesNotSupportedPosition windowSize =
    loadingTextPosition windowSize |> Coord.plus (Coord.yOnly loadingTextSize |> Coord.multiply (Coord.xy 1 2))


touchDevicesNotSupportedMesh : Effect.WebGL.Mesh Vertex
touchDevicesNotSupportedMesh =
    Sprite.text Color.black 2 "(Phones and tablets not supported)" (Coord.xy -170 0)
        |> Sprite.toMesh


startButtonMesh : Effect.WebGL.Mesh Vertex
startButtonMesh =
    Sprite.spriteWithColor
        (Color.rgb255 157 143 134)
        Coord.origin
        loadingTextSize
        (Coord.xy 508 28)
        (Coord.xy 1 1)
        ++ Sprite.sprite
            (Coord.xy 2 2)
            (loadingTextSize |> Coord.minus (Coord.xy 4 4))
            (Coord.xy 507 28)
            (Coord.xy 1 1)
        ++ Sprite.text Color.black 2 "Press to start!" (Coord.xy 16 8)
        |> Sprite.toMesh


startButtonHighlightMesh : Effect.WebGL.Mesh Vertex
startButtonHighlightMesh =
    Sprite.spriteWithColor
        (Color.rgb255 241 231 223)
        Coord.origin
        loadingTextSize
        (Coord.xy 508 28)
        (Coord.xy 1 1)
        ++ Sprite.sprite
            (Coord.xy 2 2)
            (loadingTextSize |> Coord.minus (Coord.xy 4 4))
            (Coord.xy 505 28)
            (Coord.xy 1 1)
        ++ Sprite.text Color.black 2 "Press to start!" (Coord.xy 16 8)
        |> Sprite.toMesh


currentTool : FrontendLoaded -> Tool
currentTool model =
    case currentUserId model of
        Just _ ->
            if ctrlOrMeta model then
                TilePickerTool

            else
                model.currentTool

        Nothing ->
            HandTool


cursorSprite : Hover -> FrontendLoaded -> { cursorType : CursorType, scale : Int }
cursorSprite hover model =
    case currentUserId model of
        Just userId ->
            let
                helper () =
                    case model.mailEditor of
                        Just mailEditor ->
                            case hover of
                                UiHover (MailEditorHover uiHover) _ ->
                                    MailEditor.cursorSprite model.windowSize uiHover mailEditor

                                _ ->
                                    { cursorType = DefaultCursor, scale = 1 }

                        Nothing ->
                            { cursorType =
                                if isHoldingCow model /= Nothing then
                                    CursorSprite PinchSpriteCursor

                                else
                                    case currentTool model of
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
                            , scale = 1
                            }
            in
            case isDraggingView hover model of
                Just mouse ->
                    if isSmallDistance mouse (mouseScreenPosition model) then
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
    case ( model.mailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( Nothing, _, MouseButtonDown a ) ->
            Just a

        ( Nothing, MouseButtonDown a, _ ) ->
            case model.currentTool of
                TilePlacerTool _ ->
                    Nothing

                TilePickerTool ->
                    if canDragView hover then
                        Just a

                    else
                        Nothing

                HandTool ->
                    if canDragView hover then
                        Just a

                    else
                        Nothing

                TextTool _ ->
                    Nothing

        _ ->
            Nothing


getHandColor : Id UserId -> { a | localModel : LocalModel b LocalGrid } -> Colors
getHandColor userId model =
    let
        localGrid : LocalGrid_
        localGrid =
            LocalGrid.localModel model.localModel
    in
    case IdDict.get userId localGrid.users of
        Just { handColor } ->
            handColor

        Nothing ->
            Cursor.defaultColors


mouseListeners : { a | devicePixelRatio : Float } -> List (Html.Attribute FrontendMsg_)
mouseListeners model =
    [ Html.Events.Extra.Mouse.onDown
        (\{ clientPos, button } ->
            MouseDown
                button
                (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos)
                    |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                )
        )
    , Html.Events.Extra.Mouse.onMove
        (\{ clientPos } ->
            MouseMove
                (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos)
                    |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                )
        )
    , Html.Events.Extra.Mouse.onUp
        (\{ clientPos, button } ->
            MouseUp
                button
                (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos)
                    |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                )
        )
    , Html.Events.Extra.Mouse.onContextMenu (\_ -> NoOpFrontendMsg)
    ]


shaderTime model =
    Duration.from model.startTime model.time |> Duration.inSeconds


canvasView : AudioData -> FrontendLoaded -> Html FrontendMsg_
canvasView audioData model =
    case Effect.WebGL.Texture.unwrap model.texture of
        Just texture ->
            let
                viewBounds_ : BoundingBox2d WorldUnit WorldUnit
                viewBounds_ =
                    viewBoundingBox model

                ( windowWidth, windowHeight ) =
                    Coord.toTuple model.windowSize

                ( cssWindowWidth, cssWindowHeight ) =
                    Coord.toTuple model.cssCanvasSize

                { x, y } =
                    Point2d.unwrap (actualViewPoint model)

                viewMatrix =
                    Mat4.makeScale3 (toFloat model.zoomFactor * 2 / toFloat windowWidth) (toFloat model.zoomFactor * -2 / toFloat windowHeight) 1
                        |> Mat4.translate3
                            (negate <| toFloat <| round (x * toFloat Units.tileWidth))
                            (negate <| toFloat <| round (y * toFloat Units.tileHeight))
                            0

                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel

                showMousePointer =
                    cursorSprite (hoverAt model (mouseScreenPosition model)) model

                ( mailPosition, mailSize ) =
                    case Ui.findElement (MailEditorHover MailEditor.MailButton) model.ui of
                        Just mailButton ->
                            ( mailButton.position, mailButton.buttonData.cachedSize )

                        Nothing ->
                            ( Coord.origin, Coord.origin )

                shaderTime2 =
                    shaderTime model
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
                    ++ mouseListeners model
                )
                (case Maybe.andThen Effect.WebGL.Texture.unwrap model.trainTexture of
                    Just trainTexture ->
                        let
                            textureSize =
                                WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2

                            gridViewBounds : BoundingBox2d WorldUnit WorldUnit
                            gridViewBounds =
                                viewLoadingBoundingBox model

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
                        drawBackground meshes viewMatrix texture shaderTime2
                            ++ drawForeground model.selectedUserId meshes viewMatrix texture shaderTime2
                            ++ Train.draw
                                model.selectedUserId
                                model.time
                                localGrid.mail
                                model.trains
                                viewMatrix
                                trainTexture
                                viewBounds_
                                shaderTime2
                            ++ drawCows texture viewMatrix model shaderTime2
                            ++ drawFlags texture viewMatrix model shaderTime2
                            ++ [ Effect.WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.debrisVertexShader
                                    Shaders.fragmentShader
                                    model.debrisMesh
                                    { view = viewMatrix
                                    , texture = texture
                                    , textureSize = textureSize
                                    , time = shaderTime2
                                    , time2 = shaderTime2
                                    , color = Vec4.vec4 1 1 1 1
                                    }
                               ]
                            ++ drawOtherCursors texture viewMatrix model shaderTime2
                            ++ drawSpeechBubble texture viewMatrix model shaderTime2
                            ++ drawTilePlacer audioData viewMatrix texture model shaderTime2
                            ++ (case model.mailEditor of
                                    Just _ ->
                                        [ MailEditor.backgroundLayer texture shaderTime2 ]

                                    Nothing ->
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
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    , userId = Shaders.noUserIdSelected
                                    , time = shaderTime2
                                    }
                               ]
                            ++ drawMap model
                            ++ (case model.mailEditor of
                                    Just mailEditor ->
                                        MailEditor.drawMail
                                            mailPosition
                                            mailSize
                                            texture
                                            (mouseScreenPosition model)
                                            windowWidth
                                            windowHeight
                                            model
                                            mailEditor
                                            shaderTime2

                                    Nothing ->
                                        []
                               )
                            ++ (case currentUserId model of
                                    Just userId ->
                                        drawCursor showMousePointer texture viewMatrix userId model shaderTime2

                                    Nothing ->
                                        []
                               )

                    _ ->
                        []
                )

        Nothing ->
            Html.text ""


drawCows : WebGL.Texture.Texture -> Mat4 -> FrontendLoaded -> Float -> List Effect.WebGL.Entity
drawCows texture viewMatrix model shaderTime2 =
    let
        localGrid : LocalGrid_
        localGrid =
            LocalGrid.localModel model.localModel

        viewBounds_ : BoundingBox2d WorldUnit WorldUnit
        viewBounds_ =
            viewBoundingBox model
    in
    List.filterMap
        (\( cowId, _ ) ->
            case cowActualPosition cowId model of
                Just { position } ->
                    if BoundingBox2d.contains position viewBounds_ then
                        let
                            point =
                                Point2d.unwrap position
                        in
                        Effect.WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            Cow.cowMesh
                            { view =
                                Mat4.makeTranslate3
                                    (point.x * toFloat Units.tileWidth |> round |> toFloat)
                                    (point.y * toFloat Units.tileHeight |> round |> toFloat)
                                    (Grid.tileZ True point.y (Coord.yRaw Cow.textureSize))
                                    |> Mat4.mul viewMatrix
                            , texture = texture
                            , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                            , color = Vec4.vec4 1 1 1 1
                            , userId = Shaders.noUserIdSelected
                            , time = shaderTime2
                            }
                            |> Just

                    else
                        Nothing

                Nothing ->
                    Nothing
        )
        (IdDict.toList localGrid.cows)


drawFlags : WebGL.Texture.Texture -> Mat4 -> FrontendLoaded -> Float -> List Effect.WebGL.Entity
drawFlags texture viewMatrix model shaderTime2 =
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
                        [ Shaders.blend ]
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
                        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                        , color = Vec4.vec4 1 1 1 1
                        , userId = Shaders.noUserIdSelected
                        , time = shaderTime2
                        }
                        |> Just

                Nothing ->
                    Nothing
        )
        (getFlags model)


drawSpeechBubble : WebGL.Texture.Texture -> Mat4 -> FrontendLoaded -> Float -> List Effect.WebGL.Entity
drawSpeechBubble texture viewMatrix model shaderTime2 =
    List.filterMap
        (\{ position, isRadio } ->
            let
                point =
                    Point2d.unwrap position

                ( xOffset, yOffset ) =
                    if isRadio then
                        ( 6, -8 )

                    else
                        ( -8, -48 )

                meshArray =
                    if isRadio then
                        speechBubbleRadioMesh

                    else
                        speechBubbleMesh
            in
            case
                Array.get
                    (Effect.Time.posixToMillis model.time
                        |> toFloat
                        |> (*) 0.01
                        |> round
                        |> modBy speechBubbleFrames
                    )
                    meshArray
            of
                Just mesh ->
                    Effect.WebGL.entityWith
                        [ Shaders.blend ]
                        Shaders.vertexShader
                        Shaders.fragmentShader
                        mesh
                        { view =
                            Mat4.makeTranslate3
                                (round (point.x * toFloat Units.tileWidth) + xOffset |> toFloat)
                                (round (point.y * toFloat Units.tileHeight) + yOffset |> toFloat)
                                0
                                |> Mat4.mul viewMatrix
                        , texture = texture
                        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                        , color = Vec4.vec4 1 1 1 1
                        , userId = Shaders.noUserIdSelected
                        , time = shaderTime2
                        }
                        |> Just

                Nothing ->
                    Nothing
        )
        (getSpeechBubbles model)


drawTilePlacer : AudioData -> Mat4 -> WebGL.Texture.Texture -> FrontendLoaded -> Float -> List Effect.WebGL.Entity
drawTilePlacer audioData viewMatrix texture model shaderTime2 =
    let
        textureSize =
            WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
    in
    case ( hoverAt model (mouseScreenPosition model), currentTool model, currentUserId model ) of
        ( MapHover, TilePlacerTool currentTile, Just userId ) ->
            let
                currentTile2 : Tile
                currentTile2 =
                    Toolbar.getTileGroupTile currentTile.tileGroup currentTile.index

                mousePosition : Coord WorldUnit
                mousePosition =
                    mouseWorldPosition model
                        |> Coord.floorPoint
                        |> Coord.minus (tileSize |> Coord.divide (Coord.tuple ( 2, 2 )))

                ( mouseX, mouseY ) =
                    Coord.toTuple mousePosition

                tileSize =
                    Tile.getData currentTile2 |> .size

                offsetX : Float
                offsetX =
                    case model.lastTilePlaced of
                        Just { tile, time } ->
                            let
                                timeElapsed =
                                    Duration.from time model.time
                            in
                            if
                                (timeElapsed
                                    |> Quantity.lessThan (Sound.length audioData model.sounds EraseSound)
                                )
                                    && (tile == EmptyTile)
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
                , textureSize = textureSize
                , color =
                    if currentTile.tileGroup == EmptyTileGroup then
                        Vec4.vec4 1 1 1 1

                    else if
                        canPlaceTile
                            model.time
                            { position = mousePosition
                            , change = currentTile2
                            , userId = userId
                            , colors =
                                { primaryColor = Color.rgb255 0 0 0
                                , secondaryColor = Color.rgb255 255 255 255
                                }
                            }
                            model.trains
                            (LocalGrid.localModel model.localModel |> .grid)
                    then
                        Vec4.vec4 1 1 1 0.5

                    else
                        Vec4.vec4 1 0 0 0.5
                , userId = Shaders.noUserIdSelected
                , time = shaderTime2
                }
            ]

        ( MapHover, TextTool (Just textTool), Just userId ) ->
            [ Effect.WebGL.entityWith
                [ Shaders.blend ]
                Shaders.vertexShader
                Shaders.fragmentShader
                textCursorMesh
                { view =
                    Coord.translateMat4
                        (Coord.multiply Units.tileSize textTool.cursorPosition)
                        viewMatrix
                , texture = texture
                , textureSize = textureSize
                , color =
                    if
                        canPlaceTile
                            model.time
                            { position = textTool.cursorPosition
                            , change = BigText 'A'
                            , userId = userId
                            , colors =
                                { primaryColor = Color.rgb255 0 0 0
                                , secondaryColor = Color.rgb255 255 255 255
                                }
                            }
                            model.trains
                            (LocalGrid.localModel model.localModel |> .grid)
                    then
                        Vec4.vec4 0 0 0 0.5

                    else
                        Vec4.vec4 1 0 0 0.5
                , userId = Shaders.noUserIdSelected
                , time = shaderTime2
                }
            ]

        _ ->
            []


drawMap : FrontendLoaded -> List Effect.WebGL.Entity
drawMap model =
    case ( model.showMap, Effect.WebGL.Texture.unwrap model.simplexNoiseLookup ) of
        ( True, Just simplexNoiseLookup ) ->
            let
                mapSize =
                    Toolbar.mapSize model.windowSize |> toFloat

                ( windowWidth, windowHeight ) =
                    Coord.toTuple model.windowSize
            in
            [ Effect.WebGL.entityWith
                []
                Shaders.worldMapVertexShader
                Shaders.worldMapFragmentShader
                mapSquare
                { view =
                    Mat4.makeScale3 (mapSize * 2 / toFloat windowWidth) (mapSize * -2 / toFloat windowHeight) 1
                        |> Mat4.translate3 -0.5 -0.5 -0.5
                , texture = simplexNoiseLookup
                , cellPosition =
                    actualViewPoint model
                        |> Grid.worldToCellPoint
                        |> Point2d.unwrap
                        |> Vec2.fromRecord
                }
            ]

        _ ->
            []


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


drawOtherCursors : WebGL.Texture.Texture -> Mat4 -> FrontendLoaded -> Float -> List Effect.WebGL.Entity
drawOtherCursors texture viewMatrix model shaderTime2 =
    let
        localGrid =
            LocalGrid.localModel model.localModel

        viewBounds_ : BoundingBox2d WorldUnit WorldUnit
        viewBounds_ =
            viewBoundingBox model |> BoundingBox2d.expandBy (Units.tileUnit 2)
    in
    (case currentUserId model of
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
                            [ Shaders.blend ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            (Cursor.getSpriteMesh
                                (case cursor.holdingCow of
                                    Just _ ->
                                        PinchSpriteCursor

                                    Nothing ->
                                        case cursor.currentTool of
                                            Cursor.HandTool ->
                                                DefaultSpriteCursor

                                            Cursor.EraserTool ->
                                                EraserSpriteCursor

                                            Cursor.TilePlacerTool ->
                                                DefaultSpriteCursor

                                            Cursor.TilePickerTool ->
                                                EyeDropperSpriteCursor

                                            Cursor.TextTool (Just _) ->
                                                TextSpriteCursor

                                            Cursor.TextTool Nothing ->
                                                DefaultSpriteCursor
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
                            , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                            , color = Vec4.vec4 1 1 1 1
                            , userId = Shaders.noUserIdSelected
                            , time = shaderTime2
                            }
                            |> Just

                    _ ->
                        Nothing
            )


drawCursor :
    { cursorType : CursorType, scale : Int }
    -> WebGL.Texture.Texture
    -> Mat4
    -> Id UserId
    -> FrontendLoaded
    -> Float
    -> List Effect.WebGL.Entity
drawCursor showMousePointer texture viewMatrix userId model shaderTime2 =
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
                                , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                                , color = Vec4.vec4 1 1 1 1
                                , userId = Shaders.noUserIdSelected
                                , time = shaderTime2
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
    Maybe (Id userId)
    -> Dict ( Int, Int ) { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    -> Mat4
    -> WebGL.Texture.Texture
    -> Float
    -> List Effect.WebGL.Entity
drawForeground maybeSelectedUserId meshes viewMatrix texture shaderTime2 =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                Effect.WebGL.entityWith
                    [ Effect.WebGL.Settings.cullFace Effect.WebGL.Settings.back
                    , Effect.WebGL.Settings.DepthTest.default
                    , Shaders.blend
                    ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    mesh.foreground
                    { view = viewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , color = Vec4.vec4 1 1 1 1
                    , userId =
                        case maybeSelectedUserId of
                            Just selectedUserId ->
                                Id.toInt selectedUserId |> toFloat

                            Nothing ->
                                -3
                    , time = shaderTime2
                    }
            )


drawBackground :
    Dict ( Int, Int ) { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    -> Mat4
    -> WebGL.Texture.Texture
    -> Float
    -> List Effect.WebGL.Entity
drawBackground meshes viewMatrix texture time =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                Effect.WebGL.entityWith
                    [ Effect.WebGL.Settings.cullFace Effect.WebGL.Settings.back
                    , Effect.WebGL.Settings.DepthTest.default
                    , Shaders.blend
                    ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    mesh.background
                    { view = viewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , color = Vec4.vec4 1 1 1 1
                    , userId = Shaders.noUserIdSelected
                    , time = time
                    }
            )


shortDelayDuration : Duration
shortDelayDuration =
    Duration.milliseconds 100


subscriptions : AudioData -> FrontendModel_ -> Subscription FrontendOnly FrontendMsg_
subscriptions _ model =
    Subscription.batch
        [ Subscription.fromJs
            "martinsstewart_elm_device_pixel_ratio_from_js"
            Ports.martinsstewart_elm_device_pixel_ratio_from_js
            (\value ->
                Json.Decode.decodeValue Json.Decode.float value
                    |> Result.withDefault 1
                    |> GotDevicePixelRatio
            )
        , Effect.Browser.Events.onResize (\width height -> WindowResized (Coord.xy width height))
        , Effect.Browser.Events.onAnimationFrame AnimationFrame
        , Keyboard.downs KeyDown
        , Ports.readFromClipboardResponse PastedText
        , case model of
            Loading _ ->
                Subscription.fromJs
                    "user_agent_from_js"
                    Ports.user_agent_from_js
                    (\value ->
                        Json.Decode.decodeValue Json.Decode.string value
                            |> Result.withDefault ""
                            |> GotUserAgentPlatform
                    )

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


getSpeechBubbles : FrontendLoaded -> List { position : Point2d WorldUnit WorldUnit, isRadio : Bool }
getSpeechBubbles model =
    IdDict.toList model.trains
        |> List.concatMap
            (\( _, train ) ->
                case ( Train.status model.time train, Train.isStuck model.time train ) of
                    ( TeleportingHome _, _ ) ->
                        []

                    ( _, Just time ) ->
                        if Duration.from time model.time |> Quantity.lessThan stuckMessageDelay then
                            []

                        else
                            [ { position = Train.trainPosition model.time train, isRadio = False }
                            , { position = Coord.toPoint2d (Train.home train), isRadio = True }
                            ]

                    ( _, Nothing ) ->
                        []
            )


stuckMessageDelay : Duration
stuckMessageDelay =
    Duration.seconds 2


speechBubbleMesh : Array (Effect.WebGL.Mesh Vertex)
speechBubbleMesh =
    List.range 0 (speechBubbleFrames - 1)
        |> List.map (\frame -> speechBubbleMeshHelper frame (Coord.xy 517 29) (Coord.xy 8 12))
        |> Array.fromList


speechBubbleRadioMesh : Array (Effect.WebGL.Mesh Vertex)
speechBubbleRadioMesh =
    List.range 0 (speechBubbleFrames - 1)
        |> List.map (\frame -> speechBubbleMeshHelper frame (Coord.xy 525 29) (Coord.xy 8 13))
        |> Array.fromList


speechBubbleFrames =
    3


speechBubbleMeshHelper : Int -> Coord a -> Coord a -> Effect.WebGL.Mesh Vertex
speechBubbleMeshHelper frame bubbleTailTexturePosition bubbleTailTextureSize =
    let
        text =
            "Help!"

        padding =
            Coord.xy 6 5

        colors =
            { primaryColor = Color.white
            , secondaryColor = Color.black
            }
    in
    Sprite.nineSlice
        { topLeft = Coord.xy 504 29
        , top = Coord.xy 510 29
        , topRight = Coord.xy 511 29
        , left = Coord.xy 504 35
        , center = Coord.xy 510 35
        , right = Coord.xy 511 35
        , bottomLeft = Coord.xy 504 36
        , bottom = Coord.xy 510 36
        , bottomRight = Coord.xy 511 36
        , cornerSize = Coord.xy 6 6
        , position = Coord.xy 0 0
        , size = Sprite.textSize 1 text |> Coord.plus (Coord.multiplyTuple ( 2, 2 ) padding)
        }
        colors
        ++ Sprite.shiverText frame 1 "Help!" padding
        ++ Sprite.spriteWithTwoColors colors (Coord.xy 7 27) (Coord.xy 8 12) bubbleTailTexturePosition bubbleTailTextureSize
        |> Sprite.toMesh


cowActualPosition : Id CowId -> FrontendLoaded -> Maybe { position : Point2d WorldUnit WorldUnit, isHeld : Bool }
cowActualPosition cowId model =
    let
        localGrid =
            LocalGrid.localModel model.localModel
    in
    case
        IdDict.toList localGrid.cursors
            |> List.find (\( _, cursor ) -> Just cowId == Maybe.map .cowId cursor.holdingCow)
    of
        Just ( userId, cursor ) ->
            { position =
                cursorActualPosition (Just userId == currentUserId model) userId cursor model
                    |> Point2d.translateBy (Vector2d.unsafe { x = 0, y = 0.2 })
            , isHeld = True
            }
                |> Just

        Nothing ->
            case IdDict.get cowId localGrid.cows of
                Just cow ->
                    Just { position = cow.position, isHeld = False }

                Nothing ->
                    Nothing


mapSquare : Effect.WebGL.Mesh { position : Vec2, vcoord2 : Vec2 }
mapSquare =
    let
        size =
            11
    in
    Shaders.triangleFan
        [ { position = Vec2.vec2 0 0
          , vcoord2 = Vec2.vec2 -size -size
          }
        , { position = Vec2.vec2 1 0
          , vcoord2 = Vec2.vec2 size -size
          }
        , { position = Vec2.vec2 1 1
          , vcoord2 = Vec2.vec2 size size
          }
        , { position = Vec2.vec2 0 1
          , vcoord2 = Vec2.vec2 -size size
          }
        ]


textCursorMesh : Effect.WebGL.Mesh Vertex
textCursorMesh =
    Sprite.rectangle Color.white Coord.origin (Coord.multiply Units.tileSize (Coord.xy 1 2))
        |> Sprite.toMesh
