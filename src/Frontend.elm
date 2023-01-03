port module Frontend exposing
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
import Cursor exposing (CursorMeshes, CursorSprite(..), CursorType(..))
import Dict exposing (Dict)
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
import EverySet
import Grid exposing (Grid)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Wheel
import Id exposing (CowId, Id, TrainId, UserId)
import IdDict exposing (IdDict)
import Json.Decode
import Json.Encode
import Keyboard
import Keyboard.Arrows
import Lamdera
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import LocalGrid exposing (Cursor, LocalGrid, LocalGrid_)
import LocalModel exposing (LocalModel)
import MailEditor exposing (FrontendMail, MailStatus(..), ShowMailEditor(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Route
import Set exposing (Set)
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound(..))
import Sprite
import TextInput exposing (OutMsg(..))
import Tile exposing (CollisionMask(..), DefaultColor(..), RailPathType(..), Tile(..), TileData, TileGroup(..))
import Toolbar exposing (ViewData)
import Train exposing (Status(..), Train)
import Types exposing (..)
import Ui
import Units exposing (CellUnit, MailPixelUnit, TileLocalUnit, WorldUnit)
import Untrusted
import Url exposing (Url)
import Url.Parser exposing ((<?>))
import Vector2d exposing (Vector2d)
import WebGL.Texture


port martinsstewart_elm_device_pixel_ratio_from_js : (Json.Decode.Value -> msg) -> Sub msg


port martinsstewart_elm_device_pixel_ratio_to_js : Json.Encode.Value -> Cmd msg


port user_agent_to_js : Json.Encode.Value -> Cmd msg


port user_agent_from_js : (Json.Decode.Value -> msg) -> Sub msg


port audioPortToJS : Json.Encode.Value -> Cmd msg


port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg


port supermario_copy_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


copyToClipboard text =
    Command.sendToJs
        "supermario_copy_to_clipboard_to_js"
        supermario_copy_to_clipboard_to_js
        (Json.Encode.string text)


port supermario_read_from_clipboard_to_js : Json.Encode.Value -> Cmd msg


readFromClipboardRequest : Command FrontendOnly toMsg msg
readFromClipboardRequest =
    Command.sendToJs
        "supermario_read_from_clipboard_to_js"
        supermario_read_from_clipboard_to_js
        Json.Encode.null


port supermario_read_from_clipboard_from_js : (Json.Decode.Value -> msg) -> Sub msg


readFromClipboardResponse : (String -> msg) -> Subscription FrontendOnly msg
readFromClipboardResponse msg =
    Subscription.fromJs
        "supermario_read_from_clipboard_from_js"
        supermario_read_from_clipboard_from_js
        (\value ->
            Json.Decode.decodeValue Json.Decode.string value
                |> Result.withDefault ""
                |> msg
        )


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
            { toJS = Command.sendToJs "audioPortToJS" audioPortToJS
            , fromJS = Subscription.fromJs "audioPortFromJS" audioPortFromJS
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
            Sound.play model.sounds sound (Duration.subtractFrom time timeOffset)

        playWithConfig config sound time =
            Sound.playWithConfig audioData model.sounds config sound (Duration.subtractFrom time timeOffset)

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
                (AssocList.toList model.trains)

        mailEditorVolumeScale : Float
        mailEditorVolumeScale =
            clamp
                0
                1
                (case model.mailEditor.showMailEditor of
                    MailEditorClosed ->
                        1

                    MailEditorClosing { startTime } ->
                        Quantity.ratio (Duration.from startTime model.time) MailEditor.openAnimationLength

                    MailEditorOpening { startTime } ->
                        1 - Quantity.ratio (Duration.from startTime model.time) MailEditor.openAnimationLength
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
        (AssocList.toList model.trains)
        |> Audio.group
    , case model.lastTrainWhistle of
        Just time ->
            playSound TrainWhistleSound time |> Audio.scaleVolume (0.2 * mailEditorVolumeScale)

        Nothing ->
            Audio.silence
    , case model.mailEditor.showMailEditor of
        MailEditorClosed ->
            Audio.silence

        MailEditorOpening { startTime } ->
            playSound PageTurnSound startTime |> Audio.scaleVolume 0.8

        MailEditorClosing { startTime } ->
            playSound PageTurnSound startTime |> Audio.scaleVolume 0.8
    , List.map (playSound WhooshSound) model.lastTileRotation |> Audio.group |> Audio.scaleVolume 0.5
    , case model.mailEditor.lastPlacedImage of
        Just time ->
            playSound PopSound time |> Audio.scaleVolume 0.4

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
    ]
        |> Audio.group
        |> Audio.scaleVolumeAt [ ( model.startTime, 0 ), ( Duration.addTo model.startTime Duration.second, 1 ) ]


volume : FrontendLoaded -> Point2d WorldUnit WorldUnit -> Float
volume model position =
    let
        boundingBox =
            viewBoundingBox_ model
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
                (\time devicePixelRatio texture () ->
                    loadedInit time devicePixelRatio frontendLoading texture loadedLocalModel
                )
                frontendLoading.time
                frontendLoading.devicePixelRatio
                frontendLoading.texture


defaultTileHotkeys : Dict String TileGroup
defaultTileHotkeys =
    Dict.fromList
        [ ( "1", EmptyTileGroup )
        , ( "2", PostOfficeGroup )
        , ( "3", HouseGroup )
        , ( "4", LogCabinGroup )
        , ( "q", TrainHouseGroup )
        , ( "w", RailTurnGroup )
        , ( "e", RailTurnSplitGroup )
        , ( "r", RailTurnSplitMirrorGroup )
        , ( "a", RailStrafeSmallGroup )
        , ( "s", RailStrafeGroup )
        , ( "d", RailTurnLargeGroup )
        , ( "f", RailStraightGroup )
        , ( "z", RailCrossingGroup )
        , ( "x", SidewalkRailGroup )
        , ( "c", SidewalkGroup )
        , ( "v", PineTreeGroup )
        ]


loadedInit :
    Effect.Time.Posix
    -> Float
    -> FrontendLoading
    -> Texture
    -> LoadedLocalModel_
    -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
loadedInit time devicePixelRatio loading texture loadedLocalModel =
    let
        currentTile =
            HandTool

        defaultTileColors =
            AssocList.empty

        focus =
            MapHover

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = loadedLocalModel.localModel
            , trains = loadedLocalModel.trains
            , meshes = Dict.empty
            , viewPoint = Coord.toPoint2d loading.viewPoint |> NormalViewPoint
            , viewPointLastInterval = Point2d.origin
            , texture = texture
            , trainTexture = Nothing
            , pressedKeys = []
            , windowSize = loading.windowSize
            , devicePixelRatio = devicePixelRatio
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
            , removedTileParticles = []
            , debrisMesh = Shaders.triangleFan []
            , lastTrainWhistle = Nothing
            , mail = loadedLocalModel.mail
            , mailEditor =
                MailEditor.initEditor
                    (case (LocalGrid.localModel loadedLocalModel.localModel).userStatus of
                        LoggedIn loggedIn ->
                            loggedIn.mailEditor

                        NotLoggedIn ->
                            { to = ""
                            , content = []
                            , currentImage = MailEditor.BlueStamp
                            }
                    )
            , currentTool = currentTile
            , lastTileRotation = []
            , lastPlacementError = Nothing
            , tileHotkeys = defaultTileHotkeys
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
            , focus = focus
            , music = { startTime = Duration.addTo time (Duration.seconds 10), sound = Music0 }
            , previousCursorPositions = IdDict.empty
            , handMeshes = AssocList.empty
            , hasCmdKey = loading.hasCmdKey
            , loginTextInput = TextInput.init
            , pressedSubmitEmail = NotSubmitted { pressedSubmit = False }
            , showInvite = False
            , inviteTextInput = TextInput.init
            , inviteSubmitStatus = NotSubmitted { pressedSubmit = False }
            }
                |> setCurrentTool HandToolButton
                |> handleOutMsg LocalGrid.HandColorChanged
    in
    ( updateMeshes True model model
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
                    , cmd = Command.none
                    }

                Nothing ->
                    { data = { viewPoint = Route.startPointAt, loginToken = Nothing }
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
        , devicePixelRatio = Nothing
        , zoomFactor = 2
        , time = Nothing
        , viewPoint = data.viewPoint
        , mousePosition = Point2d.origin
        , sounds = AssocList.empty
        , texture = Nothing
        , localModel = LoadingLocalModel []
        , hasCmdKey = False
        }
    , Command.batch
        [ Effect.Lamdera.sendToBackend (ConnectToBackend bounds data.loginToken)
        , Command.sendToJs "user_agent_to_js" user_agent_to_js Json.Encode.null
        , Effect.Task.perform
            (\{ viewport } ->
                WindowResized
                    ( round viewport.width |> Pixels.pixels
                    , round viewport.height |> Pixels.pixels
                    )
            )
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
        ]
    , Sound.load SoundLoaded
    )


update : AudioData -> FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
update audioData msg model =
    case model of
        Loading loadingModel ->
            case msg of
                WindowResized windowSize ->
                    windowResizedUpdate windowSize loadingModel |> Tuple.mapFirst Loading

                GotDevicePixelRatio devicePixelRatio ->
                    ( Loading { loadingModel | devicePixelRatio = Just devicePixelRatio }, Command.none )

                SoundLoaded sound result ->
                    ( Loading { loadingModel | sounds = AssocList.insert sound result loadingModel.sounds }, Command.none )

                TextureLoaded result ->
                    case result of
                        Ok texture ->
                            ( Loading { loadingModel | texture = Just texture }, Command.none )

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

                GotUserAgent userAgent ->
                    ( Loading { loadingModel | hasCmdKey = String.startsWith "mac" (String.toLower userAgent) }
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
                |> Tuple.mapFirst (updateMeshes False frontendLoaded)
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

        KeyMsg keyMsg ->
            ( { model | pressedKeys = Keyboard.update keyMsg model.pressedKeys }, Command.none )

        KeyDown rawKey ->
            case Keyboard.anyKeyOriginal rawKey of
                Just key ->
                    if MailEditor.isOpen model.mailEditor then
                        ( { model
                            | mailEditor =
                                MailEditor.handleKeyDown model (ctrlOrMeta model) key model.mailEditor
                          }
                        , Command.none
                        )

                    else
                        case ( model.focus, model.currentTool, key ) of
                            ( _, _, Keyboard.Tab ) ->
                                ( setFocus
                                    (if keyDown Keyboard.Shift model then
                                        previousFocus model

                                     else
                                        nextFocus model
                                    )
                                    model
                                , Command.none
                                )

                            ( UiHover EmailAddressTextInputHover _, _, Keyboard.Enter ) ->
                                sendEmail model

                            ( UiHover SendEmailButtonHover _, _, Keyboard.Enter ) ->
                                sendEmail model

                            ( UiHover PrimaryColorInput _, _, Keyboard.Escape ) ->
                                ( setFocus MapHover model, Command.none )

                            ( UiHover SecondaryColorInput _, _, Keyboard.Escape ) ->
                                ( setFocus MapHover model, Command.none )

                            ( UiHover EmailAddressTextInputHover _, _, Keyboard.Escape ) ->
                                ( setFocus MapHover model, Command.none )

                            ( UiHover PrimaryColorInput _, tool, _ ) ->
                                case currentUserId model of
                                    Just userId ->
                                        handleKeyDownColorInput
                                            userId
                                            (\a b -> { b | primaryColorTextInput = a })
                                            (\color a -> { a | primaryColor = color })
                                            tool
                                            key
                                            model
                                            model.primaryColorTextInput

                                    Nothing ->
                                        ( model, Command.none )

                            ( UiHover SecondaryColorInput _, tool, _ ) ->
                                case currentUserId model of
                                    Just userId ->
                                        handleKeyDownColorInput
                                            userId
                                            (\a b -> { b | secondaryColorTextInput = a })
                                            (\color a -> { a | secondaryColor = color })
                                            tool
                                            key
                                            model
                                            model.secondaryColorTextInput

                                    Nothing ->
                                        ( model, Command.none )

                            ( UiHover EmailAddressTextInputHover _, _, _ ) ->
                                let
                                    ( newTextInput, outMsg ) =
                                        TextInput.keyMsg
                                            (ctrlOrMeta model)
                                            (keyDown Keyboard.Shift model)
                                            key
                                            model.loginTextInput
                                in
                                ( { model | loginTextInput = newTextInput }
                                , case outMsg of
                                    CopyText text ->
                                        copyToClipboard text

                                    PasteText ->
                                        readFromClipboardRequest

                                    NoOutMsg ->
                                        Command.none
                                )

                            _ ->
                                keyMsgCanvasUpdate key model

                Nothing ->
                    ( model, Command.none )

        WindowResized windowSize ->
            windowResizedUpdate windowSize model

        GotDevicePixelRatio devicePixelRatio ->
            ( { model | devicePixelRatio = devicePixelRatio }, Command.none )

        MouseDown button mousePosition ->
            let
                hover =
                    hoverAt model mousePosition

                mousePosition2 : Coord Pixels
                mousePosition2 =
                    mousePosition
                        |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                        |> Coord.roundPoint
            in
            case model.mailEditor.showMailEditor of
                MailEditorOpening { startTime, startPosition } ->
                    if
                        (button == MainButton)
                            && (Duration.from startTime model.time |> Quantity.greaterThan MailEditor.openAnimationLength)
                    then
                        let
                            ( windowWidth, windowHeight ) =
                                actualCanvasSize

                            { canvasSize, actualCanvasSize } =
                                findPixelPerfectSize model

                            ( newMailEditor, cmd ) =
                                MailEditor.handleMouseDown
                                    Command.none
                                    (MailEditorToBackend >> Effect.Lamdera.sendToBackend)
                                    windowWidth
                                    windowHeight
                                    model
                                    mousePosition
                                    model.mailEditor
                        in
                        ( { model
                            | mouseLeft =
                                MouseButtonDown
                                    { start = mousePosition
                                    , start_ = screenToWorld model mousePosition
                                    , current = mousePosition
                                    , hover = hover
                                    }
                            , mailEditor = newMailEditor
                          }
                        , cmd
                        )

                    else
                        ( model, Command.none )

                _ ->
                    ( if button == MainButton then
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
                                    case ( currentTool model2, hover ) of
                                        ( TilePlacerTool { tileGroup, index }, MapHover ) ->
                                            placeTile False tileGroup index model2

                                        ( _, UiHover PrimaryColorInput data ) ->
                                            { model2
                                                | primaryColorTextInput =
                                                    TextInput.mouseDown
                                                        mousePosition2
                                                        data.position
                                                        model2.primaryColorTextInput
                                            }
                                                |> setFocus (UiHover PrimaryColorInput data)

                                        ( _, UiHover SecondaryColorInput data ) ->
                                            { model2
                                                | secondaryColorTextInput =
                                                    TextInput.mouseDown
                                                        mousePosition2
                                                        data.position
                                                        model2.secondaryColorTextInput
                                            }
                                                |> setFocus (UiHover SecondaryColorInput data)

                                        ( _, UiHover EmailAddressTextInputHover data ) ->
                                            { model2
                                                | loginTextInput =
                                                    TextInput.mouseDown
                                                        mousePosition2
                                                        data.position
                                                        model2.loginTextInput
                                            }
                                                |> setFocus hover

                                        _ ->
                                            model2
                               )

                      else if button == MiddleButton then
                        { model
                            | mouseMiddle =
                                MouseButtonDown
                                    { start = mousePosition
                                    , start_ = screenToWorld model mousePosition
                                    , current = mousePosition
                                    , hover = hover
                                    }
                        }

                      else
                        model
                    , Command.none
                    )

        MouseUp button mousePosition ->
            case ( button, model.mouseLeft, model.mouseMiddle ) of
                ( MainButton, MouseButtonDown previousMouseState, _ ) ->
                    mainMouseButtonUp mousePosition previousMouseState model

                ( MiddleButton, _, MouseButtonDown mouseState ) ->
                    ( { model
                        | mouseMiddle = MouseButtonUp { current = mousePosition }
                        , viewPoint =
                            if MailEditor.isOpen model.mailEditor then
                                model.viewPoint

                            else
                                offsetViewPoint model mouseState.hover mouseState.start mousePosition |> NormalViewPoint
                      }
                    , Command.none
                    )

                _ ->
                    ( model, Command.none )

        MouseWheel event ->
            let
                rotationHelper : Int -> { a | tileGroup : TileGroup, index : Int } -> FrontendLoaded
                rotationHelper offset tile =
                    if Tile.getTileGroupData tile.tileGroup |> .tiles |> List.Nonempty.length |> (==) 1 then
                        model

                    else
                        { model
                            | currentTool =
                                { tileGroup = tile.tileGroup
                                , index = tile.index + offset
                                , mesh =
                                    Grid.tileMesh
                                        Coord.origin
                                        (Toolbar.getTileGroupTile tile.tileGroup (tile.index + offset))
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

                scrollThreshold : Float
                scrollThreshold =
                    model.scrollThreshold + event.deltaY
            in
            ( if abs scrollThreshold > 50 then
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
                            rotationHelper 1 currentTile

                        ( False, TilePlacerTool currentTile ) ->
                            rotationHelper -1 currentTile

                        _ ->
                            { model | scrollThreshold = 0 }

              else
                { model | scrollThreshold = scrollThreshold }
            , Command.none
            )

        MouseMove mousePosition ->
            let
                tileHover_ =
                    case hoverAt model mousePosition of
                        UiHover (ToolButtonHover (TilePlacerToolButton tile)) _ ->
                            Just tile

                        _ ->
                            Nothing

                mousePosition2 : Coord Pixels
                mousePosition2 =
                    mousePosition
                        |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                        |> Coord.roundPoint

                placeTileHelper model2 =
                    case currentTool model2 of
                        TilePlacerTool { tileGroup, index } ->
                            placeTile True tileGroup index model2

                        HandTool ->
                            model2

                        TilePickerTool ->
                            model2
            in
            ( { model
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
                                        model2

                                    TileHover _ ->
                                        placeTileHelper model2

                                    TrainHover _ ->
                                        placeTileHelper model2

                                    MapHover ->
                                        placeTileHelper model2

                                    MailEditorHover _ ->
                                        model2

                                    UiHover uiHover data ->
                                        case uiHover of
                                            PrimaryColorInput ->
                                                { model2
                                                    | primaryColorTextInput =
                                                        TextInput.mouseDownMove
                                                            mousePosition2
                                                            data.position
                                                            model2.primaryColorTextInput
                                                }

                                            SecondaryColorInput ->
                                                { model2
                                                    | secondaryColorTextInput =
                                                        TextInput.mouseDownMove
                                                            mousePosition2
                                                            data.position
                                                            model2.secondaryColorTextInput
                                                }

                                            EmailAddressTextInputHover ->
                                                { model2
                                                    | loginTextInput =
                                                        TextInput.mouseDownMove
                                                            mousePosition2
                                                            data.position
                                                            model2.loginTextInput
                                                }

                                            SendEmailButtonHover ->
                                                model2

                                            ToolButtonHover _ ->
                                                model2

                                            ShowInviteUser ->
                                                model2

                                    CowHover _ ->
                                        placeTileHelper model2

                            _ ->
                                model2
                   )
            , Command.none
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
                    viewBoundingBox_ model

                playTrainWhistle =
                    (case model.lastTrainWhistle of
                        Just whistleTime ->
                            Duration.from whistleTime time |> Quantity.greaterThan (Duration.seconds 180)

                        Nothing ->
                            True
                    )
                        && List.any
                            (\( _, train ) -> BoundingBox2d.contains (Train.trainPosition model.time train) viewBounds)
                            (AssocList.toList model.trains)

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
                                , sound = Music0
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
                    case model.focus of
                        TileHover _ ->
                            True

                        TrainHover _ ->
                            True

                        MapHover ->
                            True

                        MailEditorHover _ ->
                            True

                        CowHover _ ->
                            True

                        UiBackgroundHover ->
                            True

                        UiHover uiHover _ ->
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

                model2 =
                    { model
                        | time = time
                        , localTime = localTime
                        , animationElapsedTime = Duration.from model.time time |> Quantity.plus model.animationElapsedTime
                        , trains =
                            AssocList.map
                                (\trainId train ->
                                    Train.moveTrain
                                        trainId
                                        Train.defaultMaxSpeed
                                        model.time
                                        time
                                        { grid = localGrid.grid, mail = AssocList.empty }
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
            in
            ( case ( ( movedViewWithArrowKeys, model.viewPoint ), model2.mouseLeft, model2.currentTool ) of
                ( ( True, _ ), MouseButtonDown _, TilePlacerTool currentTile ) ->
                    placeTile True currentTile.tileGroup currentTile.index model2

                ( ( _, TrainViewPoint _ ), MouseButtonDown _, TilePlacerTool currentTile ) ->
                    placeTile True currentTile.tileGroup currentTile.index model2

                _ ->
                    model2
            , Command.none
            )

        SoundLoaded sound result ->
            ( { model | sounds = AssocList.insert sound result model.sounds }, Command.none )

        VisibilityChanged ->
            ( setCurrentTool HandToolButton model, Command.none )

        TrainTextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | trainTexture = Just texture }, Command.none )

                Err _ ->
                    ( model, Command.none )

        PastedText text ->
            case model.focus of
                TileHover _ ->
                    ( model, Command.none )

                TrainHover _ ->
                    ( model, Command.none )

                MapHover ->
                    ( model, Command.none )

                MailEditorHover _ ->
                    ( model, Command.none )

                CowHover _ ->
                    ( model, Command.none )

                UiBackgroundHover ->
                    ( model, Command.none )

                UiHover uiHover _ ->
                    case uiHover of
                        EmailAddressTextInputHover ->
                            ( { model | loginTextInput = TextInput.paste text model.loginTextInput }
                            , Command.none
                            )

                        SendEmailButtonHover ->
                            ( model, Command.none )

                        PrimaryColorInput ->
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
                                    ( model, Command.none )

                        SecondaryColorInput ->
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
                                    ( model, Command.none )

                        ToolButtonHover _ ->
                            ( model, Command.none )

                        ShowInviteUser ->
                            ( model, Command.none )

        GotUserAgent _ ->
            ( model, Command.none )


previousFocus : FrontendLoaded -> Hover
previousFocus model =
    rotationAntiClockwiseHelper model (List.Nonempty.singleton model.focus) |> List.Nonempty.head


rotationAntiClockwiseHelper : FrontendLoaded -> Nonempty Hover -> Nonempty Hover
rotationAntiClockwiseHelper model list =
    let
        next =
            nextFocus { model | focus = List.Nonempty.head list }
    in
    if List.Nonempty.any ((==) next) list then
        list

    else
        rotationAntiClockwiseHelper model (List.Nonempty.cons next list)


currentTileGroup : FrontendLoaded -> Maybe TileGroup
currentTileGroup model =
    case model.currentTool of
        TilePlacerTool { tileGroup } ->
            Just tileGroup

        HandTool ->
            Nothing

        TilePickerTool ->
            Nothing


nextFocus : FrontendLoaded -> Hover
nextFocus model =
    case model.focus of
        TileHover _ ->
            model.focus

        TrainHover _ ->
            model.focus

        MapHover ->
            model.focus

        MailEditorHover _ ->
            model.focus

        CowHover _ ->
            model.focus

        UiBackgroundHover ->
            model.focus

        UiHover uiHover _ ->
            UiHover
                (case uiHover of
                    EmailAddressTextInputHover ->
                        SendEmailButtonHover

                    SendEmailButtonHover ->
                        EmailAddressTextInputHover

                    PrimaryColorInput ->
                        case currentUserId model of
                            Just userId ->
                                case Toolbar.showColorTextInputs (getHandColor userId model) model.tileColors model.currentTool |> .showSecondaryColorTextInput of
                                    Just _ ->
                                        SecondaryColorInput

                                    Nothing ->
                                        PrimaryColorInput

                            Nothing ->
                                PrimaryColorInput

                    SecondaryColorInput ->
                        case currentUserId model of
                            Just userId ->
                                case Toolbar.showColorTextInputs (getHandColor userId model) model.tileColors model.currentTool |> .showPrimaryColorTextInput of
                                    Just _ ->
                                        PrimaryColorInput

                                    Nothing ->
                                        SecondaryColorInput

                            Nothing ->
                                SecondaryColorInput

                    ToolButtonHover toolButton ->
                        ToolButtonHover toolButton

                    ShowInviteUser ->
                        ShowInviteUser
                )
                { position = Coord.origin }


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
                                copyToClipboard text

                            PasteText ->
                                readFromClipboardRequest

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
                    let
                        ( model2, outMsg ) =
                            updateLocalModel
                                (updateColor color (getHandColor userId model)
                                    |> Change.ChangeHandColor
                                )
                                model
                    in
                    ( handleOutMsg outMsg model2, Command.none )

                Nothing ->
                    ( model, Command.none )

        TilePickerTool ->
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
                                                Coord.origin
                                                (Toolbar.getTileGroupTile currentTile.tileGroup currentTile.index)
                                                (getTileColor currentTile.tileGroup m)
                                                |> Sprite.toMesh
                                        }
                                            |> TilePlacerTool

                                    HandTool ->
                                        m.currentTool

                                    TilePickerTool ->
                                        m.currentTool
                        }

                    Nothing ->
                        m
            )


getViewModel : FrontendLoaded -> ViewData Pixels
getViewModel model =
    { devicePixelRatio = model.devicePixelRatio
    , windowSize = model.windowSize
    , pressedSubmitEmail = model.pressedSubmitEmail
    , loginTextInput = model.loginTextInput
    , hasCmdKey = model.hasCmdKey
    , handColor = Maybe.map (\userId -> getHandColor userId model) (currentUserId model)
    , primaryColorTextInput = model.primaryColorTextInput
    , secondaryColorTextInput = model.secondaryColorTextInput
    , tileColors = model.tileColors
    , tileHotkeys = model.tileHotkeys
    , currentTool = model.currentTool
    , pingData = model.pingData
    , userId = currentUserId model
    , showInvite = model.showInvite
    , inviteTextInput = model.inviteTextInput
    , inviteSubmitStatus = model.inviteSubmitStatus
    }


hoverAt : FrontendLoaded -> Point2d Pixels Pixels -> Hover
hoverAt model mousePosition =
    let
        mousePosition2 : Coord Pixels
        mousePosition2 =
            mousePosition
                |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                |> Coord.roundPoint
    in
    if MailEditor.isOpen model.mailEditor then
        MailEditor.hoverAt model.mailEditor |> MailEditorHover

    else
        case Ui.hover mousePosition2 (Toolbar.view (getViewModel model)) of
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
                                AssocList.toList model.trains
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
                                                        insideCow mouseWorldPosition_ a.position

                                                Nothing ->
                                                    False
                                        )
                                    |> Quantity.maximumBy (\( _, cow ) -> Point2d.yCoordinate cow.position)
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
            , Command.none
            )

        ( Keyboard.Spacebar, True ) ->
            ( { model | tileHotkeys = Dict.update " " (\_ -> currentTileGroup model) model.tileHotkeys }
            , Command.none
            )

        ( Keyboard.Character string, True ) ->
            ( { model | tileHotkeys = Dict.update string (\_ -> currentTileGroup model) model.tileHotkeys }
            , Command.none
            )

        ( Keyboard.Spacebar, False ) ->
            ( case Dict.get " " model.tileHotkeys of
                Just tile ->
                    setCurrentTool (TilePlacerToolButton tile) model

                Nothing ->
                    model
            , Command.none
            )

        ( Keyboard.Character string, False ) ->
            ( case Dict.get string model.tileHotkeys of
                Just tile ->
                    setCurrentTool (TilePlacerToolButton tile) model

                Nothing ->
                    model
            , Command.none
            )

        _ ->
            ( model, Command.none )


getTileColor :
    TileGroup
    -> { a | tileColors : AssocList.Dict TileGroup Colors }
    -> Colors
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
                        , mesh = Grid.tileMesh Coord.origin (Toolbar.getTileGroupTile tileGroup 0) colors |> Sprite.toMesh
                        }

                HandToolButton ->
                    HandTool

                TilePickerToolButton ->
                    TilePickerTool
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
tileInteraction currentUserId2 { tile, userId, position } model2 =
    let
        handleTrainHouse : Maybe (() -> ( FrontendLoaded, Command FrontendOnly ToBackend frontendMsg ))
        handleTrainHouse =
            case
                AssocList.toList model2.trains
                    |> List.find (\( _, train ) -> Train.home train == position)
            of
                Just ( trainId, train ) ->
                    case Train.status model2.time train of
                        WaitingAtHome ->
                            Just (\() -> clickLeaveHomeTrain trainId train model2)

                        _ ->
                            Just (\() -> clickTeleportHomeTrain trainId train model2)

                Nothing ->
                    Nothing
    in
    case tile of
        PostOffice ->
            if userId == currentUserId2 && canOpenMailEditor model2 then
                (\() ->
                    ( { model2
                        | mailEditor =
                            MailEditor.open
                                model2
                                (Coord.toPoint2d position
                                    |> Point2d.translateBy (Vector2d.unsafe { x = 1, y = 1.5 })
                                    |> worldToScreen model2
                                )
                                model2.mailEditor
                      }
                    , Command.none
                    )
                )
                    |> Just

            else
                Nothing

        HouseDown ->
            (\() -> ( { model2 | lastHouseClick = Just model2.time }, Command.none )) |> Just

        HouseLeft ->
            (\() -> ( { model2 | lastHouseClick = Just model2.time }, Command.none )) |> Just

        HouseUp ->
            (\() -> ( { model2 | lastHouseClick = Just model2.time }, Command.none )) |> Just

        HouseRight ->
            (\() -> ( { model2 | lastHouseClick = Just model2.time }, Command.none )) |> Just

        TrainHouseLeft ->
            handleTrainHouse

        TrainHouseRight ->
            handleTrainHouse

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
                    case ( MailEditor.isOpen model.mailEditor, model.mouseMiddle ) of
                        ( False, MouseButtonUp _ ) ->
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

                        _ ->
                            model.viewPoint
            }
                |> (\m ->
                        if isSmallDistance2 then
                            setFocus hoverAt2 m

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

                            Nothing ->
                                ( model2, Command.none )

                    TrainHover { trainId, train } ->
                        case Train.status model.time train of
                            WaitingAtHome ->
                                clickLeaveHomeTrain trainId train model2

                            TeleportingHome _ ->
                                ( { model2
                                    | viewPoint = actualViewPoint model2 |> NormalViewPoint
                                    , trains =
                                        AssocList.update
                                            trainId
                                            (\_ -> Train.leaveHome model.time train |> Just)
                                            model2.trains
                                  }
                                , CancelTeleportHomeTrainRequest trainId |> Effect.Lamdera.sendToBackend
                                )

                            _ ->
                                case Train.isStuck model.time train of
                                    Just stuckTime ->
                                        if Duration.from stuckTime model2.time |> Quantity.lessThan stuckMessageDelay then
                                            ( setTrainViewPoint trainId model2, Command.none )

                                        else
                                            clickTeleportHomeTrain trainId train model2

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

                    MailEditorHover _ ->
                        ( model2, Command.none )

                    CowHover { cowId } ->
                        let
                            ( model3, _ ) =
                                updateLocalModel (Change.PickupCow cowId (mouseWorldPosition model2) model2.time) model2
                        in
                        ( model3, Command.none )

                    UiHover uiHover _ ->
                        case uiHover of
                            PrimaryColorInput ->
                                ( model2, Command.none )

                            SecondaryColorInput ->
                                ( model2, Command.none )

                            ToolButtonHover tool ->
                                ( setCurrentTool tool model2, Command.none )

                            EmailAddressTextInputHover ->
                                ( model2, Command.none )

                            SendEmailButtonHover ->
                                sendEmail model2

                            ShowInviteUser ->
                                ( { model2 | showInvite = True }, Command.none )

    else
        ( model2, Command.none )


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


isPrimaryColorInput : Hover -> Bool
isPrimaryColorInput hover =
    case hover of
        UiHover PrimaryColorInput _ ->
            True

        _ ->
            False


isSecondaryColorInput : Hover -> Bool
isSecondaryColorInput hover =
    case hover of
        UiHover SecondaryColorInput _ ->
            True

        _ ->
            False


setFocus : Hover -> FrontendLoaded -> FrontendLoaded
setFocus newFocus model =
    { model
        | focus = newFocus
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

                    else if not (isSecondaryColorInput model.focus) && isSecondaryColorInput newFocus then
                        TextInput.selectAll model.secondaryColorTextInput

                    else
                        model.secondaryColorTextInput

                Nothing ->
                    model.secondaryColorTextInput
    }


clickLeaveHomeTrain : Id TrainId -> Train -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend frontendMsg )
clickLeaveHomeTrain trainId train model =
    ( { model
        | viewPoint = actualViewPoint model |> NormalViewPoint
        , trains =
            AssocList.update
                trainId
                (\_ -> Train.cancelTeleportingHome model.time train |> Just)
                model.trains
      }
    , LeaveHomeTrainRequest trainId |> Effect.Lamdera.sendToBackend
    )


clickTeleportHomeTrain : Id TrainId -> Train -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend frontendMsg )
clickTeleportHomeTrain trainId train model =
    ( { model
        | viewPoint = actualViewPoint model |> NormalViewPoint
        , trains =
            AssocList.update
                trainId
                (\_ -> Train.startTeleportingHome model.time train |> Just)
                model.trains
      }
    , TeleportHomeTrainRequest trainId model.time |> Effect.Lamdera.sendToBackend
    )


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


canOpenMailEditor : FrontendLoaded -> Bool
canOpenMailEditor model =
    case ( model.mailEditor.showMailEditor, model.currentTool ) of
        ( MailEditorClosed, HandTool ) ->
            True

        ( MailEditorClosing { startTime }, HandTool ) ->
            Duration.from startTime model.time |> Quantity.greaterThan MailEditor.openAnimationLength

        _ ->
            False


updateLocalModel : Change.LocalChange -> FrontendLoaded -> ( FrontendLoaded, LocalGrid.OutMsg )
updateLocalModel msg model =
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


scaleForScreenToWorld model =
    ( model.devicePixelRatio / (toFloat model.zoomFactor * toFloat (Coord.xRaw Units.tileSize)) |> Quantity
    , model.devicePixelRatio / (toFloat model.zoomFactor * toFloat (Coord.yRaw Units.tileSize)) |> Quantity
    )


windowResizedUpdate : Coord Pixels -> { b | windowSize : Coord Pixels } -> ( { b | windowSize : Coord Pixels }, Command FrontendOnly ToBackend msg )
windowResizedUpdate windowSize model =
    ( { model | windowSize = windowSize }
    , Command.sendToJs
        "martinsstewart_elm_device_pixel_ratio_to_js"
        martinsstewart_elm_device_pixel_ratio_to_js
        Json.Encode.null
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
    case currentUserId model of
        Just userId ->
            let
                tile =
                    Toolbar.getTileGroupTile tileGroup index

                tileData =
                    Tile.getData tile

                cursorPosition_ : Coord WorldUnit
                cursorPosition_ =
                    cursorPosition tileData model

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
                            LocalGrid.NoOutMsg ->
                                []

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

                            LocalGrid.OtherUserCursorMoved _ ->
                                []

                            LocalGrid.HandColorChanged ->
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
                                AssocList.insert trainId train model.trains

                            Nothing ->
                                model.trains
                }

        Nothing ->
            model


canPlaceTile : Effect.Time.Posix -> Grid.GridChange -> AssocList.Dict (Id TrainId) Train -> Grid -> Bool
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
                    createDebrisMeshHelper position texturePosition data.size colors appStartTime time

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
    ( Quantity Int WorldUnit, Quantity Int WorldUnit )
    -> Coord unit
    -> Coord unit
    -> Colors
    -> Effect.Time.Posix
    -> Effect.Time.Posix
    -> List DebrisVertex
createDebrisMeshHelper ( Quantity x, Quantity y ) texturePosition ( Quantity textureW, Quantity textureH ) colors appStartTime time =
    List.concatMap
        (\x2 ->
            List.concatMap
                (\y2 ->
                    let
                        { topLeft, topRight, bottomLeft, bottomRight } =
                            Tile.texturePosition_ (texturePosition |> Coord.plus (Coord.xy x2 y2)) (Coord.xy 1 1)

                        ( ( randomX, randomY ), _ ) =
                            Random.step
                                (Random.map2 Tuple.pair (Random.float -40 40) (Random.float -40 40))
                                (Random.initialSeed (Effect.Time.posixToMillis time + x2 * 3 + y2 * 5))
                    in
                    List.map
                        (\uv ->
                            let
                                offset =
                                    Vec2.vec2
                                        ((x + x2) * Coord.xRaw Units.tileSize |> toFloat)
                                        ((y + y2) * Coord.yRaw Units.tileSize |> toFloat)
                            in
                            { position = Vec2.sub (Vec2.add offset uv) topLeft
                            , initialSpeed =
                                Vec2.vec2
                                    ((toFloat x2 + 0.5 - toFloat textureW / 2) * 100 + randomX)
                                    (((toFloat y2 + 0.5 - toFloat textureH / 2) * 100) + randomY - 100)
                            , texturePosition = uv
                            , startTime = Duration.from appStartTime time |> Duration.inSeconds
                            , primaryColor = Color.toVec3 colors.primaryColor
                            , secondaryColor = Color.toVec3 colors.secondaryColor
                            }
                        )
                        [ topLeft
                        , topRight
                        , bottomRight
                        , bottomLeft
                        ]
                )
                (List.range 0 (textureH - 1))
        )
        (List.range 0 (textureW - 1))


keyDown : Keyboard.Key -> { a | pressedKeys : List Keyboard.Key } -> Bool
keyDown key { pressedKeys } =
    List.any ((==) key) pressedKeys


updateMeshes : Bool -> FrontendLoaded -> FrontendLoaded -> FrontendLoaded
updateMeshes forceUpdate oldModel newModel =
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
                Grid.foregroundMesh
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
                    (GridCell.flatten newCell)
            , background =
                case backgroundMesh of
                    Just background ->
                        background

                    Nothing ->
                        Grid.backgroundMesh coord
            }

        viewModel =
            getViewModel newModel
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
        , uiMesh =
            if (viewModel == getViewModel oldModel) && newModel.focus == oldModel.focus && not forceUpdate then
                newModel.uiMesh

            else
                Toolbar.view viewModel |> Ui.view (getUiHover newModel.focus)
    }


getUiHover : Hover -> Maybe UiHover
getUiHover hover =
    case hover of
        UiHover id _ ->
            Just id

        _ ->
            Nothing


viewBoundsUpdate : ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ ) -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
viewBoundsUpdate ( model, cmd ) =
    let
        { minX, minY, maxX, maxY } =
            viewBoundingBox model |> BoundingBox2d.extrema

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

        newBounds =
            Bounds.expand (Units.cellUnit 1) bounds
    in
    if LocalGrid.localModel model.localModel |> .viewBounds |> Bounds.containsBounds bounds then
        ( model, cmd )

    else
        ( { model
            | localModel =
                LocalGrid.update
                    (ClientChange (Change.ViewBoundsChange newBounds []))
                    model.localModel
                    |> Tuple.first
          }
        , Command.batch [ cmd, Effect.Lamdera.sendToBackend (ChangeViewBounds newBounds) ]
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

        MailEditorHover _ ->
            False

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
offsetViewPoint ({ windowSize, zoomFactor } as model) hover mouseStart mouseCurrent =
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
    case ( MailEditor.isOpen model.mailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( False, _, MouseButtonDown { start, current, hover } ) ->
            offsetViewPoint model hover start current

        ( False, MouseButtonDown { start, current, hover }, _ ) ->
            case model.currentTool of
                TilePlacerTool _ ->
                    actualViewPointHelper model

                TilePickerTool ->
                    offsetViewPoint model hover start current

                HandTool ->
                    offsetViewPoint model hover start current

        _ ->
            actualViewPointHelper model


actualViewPointHelper : FrontendLoaded -> Point2d WorldUnit WorldUnit
actualViewPointHelper model =
    case model.viewPoint of
        NormalViewPoint viewPoint ->
            viewPoint

        TrainViewPoint trainViewPoint ->
            case AssocList.get trainViewPoint.trainId model.trains of
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
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst (updateMeshes False loaded) |> Tuple.mapFirst Loaded

        _ ->
            ( model, Command.none )


handleOutMsg : LocalGrid.OutMsg -> FrontendLoaded -> FrontendLoaded
handleOutMsg outMsg model =
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

        LocalGrid.HandColorChanged ->
            let
                colors : AssocList.Dict Colors ()
                colors =
                    LocalGrid.localModel model.localModel
                        |> .handColors
                        |> IdDict.values
                        |> EverySet.fromList
                        |> EverySet.toList
                        |> List.map (\value -> ( value, () ))
                        |> AssocList.fromList
            in
            { model
                | handMeshes =
                    AssocList.merge
                        (\key _ result -> AssocList.remove key result)
                        (\_ _ _ result -> result)
                        (\key () result -> AssocList.insert key (Cursor.meshes key) result)
                        model.handMeshes
                        colors
                        model.handMeshes
            }


updateLoadedFromBackend : ToFrontend -> FrontendLoaded -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
updateLoadedFromBackend msg model =
    case msg of
        LoadingData _ ->
            ( model, Command.none )

        ChangeBroadcast changes ->
            let
                ( newLocalModel, outMsgs ) =
                    LocalGrid.updateFromBackend changes model.localModel
            in
            ( List.foldl handleOutMsg { model | localModel = newLocalModel } outMsgs, Command.none )

        UnsubscribeEmailConfirmed ->
            ( model, Command.none )

        WorldUpdateBroadcast diff ->
            ( { model
                | trains =
                    AssocList.toList diff
                        |> List.filterMap
                            (\( trainId, diff_ ) ->
                                case AssocList.get trainId model.trains |> Train.applyDiff diff_ of
                                    Just newTrain ->
                                        Just ( trainId, newTrain )

                                    Nothing ->
                                        Nothing
                            )
                        |> AssocList.fromList
              }
            , Command.none
            )

        MailEditorToFrontend mailEditorToFrontend ->
            ( { model | mailEditor = MailEditor.updateFromBackend model mailEditorToFrontend model.mailEditor }
            , Command.none
            )

        MailBroadcast mail ->
            ( { model | mail = mail }, Command.none )

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


actualTime : FrontendLoaded -> Effect.Time.Posix
actualTime model =
    Duration.addTo model.localTime debugTimeOffset


debugTimeOffset =
    Duration.seconds 0


view : AudioData -> FrontendModel_ -> Browser.Document FrontendMsg_
view audioData model =
    { title = "Town Collab"
    , body =
        [ case model of
            Loading loadingModel ->
                case loadingModel.devicePixelRatio of
                    Just devicePixelRatio ->
                        loadingCanvasView devicePixelRatio loadingModel

                    Nothing ->
                        Html.text ""

            Loaded loadedModel ->
                canvasView audioData loadedModel
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


findPixelPerfectSize :
    { a | devicePixelRatio : Float, windowSize : ( Quantity Int Pixels, Quantity Int Pixels ) }
    -> { canvasSize : ( Int, Int ), actualCanvasSize : ( Int, Int ) }
findPixelPerfectSize frontendModel =
    let
        findValue : Quantity Int Pixels -> ( Int, Int )
        findValue value =
            List.range 0 9
                |> List.map ((+) (Pixels.inPixels value))
                |> List.find
                    (\v ->
                        let
                            a =
                                toFloat v * frontendModel.devicePixelRatio
                        in
                        a == toFloat (round a) && modBy 2 (round a) == 0
                    )
                |> Maybe.map (\v -> ( v, toFloat v * frontendModel.devicePixelRatio |> round ))
                |> Maybe.withDefault ( Pixels.inPixels value, toFloat (Pixels.inPixels value) * frontendModel.devicePixelRatio |> round )

        ( w, actualW ) =
            findValue (Tuple.first frontendModel.windowSize)

        ( h, actualH ) =
            findValue (Tuple.second frontendModel.windowSize)
    in
    { canvasSize = ( w, h ), actualCanvasSize = ( actualW, actualH ) }


viewBoundingBox : FrontendLoaded -> BoundingBox2d WorldUnit WorldUnit
viewBoundingBox model =
    let
        viewMin =
            screenToWorld model Point2d.origin
                |> Point2d.translateBy
                    (Coord.tuple ( -1, -1 )
                        |> Units.cellToTile
                        |> Coord.toVector2d
                    )

        viewMax =
            screenToWorld model (Coord.toPoint2d model.windowSize)
    in
    BoundingBox2d.from viewMin viewMax


viewBoundingBox_ : FrontendLoaded -> BoundingBox2d WorldUnit WorldUnit
viewBoundingBox_ model =
    BoundingBox2d.from (screenToWorld model Point2d.origin) (screenToWorld model (Coord.toPoint2d model.windowSize))


loadingCanvasView : Float -> FrontendLoading -> Html FrontendMsg_
loadingCanvasView devicePixelRatio model =
    let
        ( windowWidth, windowHeight ) =
            actualCanvasSize

        ( cssWindowWidth, cssWindowHeight ) =
            canvasSize

        { canvasSize, actualCanvasSize } =
            findPixelPerfectSize { devicePixelRatio = devicePixelRatio, windowSize = model.windowSize }

        loadingTextPosition2 =
            loadingTextPosition devicePixelRatio model.windowSize

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
        [ Html.Attributes.width windowWidth
        , Html.Attributes.height windowHeight
        , Html.Attributes.style "cursor"
            (if showMousePointer then
                "pointer"

             else
                "default"
            )
        , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
        , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
        , Html.Events.Extra.Mouse.onDown
            (\{ clientPos, button } ->
                MouseDown button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
            )
        , Html.Events.Extra.Mouse.onMove
            (\{ clientPos } ->
                MouseMove (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
            )
        , Html.Events.Extra.Mouse.onUp
            (\{ clientPos, button } ->
                MouseUp button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
            )
        ]
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
                            |> Coord.translateMat4 (touchDevicesNotSupportedPosition devicePixelRatio model.windowSize)
                    , texture = texture
                    , textureSize = textureSize
                    , color = Vec4.vec4 1 1 1 1
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
                                            |> Coord.translateMat4 (loadingTextPosition devicePixelRatio model.windowSize)
                                    , texture = texture
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    }
                                ]
                       )

            Nothing ->
                []
        )


insideStartButton : Point2d Pixels Pixels -> { a | devicePixelRatio : Maybe Float, windowSize : Coord Pixels } -> Bool
insideStartButton mousePosition model =
    case model.devicePixelRatio of
        Just devicePixelRatio ->
            let
                mousePosition2 : Coord Pixels
                mousePosition2 =
                    mousePosition
                        |> Point2d.scaleAbout Point2d.origin devicePixelRatio
                        |> Coord.roundPoint

                loadingTextPosition2 =
                    loadingTextPosition devicePixelRatio model.windowSize
            in
            Bounds.fromCoordAndSize loadingTextPosition2 loadingTextSize |> Bounds.contains mousePosition2

        Nothing ->
            False


loadingTextPosition : Float -> Coord units -> Coord units
loadingTextPosition devicePixelRatio windowSize =
    windowSize
        |> Coord.multiplyTuple_ ( devicePixelRatio, devicePixelRatio )
        |> Coord.divide (Coord.xy 2 2)
        |> Coord.minus (Coord.divide (Coord.xy 2 2) loadingTextSize)


loadingTextSize : Coord units
loadingTextSize =
    Coord.xy 336 54


loadingTextMesh : Effect.WebGL.Mesh Vertex
loadingTextMesh =
    Sprite.text Color.black 2 "Loading..." Coord.origin
        |> Sprite.toMesh


touchDevicesNotSupportedPosition : Float -> Coord units -> Coord units
touchDevicesNotSupportedPosition devicePixelRatio windowSize =
    loadingTextPosition devicePixelRatio windowSize |> Coord.plus (Coord.yOnly loadingTextSize |> Coord.multiply (Coord.xy 1 2))


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


cursorSprite : Hover -> FrontendLoaded -> CursorType
cursorSprite hover model =
    case currentUserId model of
        Just userId ->
            let
                helper () =
                    if MailEditor.isOpen model.mailEditor then
                        DefaultCursor

                    else if isHoldingCow model /= Nothing then
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

                                    MailEditorHover _ ->
                                        DefaultCursor

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

                                    MailEditorHover _ ->
                                        DefaultCursor

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

                                    MailEditorHover _ ->
                                        DefaultCursor

                                    CowHover _ ->
                                        CursorSprite EyeDropperSpriteCursor

                                    UiHover _ _ ->
                                        PointerCursor
            in
            case isDraggingView hover model of
                Just mouse ->
                    if isSmallDistance mouse (mouseScreenPosition model) then
                        helper ()

                    else
                        CursorSprite DragScreenSpriteCursor

                Nothing ->
                    helper ()

        Nothing ->
            case hover of
                UiHover _ _ ->
                    PointerCursor

                _ ->
                    DefaultCursor


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
    case ( MailEditor.isOpen model.mailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( False, _, MouseButtonDown a ) ->
            Just a

        ( False, MouseButtonDown a, _ ) ->
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

        _ ->
            Nothing


getCursorMesh : Id UserId -> FrontendLoaded -> Maybe CursorMeshes
getCursorMesh userId model =
    AssocList.get (getHandColor userId model) model.handMeshes


getHandColor : Id UserId -> { a | localModel : LocalModel b LocalGrid } -> Colors
getHandColor userId model =
    let
        localGrid : LocalGrid_
        localGrid =
            LocalGrid.localModel model.localModel
    in
    IdDict.get userId localGrid.handColors |> Maybe.withDefault Cursor.defaultColors


canvasView : AudioData -> FrontendLoaded -> Html FrontendMsg_
canvasView audioData model =
    case Effect.WebGL.Texture.unwrap model.texture of
        Just texture ->
            let
                viewBounds_ =
                    viewBoundingBox model

                ( windowWidth, windowHeight ) =
                    actualCanvasSize

                ( cssWindowWidth, cssWindowHeight ) =
                    canvasSize

                { canvasSize, actualCanvasSize } =
                    findPixelPerfectSize model

                { x, y } =
                    Point2d.unwrap (actualViewPoint model)

                viewMatrix =
                    Mat4.makeScale3 (toFloat model.zoomFactor * 2 / toFloat windowWidth) (toFloat model.zoomFactor * -2 / toFloat windowHeight) 1
                        |> Mat4.translate3
                            (negate <| toFloat <| round (x * toFloat (Coord.xRaw Units.tileSize)))
                            (negate <| toFloat <| round (y * toFloat (Coord.yRaw Units.tileSize)))
                            0

                mouseScreenPosition_ =
                    mouseScreenPosition model

                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel

                showMousePointer =
                    cursorSprite (hoverAt model (mouseScreenPosition model)) model
            in
            Effect.WebGL.toHtmlWith
                [ Effect.WebGL.alpha False
                , Effect.WebGL.clearColor 1 1 1 1
                , Effect.WebGL.depth 1
                ]
                [ Html.Attributes.width windowWidth
                , Html.Attributes.height windowHeight
                , Cursor.htmlAttribute showMousePointer
                , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
                , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
                , Html.Events.preventDefaultOn "keydown" (Json.Decode.succeed ( NoOpFrontendMsg, True ))
                , Html.Events.Extra.Mouse.onDown
                    (\{ clientPos, button } ->
                        MouseDown button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
                    )
                , Html.Events.Extra.Mouse.onMove
                    (\{ clientPos } ->
                        MouseMove (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
                    )
                , Html.Events.Extra.Mouse.onUp
                    (\{ clientPos, button } ->
                        MouseUp button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
                    )
                , Html.Events.Extra.Wheel.onWheel MouseWheel
                ]
                (case Maybe.andThen Effect.WebGL.Texture.unwrap model.trainTexture of
                    Just trainTexture ->
                        let
                            textureSize =
                                WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2

                            meshes =
                                Dict.filter
                                    (\key _ ->
                                        Coord.tuple key
                                            |> Units.cellToTile
                                            |> Coord.toPoint2d
                                            |> (\p -> BoundingBox2d.contains p viewBounds_)
                                    )
                                    model.meshes
                        in
                        drawBackground meshes viewMatrix texture
                            ++ drawForeground meshes viewMatrix texture
                            ++ Train.draw model.time model.mail model.trains viewMatrix trainTexture
                            ++ List.filterMap
                                (\( cowId, _ ) ->
                                    case cowActualPosition cowId model of
                                        Just { position } ->
                                            let
                                                point =
                                                    Point2d.unwrap position
                                            in
                                            Effect.WebGL.entityWith
                                                [ Shaders.blend ]
                                                Shaders.vertexShader
                                                Shaders.fragmentShader
                                                cowMesh
                                                { view =
                                                    Mat4.makeTranslate3
                                                        (point.x * toFloat (Coord.xRaw Units.tileSize) |> round |> toFloat)
                                                        (point.y * toFloat (Coord.yRaw Units.tileSize) |> round |> toFloat)
                                                        (Grid.tileZ True y (Coord.yRaw cowSize))
                                                        |> Mat4.mul viewMatrix
                                                , texture = texture
                                                , textureSize = textureSize
                                                , color = Vec4.vec4 1 1 1 1
                                                }
                                                |> Just

                                        Nothing ->
                                            Nothing
                                )
                                (IdDict.toList localGrid.cows)
                            ++ List.filterMap
                                (\flag ->
                                    let
                                        flagMesh =
                                            if flag.isReceived then
                                                receivingMailFlagMeshes

                                            else
                                                sendingMailFlagMeshes
                                    in
                                    case
                                        Array.get
                                            (Effect.Time.posixToMillis model.time |> toFloat |> (*) 0.005 |> round |> modBy 3)
                                            flagMesh
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
                                                        (flagPosition.x * toFloat (Coord.xRaw Units.tileSize))
                                                        (flagPosition.y * toFloat (Coord.yRaw Units.tileSize))
                                                        0
                                                        |> Mat4.mul viewMatrix
                                                , texture = texture
                                                , textureSize = textureSize
                                                , color = Vec4.vec4 1 1 1 1
                                                }
                                                |> Just

                                        Nothing ->
                                            Nothing
                                )
                                (getFlags model)
                            ++ [ Effect.WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.debrisVertexShader
                                    Shaders.fragmentShader
                                    model.debrisMesh
                                    { view = viewMatrix
                                    , texture = texture
                                    , textureSize = textureSize
                                    , time = Duration.from model.startTime model.time |> Duration.inSeconds
                                    , color = Vec4.vec4 1 1 1 1
                                    }
                               ]
                            ++ ((case currentUserId model of
                                    Just userId ->
                                        IdDict.remove userId localGrid.cursors

                                    Nothing ->
                                        localGrid.cursors
                                )
                                    |> IdDict.toList
                                    |> List.filterMap
                                        (\( userId, cursor ) ->
                                            let
                                                point : { x : Float, y : Float }
                                                point =
                                                    cursorActualPosition False userId cursor model |> Point2d.unwrap
                                            in
                                            case getCursorMesh userId model of
                                                Just mesh ->
                                                    Effect.WebGL.entityWith
                                                        [ Shaders.blend ]
                                                        Shaders.vertexShader
                                                        Shaders.fragmentShader
                                                        (Cursor.getSpriteMesh DefaultSpriteCursor mesh)
                                                        { view =
                                                            Mat4.makeTranslate3
                                                                (round (point.x * toFloat (Coord.xRaw Units.tileSize) * toFloat model.zoomFactor)
                                                                    |> toFloat
                                                                    |> (*) (1 / toFloat model.zoomFactor)
                                                                )
                                                                (round (point.y * toFloat (Coord.yRaw Units.tileSize) * toFloat model.zoomFactor)
                                                                    |> toFloat
                                                                    |> (*) (1 / toFloat model.zoomFactor)
                                                                )
                                                                0
                                                                |> Mat4.mul viewMatrix
                                                        , texture = texture
                                                        , textureSize = textureSize
                                                        , color = Vec4.vec4 1 1 1 1
                                                        }
                                                        |> Just

                                                Nothing ->
                                                    Nothing
                                        )
                               )
                            ++ List.filterMap
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
                                                        (round (point.x * toFloat (Coord.xRaw Units.tileSize)) + xOffset |> toFloat)
                                                        (round (point.y * toFloat (Coord.yRaw Units.tileSize)) + yOffset |> toFloat)
                                                        0
                                                        |> Mat4.mul viewMatrix
                                                , texture = texture
                                                , textureSize = textureSize
                                                , color = Vec4.vec4 1 1 1 1
                                                }
                                                |> Just

                                        Nothing ->
                                            Nothing
                                )
                                (getSpeechBubbles model)
                            ++ (case ( hoverAt model mouseScreenPosition_, currentTool model, currentUserId model ) of
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

                                            lastPlacementOffset : () -> Float
                                            lastPlacementOffset () =
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
                                                            lastPlacementOffset ()

                                                    Nothing ->
                                                        lastPlacementOffset ()
                                        in
                                        [ Effect.WebGL.entityWith
                                            [ Shaders.blend ]
                                            Shaders.vertexShader
                                            Shaders.fragmentShader
                                            currentTile.mesh
                                            { view =
                                                viewMatrix
                                                    |> Mat4.translate3
                                                        (toFloat mouseX * toFloat (Coord.xRaw Units.tileSize) + offsetX)
                                                        (toFloat mouseY * toFloat (Coord.yRaw Units.tileSize))
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
                                            }
                                        ]

                                    _ ->
                                        []
                               )
                            ++ [ Effect.WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.vertexShader
                                    Shaders.fragmentShader
                                    model.uiMesh
                                    { view =
                                        Mat4.makeScale3
                                            (2 / toFloat windowWidth)
                                            (-2 / toFloat windowHeight)
                                            1
                                            |> Coord.translateMat4 (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                                    , texture = texture
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    }
                               ]
                            ++ MailEditor.drawMail
                                texture
                                (case model.mouseLeft of
                                    MouseButtonDown { current } ->
                                        current

                                    MouseButtonUp { current } ->
                                        current
                                )
                                windowWidth
                                windowHeight
                                model
                                (actualViewPoint model)
                                model.mailEditor
                            ++ (case currentUserId model of
                                    Just userId ->
                                        case IdDict.get userId localGrid.cursors of
                                            Just cursor ->
                                                case showMousePointer of
                                                    CursorSprite mousePointer ->
                                                        let
                                                            point =
                                                                cursorActualPosition True userId cursor model
                                                                    |> Point2d.unwrap
                                                        in
                                                        case getCursorMesh userId model of
                                                            Just mesh ->
                                                                [ Effect.WebGL.entityWith
                                                                    [ Shaders.blend ]
                                                                    Shaders.vertexShader
                                                                    Shaders.fragmentShader
                                                                    (Cursor.getSpriteMesh mousePointer mesh)
                                                                    { view =
                                                                        Mat4.makeTranslate3
                                                                            (round (point.x * toFloat (Coord.xRaw Units.tileSize) * toFloat model.zoomFactor)
                                                                                |> toFloat
                                                                                |> (*) (1 / toFloat model.zoomFactor)
                                                                            )
                                                                            (round (point.y * toFloat (Coord.yRaw Units.tileSize) * toFloat model.zoomFactor)
                                                                                |> toFloat
                                                                                |> (*) (1 / toFloat model.zoomFactor)
                                                                            )
                                                                            0
                                                                            |> Mat4.mul viewMatrix
                                                                    , texture = texture
                                                                    , textureSize = textureSize
                                                                    , color = Vec4.vec4 1 1 1 1
                                                                    }
                                                                ]

                                                            Nothing ->
                                                                []

                                                    _ ->
                                                        []

                                            Nothing ->
                                                []

                                    Nothing ->
                                        []
                               )

                    _ ->
                        []
                )

        Nothing ->
            Html.text ""


cursorActualPosition : Bool -> Id UserId -> Cursor -> FrontendLoaded -> Point2d WorldUnit WorldUnit
cursorActualPosition isCurrentUser userId cursor model =
    if isCurrentUser then
        cursor.position

    else
        case IdDict.get userId model.previousCursorPositions of
            Just previous ->
                Point2d.interpolateFrom
                    previous.position
                    cursor.position
                    (Quantity.ratio
                        (Duration.from previous.time model.time)
                        shortDelayDuration
                        |> clamp 0 1
                    )

            Nothing ->
                cursor.position


getFlags : FrontendLoaded -> List { position : Point2d WorldUnit WorldUnit, isReceived : Bool }
getFlags model =
    let
        localModel =
            LocalGrid.localModel model.localModel

        hasMailWaitingPickup : Id UserId -> Bool
        hasMailWaitingPickup userId =
            MailEditor.getMailFrom userId model.mail
                |> List.filter (\( _, mail ) -> mail.status == MailWaitingPickup)
                |> List.isEmpty
                |> not

        hasReceivedNewMail : Id UserId -> Bool
        hasReceivedNewMail userId =
            MailEditor.getMailTo userId model.mail
                |> List.filter (\( _, mail ) -> mail.status == MailReceived)
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
                                            |> Point2d.translateBy postOfficeSendingMailFlagOffset
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
                                                    |> Point2d.translateBy postOfficeReceivedMailFlagOffset
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


postOfficeSendingMailFlagOffset : Vector2d WorldUnit WorldUnit
postOfficeSendingMailFlagOffset =
    Vector2d.unsafe { x = 3.5, y = 2 + 1 / 18 }


postOfficeReceivedMailFlagOffset : Vector2d WorldUnit WorldUnit
postOfficeReceivedMailFlagOffset =
    Vector2d.unsafe { x = 3.5, y = 1 + 13 / 18 }


drawForeground :
    Dict ( Int, Int ) { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    -> Mat4
    -> WebGL.Texture.Texture
    -> List Effect.WebGL.Entity
drawForeground meshes viewMatrix texture =
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
                    }
            )


drawBackground :
    Dict ( Int, Int ) { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    -> Mat4
    -> WebGL.Texture.Texture
    -> List Effect.WebGL.Entity
drawBackground meshes viewMatrix texture =
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
                    }
            )


sendingMailFlagMeshes : Array (Effect.WebGL.Mesh Vertex)
sendingMailFlagMeshes =
    List.range 0 2
        |> List.map sendingMailFlagMesh
        |> Array.fromList


sendingMailFlagMesh : Int -> Effect.WebGL.Mesh Vertex
sendingMailFlagMesh frame =
    let
        width =
            11

        height =
            6

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels (Coord.xy 80 (594 + frame * 6)) (Coord.xy width 6)
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 0 0 0
          , texturePosition = topLeft
          , opacity = 1
          , primaryColor = Vec3.vec3 1 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          }
        , { position = Vec3.vec3 width 0 0
          , texturePosition = topRight
          , opacity = 1
          , primaryColor = Vec3.vec3 1 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          }
        , { position = Vec3.vec3 width height 0
          , texturePosition = bottomRight
          , opacity = 1
          , primaryColor = Vec3.vec3 1 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          }
        , { position = Vec3.vec3 0 height 0
          , texturePosition = bottomLeft
          , opacity = 1
          , primaryColor = Vec3.vec3 1 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          }
        ]


receivingMailFlagMeshes : Array (Effect.WebGL.Mesh Vertex)
receivingMailFlagMeshes =
    List.range 0 2
        |> List.map receivingMailFlagMesh
        |> Array.fromList


receivingMailFlagMesh : Int -> Effect.WebGL.Mesh Vertex
receivingMailFlagMesh frame =
    let
        width =
            11

        height =
            6

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels (Coord.xy 90 (594 + frame * 6)) (Coord.xy width 6)
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 0 0 0
          , texturePosition = topLeft
          , opacity = 1
          , primaryColor = Color.rgb255 255 161 0 |> Color.toVec3
          , secondaryColor = Vec3.vec3 0 0 0
          }
        , { position = Vec3.vec3 width 0 0
          , texturePosition = topRight
          , opacity = 1
          , primaryColor = Color.rgb255 255 161 0 |> Color.toVec3
          , secondaryColor = Vec3.vec3 0 0 0
          }
        , { position = Vec3.vec3 width height 0
          , texturePosition = bottomRight
          , opacity = 1
          , primaryColor = Color.rgb255 255 161 0 |> Color.toVec3
          , secondaryColor = Vec3.vec3 0 0 0
          }
        , { position = Vec3.vec3 0 height 0
          , texturePosition = bottomLeft
          , opacity = 1
          , primaryColor = Color.rgb255 255 161 0 |> Color.toVec3
          , secondaryColor = Vec3.vec3 0 0 0
          }
        ]


shortDelayDuration : Duration
shortDelayDuration =
    Duration.milliseconds 100


subscriptions : AudioData -> FrontendModel_ -> Subscription FrontendOnly FrontendMsg_
subscriptions _ model =
    Subscription.batch
        [ Subscription.fromJs
            "martinsstewart_elm_device_pixel_ratio_from_js"
            martinsstewart_elm_device_pixel_ratio_from_js
            (\value ->
                Json.Decode.decodeValue Json.Decode.float value
                    |> Result.withDefault 1
                    |> GotDevicePixelRatio
            )
        , Effect.Browser.Events.onResize (\width height -> WindowResized ( Pixels.pixels width, Pixels.pixels height ))
        , Effect.Browser.Events.onAnimationFrame AnimationFrame
        , Keyboard.downs KeyDown
        , readFromClipboardResponse PastedText
        , case model of
            Loading _ ->
                Subscription.fromJs
                    "user_agent_from_js"
                    user_agent_from_js
                    (\value ->
                        Json.Decode.decodeValue Json.Decode.string value
                            |> Result.withDefault ""
                            |> GotUserAgent
                    )

            Loaded loaded ->
                Subscription.batch
                    [ Subscription.map KeyMsg Keyboard.subscriptions
                    , Effect.Time.every
                        shortDelayDuration
                        (\time -> Duration.addTo time (PingData.pingOffset loaded) |> ShortIntervalElapsed)
                    , Effect.Browser.Events.onVisibilityChange (\_ -> VisibilityChanged)
                    ]
        ]


getSpeechBubbles : FrontendLoaded -> List { position : Point2d WorldUnit WorldUnit, isRadio : Bool }
getSpeechBubbles model =
    AssocList.toList model.trains
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


cowSize : Coord Pixels
cowSize =
    Coord.xy 20 14


cowSizeWorld : Vector2d WorldUnit WorldUnit
cowSizeWorld =
    Vector2d.unsafe
        { x = toFloat (Coord.xRaw cowSize) / toFloat (Coord.xRaw Units.tileSize)
        , y = toFloat (Coord.yRaw cowSize) / toFloat (Coord.yRaw Units.tileSize)
        }


cowPrimaryColor =
    Vec3.vec3 1 1 1


cowSecondaryColor =
    Vec3.vec3 0.2 0.2 0.2


insideCow : Point2d WorldUnit WorldUnit -> Point2d WorldUnit WorldUnit -> Bool
insideCow point cowPosition =
    BoundingBox2d.from
        (Point2d.translateBy (Vector2d.scaleBy 0.5 cowSizeWorld) cowPosition)
        (Point2d.translateBy (Vector2d.scaleBy -0.5 cowSizeWorld) cowPosition)
        |> BoundingBox2d.contains point


cowMesh : Effect.WebGL.Mesh Vertex
cowMesh =
    let
        ( width, height ) =
            Coord.toTuple cowSize |> Tuple.mapBoth toFloat toFloat

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels (Coord.xy 99 594) cowSize
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 (-width / 2) (-height / 2) 0
          , texturePosition = topLeft
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        , { position = Vec3.vec3 (width / 2) (-height / 2) 0
          , texturePosition = topRight
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        , { position = Vec3.vec3 (width / 2) (height / 2) 0
          , texturePosition = bottomRight
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        , { position = Vec3.vec3 (-width / 2) (height / 2) 0
          , texturePosition = bottomLeft
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        ]


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
