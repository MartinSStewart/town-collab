port module Frontend exposing
    ( app
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
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Browser.Events exposing (Visibility(..))
import Browser.Navigation
import Change exposing (Change(..))
import Coord exposing (Coord)
import Dict exposing (Dict)
import Duration exposing (Duration)
import Env
import Grid exposing (Grid)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Wheel
import Id exposing (Id, TrainId, UserId)
import Json.Decode
import Json.Encode
import Keyboard
import Keyboard.Arrows
import Lamdera
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import LocalGrid exposing (LocalGrid, LocalGrid_)
import LocalModel
import MailEditor exposing (FrontendMail, MailStatus(..), ShowMailEditor(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Set exposing (Set)
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound(..))
import Sprite
import Task
import Tile exposing (CollisionMask(..), RailPathType(..), Tile(..), TileData)
import Time
import Train exposing (Status(..), Train)
import Types exposing (..)
import Units exposing (CellUnit, MailPixelUnit, TileLocalUnit, WorldUnit)
import Url exposing (Url)
import Url.Parser exposing ((<?>))
import UrlHelper
import Vector2d exposing (Vector2d)
import WebGL exposing (Shader)
import WebGL.Settings
import WebGL.Settings.DepthTest
import WebGL.Texture exposing (Texture)


port martinsstewart_elm_device_pixel_ratio_from_js : (Float -> msg) -> Sub msg


port martinsstewart_elm_device_pixel_ratio_to_js : () -> Cmd msg


port audioPortToJS : Json.Encode.Value -> Cmd msg


port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg


app =
    Audio.lamderaFrontendWithAudio
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \audioData msg model -> update audioData msg model |> (\( a, b ) -> ( a, b, Audio.cmdNone ))
        , updateFromBackend = \_ msg model -> updateFromBackend msg model |> (\( a, b ) -> ( a, b, Audio.cmdNone ))
        , subscriptions = subscriptions
        , view = view
        , audio = audio
        , audioPort = { toJS = audioPortToJS, fromJS = audioPortFromJS }
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
        playSound =
            Sound.play model.sounds

        playWithConfig =
            Sound.playWithConfig audioData model.sounds

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
            mailEditorVolumeScale * 0.3 / ((List.map .volume movingTrains |> List.sum) + 1)

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
                        (Time.millisToPosix 0)
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
                    (Time.posixToMillis time |> Random.initialSeed)
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
    ]
        |> Audio.group


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


tryLoading : FrontendLoading -> ( FrontendModel_, Cmd FrontendMsg_ )
tryLoading frontendLoading =
    Maybe.map2
        (\time loadingData -> loadedInit time frontendLoading loadingData)
        frontendLoading.time
        frontendLoading.loadingData
        |> Maybe.withDefault ( Loading frontendLoading, Cmd.none )


defaultTileHotkeys : Dict String Tile
defaultTileHotkeys =
    Dict.fromList
        [ ( "1", EmptyTile )
        , ( "2", PostOffice )
        , ( "3", HouseDown )
        , ( "4", TrainHouseRight )
        , ( "q", RailBottomToLeft )
        , ( "w", RailBottomToLeft_SplitRight )
        , ( "e", RailBottomToRight_SplitLeft )
        , ( "r", RailStrafeRightSmall )
        , ( "a", RailStrafeRight )
        , ( "s", RailBottomToLeftLarge )
        , ( "d", RailHorizontal )
        , ( "f", RailCrossing )
        , ( "z", SidewalkHorizontalRailCrossing )
        , ( "x", Sidewalk )
        , ( "c", MowedGrass1 )
        , ( "v", MowedGrass4 )
        , ( "b", PineTree )
        ]


loadedInit : Time.Posix -> FrontendLoading -> LoadingData_ -> ( FrontendModel_, Cmd FrontendMsg_ )
loadedInit time loading loadingData =
    let
        currentTile =
            Nothing

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = LocalGrid.init loadingData
            , trains = loadingData.trains
            , meshes = Dict.empty
            , viewPoint = Coord.toPoint2d loading.viewPoint |> NormalViewPoint
            , viewPointLastInterval = Point2d.origin
            , texture = Nothing
            , trainTexture = Nothing
            , pressedKeys = []
            , windowSize = loading.windowSize
            , devicePixelRatio = loading.devicePixelRatio
            , zoomFactor = loading.zoomFactor
            , mouseLeft = MouseButtonUp { current = loading.mousePosition }
            , mouseMiddle = MouseButtonUp { current = loading.mousePosition }
            , lastMouseLeftUp = Nothing
            , pendingChanges = []
            , tool = DragTool
            , undoAddLast = Time.millisToPosix 0
            , time = time
            , startTime = time
            , userHoverHighlighted = Nothing
            , highlightContextMenu = Nothing
            , adminEnabled = False
            , animationElapsedTime = Duration.seconds 0
            , ignoreNextUrlChanged = False
            , lastTilePlaced = Nothing
            , sounds = loading.sounds
            , removedTileParticles = []
            , debrisMesh = Shaders.triangleFan []
            , lastTrainWhistle = Nothing
            , mail = loadingData.mail
            , mailEditor = MailEditor.initEditor loadingData.mailEditor
            , currentTile = currentTile
            , lastTileRotation = []
            , userIdMesh = createUserIdMesh loadingData.user
            , lastPlacementError = Nothing
            , tileHotkeys = defaultTileHotkeys
            , toolbarMesh = toolbarMesh defaultTileHotkeys currentTile
            , previousTileHover = Nothing
            , lastHouseClick = Nothing
            }
    in
    ( updateMeshes model model
    , Cmd.batch
        [ WebGL.Texture.loadWith
            { magnify = WebGL.Texture.nearest
            , minify = WebGL.Texture.nearest
            , horizontalWrap = WebGL.Texture.clampToEdge
            , verticalWrap = WebGL.Texture.clampToEdge
            , flipY = False
            }
            "/texture.png"
            |> Task.attempt TextureLoaded
        , WebGL.Texture.loadWith
            { magnify = WebGL.Texture.nearest
            , minify = WebGL.Texture.nearest
            , horizontalWrap = WebGL.Texture.clampToEdge
            , verticalWrap = WebGL.Texture.clampToEdge
            , flipY = False
            }
            "/trains.png"
            |> Task.attempt TrainTextureLoaded
        , Browser.Dom.focus "textareaId" |> Task.attempt (\_ -> NoOpFrontendMsg)
        ]
    )
        |> viewBoundsUpdate
        |> Tuple.mapFirst Loaded


init : Url -> Browser.Navigation.Key -> ( FrontendModel_, Cmd FrontendMsg_, AudioCmd FrontendMsg_ )
init url key =
    let
        { viewPoint, cmd } =
            let
                defaultRoute =
                    UrlHelper.internalRoute UrlHelper.startPointAt
            in
            case Url.Parser.parse UrlHelper.urlParser url of
                Just (UrlHelper.InternalRoute a) ->
                    { viewPoint = a.viewPoint
                    , cmd = Cmd.none
                    }

                Just (UrlHelper.EmailConfirmationRoute _) ->
                    { viewPoint = UrlHelper.startPointAt
                    , cmd = Browser.Navigation.replaceUrl key (UrlHelper.encodeUrl defaultRoute)
                    }

                Just (UrlHelper.EmailUnsubscribeRoute _) ->
                    { viewPoint = UrlHelper.startPointAt
                    , cmd = Browser.Navigation.replaceUrl key (UrlHelper.encodeUrl defaultRoute)
                    }

                Nothing ->
                    { viewPoint = UrlHelper.startPointAt
                    , cmd = Browser.Navigation.replaceUrl key (UrlHelper.encodeUrl defaultRoute)
                    }

        -- We only load in a portion of the grid since we don't know the window size yet. The rest will get loaded in later anyway.
        bounds =
            Bounds.bounds
                (Grid.worldToCellAndLocalCoord viewPoint
                    |> Tuple.first
                    |> Coord.plus ( Units.cellUnit -2, Units.cellUnit -2 )
                )
                (Grid.worldToCellAndLocalCoord viewPoint
                    |> Tuple.first
                    |> Coord.plus ( Units.cellUnit 2, Units.cellUnit 2 )
                )
    in
    ( Loading
        { key = key
        , windowSize = ( Pixels.pixels 1920, Pixels.pixels 1080 )
        , devicePixelRatio = 1
        , zoomFactor = 2
        , time = Nothing
        , viewPoint = viewPoint
        , mousePosition = Point2d.origin
        , sounds = AssocList.empty
        , loadingData = Nothing
        }
    , Cmd.batch
        [ Lamdera.sendToBackend (ConnectToBackend bounds)
        , Task.perform
            (\{ viewport } ->
                WindowResized
                    ( round viewport.width |> Pixels.pixels
                    , round viewport.height |> Pixels.pixels
                    )
            )
            Browser.Dom.getViewport
        , Task.perform ShortIntervalElapsed Time.now
        , cmd
        ]
    , Sound.load SoundLoaded
    )


update : AudioData -> FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Cmd FrontendMsg_ )
update audioData msg model =
    case model of
        Loading loadingModel ->
            case msg of
                WindowResized windowSize ->
                    windowResizedUpdate windowSize loadingModel |> Tuple.mapFirst Loading

                ShortIntervalElapsed time ->
                    tryLoading { loadingModel | time = Just time }

                GotDevicePixelRatio devicePixelRatio ->
                    devicePixelRatioUpdate devicePixelRatio loadingModel |> Tuple.mapFirst Loading

                SoundLoaded sound result ->
                    ( Loading { loadingModel | sounds = AssocList.insert sound result loadingModel.sounds }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Loaded frontendLoaded ->
            updateLoaded audioData msg frontendLoaded
                |> Tuple.mapFirst (updateMeshes frontendLoaded)
                |> viewBoundsUpdate
                |> Tuple.mapFirst Loaded


updateLoaded : AudioData -> FrontendMsg_ -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
updateLoaded audioData msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Cmd.batch [ Browser.Navigation.pushUrl model.key (Url.toString url) ]
                    )

                External url ->
                    ( model
                    , Browser.Navigation.load url
                    )

        UrlChanged url ->
            ( if model.ignoreNextUrlChanged then
                { model | ignoreNextUrlChanged = False }

              else
                case Url.Parser.parse UrlHelper.urlParser url of
                    Just (UrlHelper.InternalRoute { viewPoint }) ->
                        { model | viewPoint = Coord.toPoint2d viewPoint |> NormalViewPoint }

                    _ ->
                        model
            , Cmd.none
            )

        NoOpFrontendMsg ->
            ( model, Cmd.none )

        TextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | texture = Just texture }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        KeyMsg keyMsg ->
            ( { model | pressedKeys = Keyboard.update keyMsg model.pressedKeys }
            , Cmd.none
            )

        KeyDown rawKey ->
            case Keyboard.anyKeyOriginal rawKey of
                Just key ->
                    if MailEditor.isOpen model.mailEditor then
                        ( { model
                            | mailEditor =
                                MailEditor.handleKeyDown
                                    model
                                    (keyDown Keyboard.Control model || keyDown Keyboard.Meta model)
                                    key
                                    model.mailEditor
                          }
                        , Cmd.none
                        )

                    else
                        keyMsgCanvasUpdate key model

                Nothing ->
                    ( model, Cmd.none )

        WindowResized windowSize ->
            windowResizedUpdate windowSize model

        GotDevicePixelRatio devicePixelRatio ->
            devicePixelRatioUpdate devicePixelRatio model

        MouseDown button mousePosition ->
            let
                hover =
                    hoverAt model mousePosition
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
                                    Cmd.none
                                    (MailEditorToBackend >> Lamdera.sendToBackend)
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
                        ( model, Cmd.none )

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
                                    case ( model2.currentTile, hover ) of
                                        ( Just { tile }, MapHover ) ->
                                            placeTile False tile model2

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
                    , Cmd.none
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
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        MouseWheel event ->
            let
                rotationHelper : (Tile -> Tile) -> Tile -> FrontendLoaded
                rotationHelper rotation tile =
                    let
                        nextTile =
                            rotation tile
                    in
                    if tile == nextTile then
                        model

                    else
                        { model
                            | currentTile =
                                Just
                                    { tile = nextTile
                                    , mesh = Grid.tileMesh Coord.origin nextTile |> Sprite.toMesh
                                    }
                            , lastTileRotation =
                                model.time
                                    :: List.filter
                                        (\time ->
                                            Duration.from time model.time
                                                |> Quantity.lessThan (Sound.length audioData model.sounds WhooshSound)
                                        )
                                        model.lastTileRotation
                        }
            in
            ( if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                { model
                    | zoomFactor =
                        (if event.deltaY > 0 then
                            model.zoomFactor - 1

                         else
                            model.zoomFactor + 1
                        )
                            |> clamp 1 3
                }

              else
                case ( event.deltaY > 0, model.currentTile ) of
                    ( True, Just currentTile ) ->
                        rotationHelper Tile.rotateClockwise currentTile.tile

                    ( False, Just currentTile ) ->
                        rotationHelper Tile.rotateAntiClockwise currentTile.tile

                    ( _, Nothing ) ->
                        model
            , Cmd.none
            )

        MouseMove mousePosition ->
            let
                tileHover_ =
                    case hoverAt model mousePosition of
                        TileHover tile ->
                            Just tile

                        _ ->
                            Nothing
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
                , toolbarMesh =
                    if model.previousTileHover == tileHover_ then
                        model.toolbarMesh

                    else
                        toolbarMesh model.tileHotkeys tileHover_
                , previousTileHover = tileHover_
              }
                |> (\model2 ->
                        case ( model2.currentTile, model2.mouseLeft ) of
                            ( Just { tile }, MouseButtonDown { hover } ) ->
                                case hover of
                                    ToolbarHover ->
                                        model2

                                    TileHover _ ->
                                        model2

                                    PostOfficeHover _ ->
                                        placeTile True tile model2

                                    TrainHover _ ->
                                        placeTile True tile model2

                                    TrainHouseHover _ ->
                                        placeTile True tile model2

                                    HouseHover _ ->
                                        placeTile True tile model2

                                    MapHover ->
                                        placeTile True tile model2

                            _ ->
                                model2
                   )
            , Cmd.none
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
                            |> UrlHelper.internalRoute
                            |> UrlHelper.encodeUrl
                            |> (\a -> replaceUrl a model2)

                    else
                        ( model2, Cmd.none )

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

                model4 =
                    { model3
                        | lastTrainWhistle =
                            if playTrainWhistle then
                                Just time

                            else
                                model.lastTrainWhistle
                    }
            in
            case List.Nonempty.fromList model4.pendingChanges of
                Just nonempty ->
                    ( { model4 | pendingChanges = [] }
                    , Cmd.batch
                        [ GridChange nonempty |> Lamdera.sendToBackend
                        , urlChange
                        ]
                    )

                Nothing ->
                    ( model4, urlChange )

        ZoomFactorPressed zoomFactor ->
            ( model |> (\m -> { m | zoomFactor = zoomFactor }), Cmd.none )

        SelectToolPressed toolType ->
            ( model |> (\m -> { m | tool = toolType }), Cmd.none )

        UndoPressed ->
            ( model |> updateLocalModel Change.LocalUndo |> Tuple.first, Cmd.none )

        RedoPressed ->
            ( model |> updateLocalModel Change.LocalRedo |> Tuple.first, Cmd.none )

        CopyPressed ->
            -- TODO
            ( model, Cmd.none )

        CutPressed ->
            -- TODO
            ( model, Cmd.none )

        UnhideUserPressed userToUnhide ->
            ( updateLocalModel
                (Change.LocalUnhideUser userToUnhide)
                { model
                    | userHoverHighlighted =
                        if Just userToUnhide == model.userHoverHighlighted then
                            Nothing

                        else
                            model.userHoverHighlighted
                }
                |> Tuple.first
            , Cmd.none
            )

        UserTagMouseEntered userId ->
            ( { model | userHoverHighlighted = Just userId }, Cmd.none )

        UserTagMouseExited _ ->
            ( { model | userHoverHighlighted = Nothing }, Cmd.none )

        HideForAllTogglePressed userToHide ->
            ( updateLocalModel (Change.LocalToggleUserVisibilityForAll userToHide) model |> Tuple.first, Cmd.none )

        ToggleAdminEnabledPressed ->
            ( if Just (currentUserId model) == Env.adminUserId then
                { model | adminEnabled = not model.adminEnabled }

              else
                model
            , Cmd.none
            )

        HideUserPressed { userId, hidePoint } ->
            ( { model | highlightContextMenu = Nothing }
                |> updateLocalModel (Change.LocalHideUser userId hidePoint)
                |> Tuple.first
            , Cmd.none
            )

        AnimationFrame time ->
            let
                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel

                oldViewPoint =
                    actualViewPoint model

                newViewPoint =
                    Point2d.translateBy
                        (Keyboard.Arrows.arrows model.pressedKeys
                            |> (\{ x, y } -> Vector2d.unsafe { x = toFloat x, y = toFloat -y })
                        )
                        oldViewPoint

                movedViewWithArrowKeys =
                    Keyboard.Arrows.arrows model.pressedKeys /= { x = 0, y = 0 }

                model2 =
                    { model
                        | time = time
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
                    }
            in
            ( case ( ( movedViewWithArrowKeys, model.viewPoint ), model2.mouseLeft, model2.currentTile ) of
                ( ( True, _ ), MouseButtonDown _, Just currentTile ) ->
                    placeTile True currentTile.tile model2

                ( ( _, TrainViewPoint _ ), MouseButtonDown _, Just currentTile ) ->
                    placeTile True currentTile.tile model2

                _ ->
                    model2
            , Cmd.none
            )

        SoundLoaded sound result ->
            ( { model | sounds = AssocList.insert sound result model.sounds }, Cmd.none )

        VisibilityChanged ->
            ( { model | currentTile = Nothing }, Cmd.none )

        TrainTextureLoaded result ->
            case result of
                Ok texture ->
                    ( { model | trainTexture = Just texture }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


hoverAt : FrontendLoaded -> Point2d Pixels Pixels -> Hover
hoverAt model mousePosition =
    let
        mousePosition2 : Coord Pixels
        mousePosition2 =
            mousePosition
                |> Point2d.scaleAbout Point2d.origin model.devicePixelRatio
                |> Coord.roundPoint

        toolbarTopLeft : Coord Pixels
        toolbarTopLeft =
            toolbarToPixel
                model.devicePixelRatio
                model.windowSize
                Coord.origin

        containsToolbar : Bool
        containsToolbar =
            Bounds.bounds toolbarTopLeft (Coord.plus toolbarSize toolbarTopLeft) |> Bounds.contains mousePosition2
    in
    if containsToolbar then
        let
            containsTileButton : Maybe Tile
            containsTileButton =
                List.indexedMap
                    (\index tile ->
                        let
                            topLeft =
                                toolbarToPixel
                                    model.devicePixelRatio
                                    model.windowSize
                                    (toolbarTileButtonPosition index)
                        in
                        if
                            Bounds.bounds topLeft (Coord.plus toolbarButtonSize topLeft)
                                |> Bounds.contains mousePosition2
                        then
                            Just tile

                        else
                            Nothing
                    )
                    buttonTiles
                    |> List.filterMap identity
                    |> List.head
        in
        case containsTileButton of
            Just tile ->
                TileHover tile

            Nothing ->
                ToolbarHover

    else
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
                case ( model.currentTile, Grid.getTile (Coord.floorPoint mouseWorldPosition_) localModel.grid ) of
                    ( Nothing, Just tile ) ->
                        case tile.value of
                            PostOffice ->
                                if tile.userId == localModel.user then
                                    PostOfficeHover { postOfficePosition = tile.position } |> Just

                                else
                                    Nothing

                            TrainHouseLeft ->
                                TrainHouseHover { trainHousePosition = tile.position } |> Just

                            TrainHouseRight ->
                                TrainHouseHover { trainHousePosition = tile.position } |> Just

                            HouseDown ->
                                HouseHover { housePosition = tile.position } |> Just

                            HouseLeft ->
                                HouseHover { housePosition = tile.position } |> Just

                            HouseUp ->
                                HouseHover { housePosition = tile.position } |> Just

                            HouseRight ->
                                HouseHover { housePosition = tile.position } |> Just

                            _ ->
                                Nothing

                    _ ->
                        Nothing

            trainHovers : Maybe ( { trainId : Id TrainId, train : Train }, Quantity Float WorldUnit )
            trainHovers =
                case model.currentTile of
                    Just _ ->
                        Nothing

                    Nothing ->
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
        in
        case ( trainHovers, tileHover ) of
            ( Just ( train, _ ), _ ) ->
                TrainHover train

            ( Nothing, Just hover ) ->
                hover

            ( Nothing, Nothing ) ->
                MapHover


replaceUrl : String -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
replaceUrl url model =
    ( { model | ignoreNextUrlChanged = True }, Browser.Navigation.replaceUrl model.key url )


keyMsgCanvasUpdate : Keyboard.Key -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
keyMsgCanvasUpdate key model =
    let
        ctrlOrMeta =
            keyDown Keyboard.Control model || keyDown Keyboard.Meta model

        handleRedo () =
            if ctrlOrMeta then
                ( updateLocalModel Change.LocalRedo model |> Tuple.first, Cmd.none )

            else
                ( model, Cmd.none )
    in
    case ( key, ctrlOrMeta ) of
        ( Keyboard.Character "z", True ) ->
            if ctrlOrMeta then
                ( updateLocalModel Change.LocalUndo model |> Tuple.first, Cmd.none )

            else
                ( model, Cmd.none )

        ( Keyboard.Character "Z", True ) ->
            handleRedo ()

        ( Keyboard.Character "y", True ) ->
            handleRedo ()

        ( Keyboard.Escape, _ ) ->
            ( case model.currentTile of
                Just _ ->
                    { model | currentTile = Nothing }

                Nothing ->
                    { model
                        | viewPoint =
                            case model.viewPoint of
                                TrainViewPoint _ ->
                                    actualViewPoint model |> NormalViewPoint

                                NormalViewPoint _ ->
                                    model.viewPoint
                    }
            , Cmd.none
            )

        ( Keyboard.Spacebar, True ) ->
            ( { model | tileHotkeys = Dict.update " " (\_ -> Maybe.map .tile model.currentTile) model.tileHotkeys }
            , Cmd.none
            )

        ( Keyboard.Character string, True ) ->
            ( { model | tileHotkeys = Dict.update string (\_ -> Maybe.map .tile model.currentTile) model.tileHotkeys }
            , Cmd.none
            )

        ( Keyboard.Spacebar, False ) ->
            ( case Dict.get " " model.tileHotkeys of
                Just tile ->
                    setCurrentTile tile model

                Nothing ->
                    model
            , Cmd.none
            )

        ( Keyboard.Character string, False ) ->
            ( case Dict.get string model.tileHotkeys of
                Just tile ->
                    setCurrentTile tile model

                Nothing ->
                    model
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


setCurrentTile : Tile -> FrontendLoaded -> FrontendLoaded
setCurrentTile tile model =
    { model
        | currentTile =
            Just { tile = tile, mesh = Grid.tileMesh Coord.origin tile |> Sprite.toMesh }
    }


mainMouseButtonUp :
    Point2d Pixels Pixels
    -> { a | start : Point2d Pixels Pixels, hover : Hover }
    -> FrontendLoaded
    -> ( FrontendLoaded, Cmd FrontendMsg_ )
mainMouseButtonUp mousePosition previousMouseState model =
    let
        isSmallDistance =
            Vector2d.from previousMouseState.start mousePosition
                |> Vector2d.length
                |> Quantity.lessThan (Pixels.pixels 5)

        model2 =
            { model
                | mouseLeft = MouseButtonUp { current = mousePosition }
                , viewPoint =
                    case ( MailEditor.isOpen model.mailEditor, model.mouseMiddle, model.tool ) of
                        ( False, MouseButtonUp _, DragTool ) ->
                            case model.currentTile of
                                Just _ ->
                                    model.viewPoint

                                Nothing ->
                                    offsetViewPoint
                                        model
                                        previousMouseState.hover
                                        previousMouseState.start
                                        mousePosition
                                        |> NormalViewPoint

                        _ ->
                            model.viewPoint
                , highlightContextMenu =
                    if isSmallDistance then
                        Nothing

                    else
                        model.highlightContextMenu
                , lastMouseLeftUp = Just ( model.time, mousePosition )
            }
    in
    if isSmallDistance then
        case hoverAt model mousePosition of
            TileHover tileHover_ ->
                ( setCurrentTile tileHover_ model2, Cmd.none )

            PostOfficeHover { postOfficePosition } ->
                ( if canOpenMailEditor model2 then
                    { model2
                        | mailEditor =
                            MailEditor.open
                                model2
                                (Coord.toPoint2d postOfficePosition
                                    |> Point2d.translateBy (Vector2d.unsafe { x = 1, y = 1.5 })
                                    |> worldToScreen model2
                                )
                                model2.mailEditor
                    }

                  else
                    model2
                , Cmd.none
                )

            TrainHover { trainId, train } ->
                case Train.status model.time train of
                    WaitingAtHome ->
                        ( { model2
                            | viewPoint = actualViewPoint model2 |> NormalViewPoint
                            , trains =
                                AssocList.update
                                    trainId
                                    (\_ -> Train.cancelTeleportingHome model.time train |> Just)
                                    model2.trains
                          }
                        , LeaveHomeTrainRequest trainId |> Lamdera.sendToBackend
                        )

                    TeleportingHome _ ->
                        ( { model2
                            | viewPoint = actualViewPoint model2 |> NormalViewPoint
                            , trains =
                                AssocList.update
                                    trainId
                                    (\_ -> Train.leaveHome model.time train |> Just)
                                    model2.trains
                          }
                        , CancelTeleportHomeTrainRequest trainId |> Lamdera.sendToBackend
                        )

                    _ ->
                        case Train.isStuck model.time train of
                            Just stuckTime ->
                                if Duration.from stuckTime model2.time |> Quantity.lessThan stuckMessageDelay then
                                    ( setTrainViewPoint trainId model2, Cmd.none )

                                else
                                    ( { model2
                                        | viewPoint = actualViewPoint model2 |> NormalViewPoint
                                        , trains =
                                            AssocList.update
                                                trainId
                                                (\_ -> Train.startTeleportingHome model2.time train |> Just)
                                                model2.trains
                                      }
                                    , TeleportHomeTrainRequest trainId |> Lamdera.sendToBackend
                                    )

                            Nothing ->
                                ( setTrainViewPoint trainId model2, Cmd.none )

            ToolbarHover ->
                ( model2, Cmd.none )

            TrainHouseHover _ ->
                ( model2, Cmd.none )

            HouseHover _ ->
                ( { model2 | lastHouseClick = Just model.time }, Cmd.none )

            MapHover ->
                ( case previousMouseState.hover of
                    TrainHover { trainId, train } ->
                        setTrainViewPoint trainId model2

                    _ ->
                        model2
                , Cmd.none
                )

    else
        ( model2, Cmd.none )


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
    case ( model.mailEditor.showMailEditor, model.currentTile ) of
        ( MailEditorClosed, Nothing ) ->
            True

        ( MailEditorClosing { startTime }, Nothing ) ->
            Duration.from startTime model.time |> Quantity.greaterThan MailEditor.openAnimationLength

        _ ->
            False


updateLocalModel : Change.LocalChange -> FrontendLoaded -> ( FrontendLoaded, LocalGrid.OutMsg )
updateLocalModel msg model =
    let
        ( newLocalModel, outMsg ) =
            LocalGrid.update model.time (LocalChange msg) model.localModel
    in
    ( { model
        | pendingChanges = model.pendingChanges ++ [ msg ]
        , localModel = newLocalModel
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
        >> Point2d.at (scaleForScreenToWorld model)
        >> Point2d.placeIn (Units.screenFrame (actualViewPoint model))


worldToScreen : FrontendLoaded -> Point2d WorldUnit WorldUnit -> Point2d Pixels Pixels
worldToScreen model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5 |> Vector2d.reverse)
        << Point2d.at_ (scaleForScreenToWorld model)
        << Point2d.relativeTo (Units.screenFrame (actualViewPoint model))


scaleForScreenToWorld model =
    model.devicePixelRatio / (toFloat model.zoomFactor * Units.tileSize) |> Quantity


windowResizedUpdate : Coord Pixels -> { b | windowSize : Coord Pixels } -> ( { b | windowSize : Coord Pixels }, Cmd msg )
windowResizedUpdate windowSize model =
    ( { model | windowSize = windowSize }, martinsstewart_elm_device_pixel_ratio_to_js () )


devicePixelRatioUpdate :
    Float
    -> { b | devicePixelRatio : Float, zoomFactor : Int }
    -> ( { b | devicePixelRatio : Float, zoomFactor : Int }, Cmd msg )
devicePixelRatioUpdate devicePixelRatio model =
    ( { model | devicePixelRatio = devicePixelRatio }, Cmd.none )


mouseWorldPosition : FrontendLoaded -> Point2d WorldUnit WorldUnit
mouseWorldPosition model =
    mouseScreenPosition model |> screenToWorld model


mouseScreenPosition : FrontendLoaded -> Point2d Pixels Pixels
mouseScreenPosition model =
    case model.mouseLeft of
        MouseButtonDown { current } ->
            current

        MouseButtonUp { current } ->
            current


cursorPosition : TileData -> FrontendLoaded -> Coord WorldUnit
cursorPosition tileData model =
    mouseWorldPosition model
        |> Coord.floorPoint
        |> Coord.minus (Coord.tuple tileData.size |> Coord.divide (Coord.tuple ( 2, 2 )))


placeTile : Bool -> Tile -> FrontendLoaded -> FrontendLoaded
placeTile isDragPlacement tile model =
    let
        tileData =
            Tile.getData tile

        cursorPosition_ : Coord WorldUnit
        cursorPosition_ =
            cursorPosition tileData model

        hasCollision : Bool
        hasCollision =
            case model.lastTilePlaced of
                Just lastPlaced ->
                    Tile.hasCollision cursorPosition_ tileData lastPlaced.position (Tile.getData lastPlaced.tile)

                Nothing ->
                    False

        change =
            { position = cursorPosition_
            , change = tile
            , userId = currentUserId model
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
                        }
                    )
                    model2

            removedTiles : List { time : Time.Posix, tile : Tile, position : Coord WorldUnit }
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
                                }
                            )
                            tiles
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
                case Train.handleAddingTrain model3.trains tile cursorPosition_ of
                    Just ( trainId, train ) ->
                        AssocList.insert trainId train model.trains

                    Nothing ->
                        model.trains
        }


canPlaceTile : Time.Posix -> Grid.GridChange -> AssocList.Dict (Id TrainId) Train -> Grid -> Bool
canPlaceTile time change trains grid =
    if Grid.canPlaceTile change then
        let
            trains_ =
                AssocList.toList trains
        in
        Grid.addChange change grid
            |> .removed
            |> List.all
                (\{ tile, position } ->
                    if tile == TrainHouseLeft || tile == TrainHouseRight then
                        List.any
                            (\( _, train ) -> Train.home train == position && Train.status time train == WaitingAtHome)
                            trains_

                    else
                        True
                )

    else
        False


createDebrisMesh : Time.Posix -> List RemovedTileParticle -> WebGL.Mesh DebrisVertex
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

                            ( _, height ) =
                                Tile.getData tile |> .size
                        in
                        y + height
                    )
    in
    List.map
        (\{ position, tile, time } ->
            let
                data =
                    Tile.getData tile
            in
            createDebrisMeshHelper position data.texturePosition data.size appStartTime time
                ++ (case data.texturePositionTopLayer of
                        Just topLayer ->
                            createDebrisMeshHelper position topLayer.texturePosition data.size appStartTime time

                        Nothing ->
                            []
                   )
        )
        list
        |> List.concat
        |> Sprite.toMesh


createDebrisMeshHelper :
    ( Quantity Int WorldUnit, Quantity Int WorldUnit )
    -> ( Int, Int )
    -> ( Int, Int )
    -> Time.Posix
    -> Time.Posix
    -> List DebrisVertex
createDebrisMeshHelper ( Quantity x, Quantity y ) ( textureX, textureY ) ( textureW, textureH ) appStartTime time =
    List.concatMap
        (\x2 ->
            List.concatMap
                (\y2 ->
                    let
                        { topLeft, topRight, bottomLeft, bottomRight } =
                            Tile.texturePosition_ ( textureX + x2, textureY + y2 ) ( 1, 1 )

                        ( ( randomX, randomY ), _ ) =
                            Random.step
                                (Random.map2 Tuple.pair (Random.float -40 40) (Random.float -40 40))
                                (Random.initialSeed (Time.posixToMillis time + x2 * 3 + y2 * 5))
                    in
                    List.map
                        (\uv ->
                            let
                                offset =
                                    Vec2.vec2
                                        ((x + x2) * Units.tileSize |> toFloat)
                                        ((y + y2) * Units.tileSize |> toFloat)
                            in
                            { position = Vec2.sub (Vec2.add offset uv) topLeft
                            , initialSpeed =
                                Vec2.vec2
                                    ((toFloat x2 + 0.5 - toFloat textureW / 2) * 100 + randomX)
                                    (((toFloat y2 + 0.5 - toFloat textureH / 2) * 100) + randomY - 100)
                            , texturePosition = uv
                            , startTime = Duration.from appStartTime time |> Duration.inSeconds
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

        currentTile : FrontendLoaded -> Maybe { tile : Tile, position : Coord WorldUnit, cellPosition : Set ( Int, Int ) }
        currentTile model =
            case model.currentTile of
                Just { tile } ->
                    let
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
                    }
                        |> Just

                Nothing ->
                    Nothing

        oldCurrentTile =
            currentTile oldModel

        newCurrentTile : Maybe { tile : Tile, position : Coord WorldUnit, cellPosition : Set ( Int, Int ) }
        newCurrentTile =
            currentTile newModel

        currentTileUnchanged =
            oldCurrentTile == newCurrentTile

        newMesh : Maybe (WebGL.Mesh Vertex) -> GridCell.Cell -> ( Int, Int ) -> { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
        newMesh backgroundMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.tuple rawCoord
            in
            { foreground =
                Grid.foregroundMesh
                    (case newCurrentTile of
                        Just newCurrentTile_ ->
                            if
                                canPlaceTile
                                    newModel.time
                                    { userId = currentUserId newModel
                                    , position = newCurrentTile_.position
                                    , change = newCurrentTile_.tile
                                    }
                                    newModel.trains
                                    localModel.grid
                            then
                                newCurrentTile

                            else
                                Nothing

                        Nothing ->
                            newCurrentTile
                    )
                    coord
                    localModel.user
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


viewBoundsUpdate : ( FrontendLoaded, Cmd FrontendMsg_ ) -> ( FrontendLoaded, Cmd FrontendMsg_ )
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
                    model.time
                    (ClientChange (Change.ViewBoundsChange newBounds []))
                    model.localModel
                    |> Tuple.first
          }
        , Cmd.batch [ cmd, Lamdera.sendToBackend (ChangeViewBounds newBounds) ]
        )


offsetViewPoint :
    FrontendLoaded
    -> Hover
    -> Point2d Pixels Pixels
    -> Point2d Pixels Pixels
    -> Point2d WorldUnit WorldUnit
offsetViewPoint ({ windowSize, zoomFactor } as model) hover mouseStart mouseCurrent =
    let
        canDragView =
            case hover of
                PostOfficeHover _ ->
                    True

                TrainHover _ ->
                    True

                ToolbarHover ->
                    False

                TileHover _ ->
                    False

                TrainHouseHover _ ->
                    True

                HouseHover _ ->
                    True

                MapHover ->
                    True
    in
    if canDragView then
        let
            delta : Vector2d WorldUnit WorldUnit
            delta =
                Vector2d.from mouseCurrent mouseStart
                    |> Vector2d.at (scaleForScreenToWorld model)
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
            case model.currentTile of
                Just _ ->
                    actualViewPointHelper model

                Nothing ->
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


updateFromBackend : ToFrontend -> FrontendModel_ -> ( FrontendModel_, Cmd FrontendMsg_ )
updateFromBackend msg model =
    case ( model, msg ) of
        ( Loading loading, LoadingData loadingData ) ->
            tryLoading { loading | loadingData = Just loadingData }

        ( Loaded loaded, _ ) ->
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst (updateMeshes loaded) |> Tuple.mapFirst Loaded

        _ ->
            ( model, Cmd.none )


updateLoadedFromBackend : ToFrontend -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
updateLoadedFromBackend msg model =
    case msg of
        LoadingData _ ->
            ( model, Cmd.none )

        ChangeBroadcast changes ->
            ( { model
                | localModel = LocalGrid.updateFromBackend changes model.localModel
              }
            , Cmd.none
            )

        UnsubscribeEmailConfirmed ->
            ( model, Cmd.none )

        TrainBroadcast trains ->
            ( { model | trains = trains }, Cmd.none )

        MailEditorToFrontend mailEditorToFrontend ->
            ( { model | mailEditor = MailEditor.updateFromBackend model mailEditorToFrontend model.mailEditor }
            , Cmd.none
            )

        MailBroadcast mail ->
            ( { model | mail = mail }, Cmd.none )


lostConnection : FrontendLoaded -> Bool
lostConnection model =
    case LocalModel.localMsgs model.localModel of
        ( time, _ ) :: _ ->
            Duration.from time model.time |> Quantity.greaterThan (Duration.seconds 10)

        [] ->
            False


view : AudioData -> FrontendModel_ -> Browser.Document FrontendMsg_
view audioData model =
    { title =
        case model of
            Loading _ ->
                "Town Collab"

            Loaded loadedModel ->
                if lostConnection loadedModel then
                    "Town Collab (offline)"

                else
                    "Town Collab"
    , body =
        [ case model of
            Loading _ ->
                Html.text "Loading"

            Loaded loadedModel ->
                canvasView audioData loadedModel
        , Html.node "style" [] [ Html.text "body { overflow: hidden; margin: 0; }" ]
        ]
    }


currentUserId : FrontendLoaded -> Id UserId
currentUserId =
    .localModel >> LocalGrid.localModel >> .user


findPixelPerfectSize : FrontendLoaded -> { canvasSize : ( Int, Int ), actualCanvasSize : ( Int, Int ) }
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


canvasView : AudioData -> FrontendLoaded -> Html FrontendMsg_
canvasView audioData model =
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
                    (negate <| toFloat <| round (x * Units.tileSize))
                    (negate <| toFloat <| round (y * Units.tileSize))
                    0

        mouseScreenPosition_ =
            mouseScreenPosition model

        showMousePointer =
            if MailEditor.isOpen model.mailEditor then
                False

            else
                case hoverAt model mouseScreenPosition_ of
                    TileHover _ ->
                        True

                    ToolbarHover ->
                        False

                    PostOfficeHover _ ->
                        True

                    TrainHover _ ->
                        True

                    TrainHouseHover _ ->
                        True

                    HouseHover _ ->
                        True

                    MapHover ->
                        False
    in
    WebGL.toHtmlWith
        [ WebGL.alpha False
        , WebGL.antialias
        , WebGL.clearColor 1 1 1 1
        , WebGL.depth 1
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
        (case ( model.texture, model.trainTexture ) of
            ( Just texture, Just trainTexture ) ->
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
                                    (Time.posixToMillis model.time |> toFloat |> (*) 0.005 |> round |> modBy 3)
                                    flagMesh
                            of
                                Just flagMesh_ ->
                                    let
                                        flagPosition =
                                            Point2d.unwrap flag.position
                                    in
                                    WebGL.entityWith
                                        [ Shaders.blend ]
                                        Shaders.vertexShader
                                        Shaders.fragmentShader
                                        flagMesh_
                                        { view =
                                            Mat4.makeTranslate3
                                                (flagPosition.x * Units.tileSize)
                                                (flagPosition.y * Units.tileSize)
                                                0
                                                |> Mat4.mul viewMatrix
                                        , texture = texture
                                        , textureSize = textureSize
                                        }
                                        |> Just

                                Nothing ->
                                    Nothing
                        )
                        (getFlags model)
                    ++ [ WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.debrisVertexShader
                            Shaders.fragmentShader
                            model.debrisMesh
                            { view = viewMatrix
                            , texture = texture
                            , textureSize = textureSize
                            , time = Duration.from model.startTime model.time |> Duration.inSeconds
                            }
                       ]
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
                                    (Time.posixToMillis model.time
                                        |> toFloat
                                        |> (*) 0.01
                                        |> round
                                        |> modBy speechBubbleFrames
                                    )
                                    meshArray
                            of
                                Just mesh ->
                                    WebGL.entityWith
                                        [ Shaders.blend ]
                                        Shaders.vertexShader
                                        Shaders.fragmentShader
                                        mesh
                                        { view =
                                            Mat4.makeTranslate3
                                                (round (point.x * Units.tileSize) + xOffset |> toFloat)
                                                (round (point.y * Units.tileSize) + yOffset |> toFloat)
                                                0
                                                |> Mat4.mul viewMatrix
                                        , texture = texture
                                        , textureSize = textureSize
                                        }
                                        |> Just

                                Nothing ->
                                    Nothing
                        )
                        (getSpeechBubbles model)
                    ++ (case ( hoverAt model mouseScreenPosition_, model.currentTile ) of
                            ( MapHover, Just currentTile ) ->
                                let
                                    mousePosition : Coord WorldUnit
                                    mousePosition =
                                        mouseWorldPosition model
                                            |> Coord.floorPoint
                                            |> Coord.minus (tileSize |> Coord.divide (Coord.tuple ( 2, 2 )))

                                    ( mouseX, mouseY ) =
                                        Coord.toTuple mousePosition

                                    tileSize =
                                        Tile.getData currentTile.tile |> .size |> Coord.tuple

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
                                [ WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.colorAndTextureVertexShader
                                    Shaders.colorAndTextureFragmentShader
                                    currentTile.mesh
                                    { view =
                                        viewMatrix
                                            |> Mat4.translate3
                                                (toFloat mouseX * Units.tileSize + offsetX)
                                                (toFloat mouseY * Units.tileSize)
                                                0
                                    , texture = texture
                                    , textureSize = textureSize
                                    , color =
                                        if currentTile.tile == EmptyTile then
                                            Vec4.vec4 1 1 1 1

                                        else if
                                            canPlaceTile
                                                model.time
                                                { position = mousePosition
                                                , change = currentTile.tile
                                                , userId = currentUserId model
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
                    ++ [ WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            model.userIdMesh
                            { view =
                                Mat4.makeScale3
                                    (2 / toFloat windowWidth)
                                    (-2 / toFloat windowHeight)
                                    1
                                    |> Coord.translateMat4
                                        (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                            , texture = texture
                            , textureSize = textureSize
                            }
                       , WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            model.toolbarMesh
                            { view =
                                Mat4.makeScale3
                                    (2 / toFloat windowWidth)
                                    (-2 / toFloat windowHeight)
                                    1
                                    |> Coord.translateMat4
                                        (Coord.tuple ( -windowWidth // 2, -windowHeight // 2 ))
                                    |> Coord.translateMat4 (toolbarPosition model.devicePixelRatio model.windowSize)
                            , texture = texture
                            , textureSize = textureSize
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

            _ ->
                []
        )


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
    Dict ( Int, Int ) { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
    -> Mat4
    -> Texture
    -> List WebGL.Entity
drawForeground meshes viewMatrix texture =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                WebGL.entityWith
                    [ WebGL.Settings.cullFace WebGL.Settings.back
                    , WebGL.Settings.DepthTest.default
                    , Shaders.blend
                    ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    mesh.foreground
                    { view = viewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    }
            )


drawBackground :
    Dict ( Int, Int ) { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
    -> Mat4
    -> Texture
    -> List WebGL.Entity
drawBackground meshes viewMatrix texture =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                WebGL.entityWith
                    [ WebGL.Settings.cullFace WebGL.Settings.back
                    , WebGL.Settings.DepthTest.default
                    , Shaders.blend
                    ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    mesh.background
                    { view = viewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    }
            )


sendingMailFlagMeshes : Array (WebGL.Mesh Vertex)
sendingMailFlagMeshes =
    List.range 0 2
        |> List.map sendingMailFlagMesh
        |> Array.fromList


sendingMailFlagMesh : Int -> WebGL.Mesh Vertex
sendingMailFlagMesh frame =
    let
        width =
            11

        height =
            6

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels ( 72, 594 + frame * 6 ) ( width, 6 )
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 0 0 0, texturePosition = topLeft, opacity = 1 }
        , { position = Vec3.vec3 width 0 0, texturePosition = topRight, opacity = 1 }
        , { position = Vec3.vec3 width height 0, texturePosition = bottomRight, opacity = 1 }
        , { position = Vec3.vec3 0 height 0, texturePosition = bottomLeft, opacity = 1 }
        ]


receivingMailFlagMeshes : Array (WebGL.Mesh Vertex)
receivingMailFlagMeshes =
    List.range 0 2
        |> List.map receivingMailFlagMesh
        |> Array.fromList


receivingMailFlagMesh : Int -> WebGL.Mesh Vertex
receivingMailFlagMesh frame =
    let
        width =
            11

        height =
            6

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels ( 90, 594 + frame * 6 ) ( width, 6 )
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 0 0 0, texturePosition = topLeft, opacity = 1 }
        , { position = Vec3.vec3 width 0 0, texturePosition = topRight, opacity = 1 }
        , { position = Vec3.vec3 width height 0, texturePosition = bottomRight, opacity = 1 }
        , { position = Vec3.vec3 0 height 0, texturePosition = bottomLeft, opacity = 1 }
        ]


createUserIdMesh : Id UserId -> WebGL.Mesh Vertex
createUserIdMesh userId =
    let
        id =
            "USER ID: " ++ String.fromInt (Id.toInt userId)

        vertices =
            Sprite.text 2 id (Coord.xy 2 2)
    in
    Shaders.indexedTriangles vertices (Sprite.getQuadIndices vertices)


subscriptions : AudioData -> FrontendModel_ -> Sub FrontendMsg_
subscriptions _ model =
    Sub.batch
        [ martinsstewart_elm_device_pixel_ratio_from_js GotDevicePixelRatio
        , Browser.Events.onResize (\width height -> WindowResized ( Pixels.pixels width, Pixels.pixels height ))
        , case model of
            Loading _ ->
                Sub.none

            Loaded _ ->
                Sub.batch
                    [ Sub.map KeyMsg Keyboard.subscriptions
                    , Keyboard.downs KeyDown
                    , Time.every 1000 ShortIntervalElapsed
                    , Browser.Events.onAnimationFrame AnimationFrame
                    , Browser.Events.onVisibilityChange (\_ -> VisibilityChanged)
                    ]
        ]


toolbarSize : Coord Pixels
toolbarSize =
    Coord.xy 748 174


toolbarPosition : Float -> Coord Pixels -> Coord Pixels
toolbarPosition devicePixelRatio windowSize =
    windowSize
        |> Coord.multiplyTuple_ ( devicePixelRatio, devicePixelRatio )
        |> Coord.divide (Coord.xy 2 1)
        |> Coord.plus (Coord.xy 0 -4)
        |> Coord.minus (Coord.divide (Coord.xy 2 1) toolbarSize)


toolbarButtonSize : Coord units
toolbarButtonSize =
    Coord.xy 80 80


toolbarTileButton : Maybe String -> Bool -> Coord ToolbarUnit -> Tile -> List Vertex
toolbarTileButton maybeHotkey highlight offset tile =
    let
        charSize =
            Sprite.charSize |> Coord.multiplyTuple ( 2, 2 )
    in
    Sprite.sprite (Coord.toTuple offset)
        toolbarButtonSize
        ( if highlight then
            379

          else
            380
        , 153
        )
        ( 1, 1 )
        ++ Sprite.sprite
            (offset |> Coord.plus (Coord.xy 2 2) |> Coord.toTuple)
            (toolbarButtonSize |> Coord.minus (Coord.xy 4 4))
            ( if highlight then
                379

              else
                381
            , 153
            )
            ( 1, 1 )
        ++ tileMesh offset tile
        ++ (case maybeHotkey of
                Just hotkey ->
                    Sprite.sprite
                        (Coord.plus
                            (Coord.xy 0 (Coord.yRaw toolbarButtonSize - Coord.yRaw charSize + 4))
                            offset
                            |> Coord.toTuple
                        )
                        (Coord.plus (Coord.xy 2 -4) charSize)
                        ( 380, 153 )
                        ( 1, 1 )
                        ++ Sprite.text
                            2
                            hotkey
                            (Coord.plus
                                (Coord.xy 2 (Coord.yRaw toolbarButtonSize - Coord.yRaw charSize))
                                offset
                            )

                Nothing ->
                    []
           )


toolbarMesh : Dict String Tile -> Maybe Tile -> WebGL.Mesh Vertex
toolbarMesh hotkeys currentTile =
    Sprite.sprite ( 0, 0 ) toolbarSize ( 380, 153 ) ( 1, 1 )
        ++ Sprite.sprite ( 2, 2 ) (toolbarSize |> Coord.minus (Coord.xy 4 4)) ( 381, 153 ) ( 1, 1 )
        ++ (List.indexedMap
                (\index tile ->
                    toolbarTileButton
                        (Dict.toList hotkeys |> List.find (Tuple.second >> (==) tile) |> Maybe.map Tuple.first)
                        (Just tile == currentTile)
                        (toolbarTileButtonPosition index)
                        tile
                )
                buttonTiles
                |> List.concat
           )
        |> Sprite.toMesh


buttonTiles : List Tile
buttonTiles =
    [ EmptyTile
    , PostOffice
    , HouseDown
    , TrainHouseRight
    , RailBottomToLeft
    , RailBottomToLeft_SplitRight
    , RailBottomToRight_SplitLeft
    , RailStrafeRightSmall
    , RailStrafeRight
    , RailBottomToLeftLarge
    , RailHorizontal
    , RailCrossing
    , SidewalkHorizontalRailCrossing
    , Sidewalk
    , MowedGrass1
    , MowedGrass4
    , PineTree
    ]


type ToolbarUnit
    = ToolbarUnit Never


toolbarTileButtonPosition : Int -> Coord ToolbarUnit
toolbarTileButtonPosition index =
    Coord.xy
        ((Coord.xRaw toolbarButtonSize + 2) * (index // 2) + 6)
        ((Coord.yRaw toolbarButtonSize + 2) * modBy 2 index + 6)


toolbarToPixel : Float -> Coord Pixels -> Coord ToolbarUnit -> Coord Pixels
toolbarToPixel devicePixelRatio windowSize coord =
    toolbarPosition devicePixelRatio windowSize |> Coord.changeUnit |> Coord.plus coord |> Coord.changeUnit


tileMesh : Coord unit -> Tile -> List Vertex
tileMesh position tile =
    let
        data : TileData
        data =
            Tile.getData tile

        size : Coord units
        size =
            Coord.multiplyTuple ( Units.tileSize, Units.tileSize ) (Coord.tuple data.size)
                |> Coord.minimum toolbarButtonSize

        spriteSize =
            if data.size == ( 1, 1 ) then
                Coord.multiplyTuple ( 2, 2 ) size

            else
                size

        position2 =
            position |> Coord.minus (Coord.divide (Coord.xy 2 2) spriteSize) |> Coord.plus (Coord.divide (Coord.xy 2 2) toolbarButtonSize)

        texturePosition : Coord units
        texturePosition =
            Coord.multiplyTuple ( Units.tileSize, Units.tileSize ) (Coord.tuple data.texturePosition)
    in
    if tile == EmptyTile then
        Sprite.sprite
            (Coord.plus (Coord.xy 10 12) position |> Coord.toTuple)
            (Coord.tuple ( 30 * 2, 29 * 2 ))
            ( 324, 223 )
            ( 30, 29 )

    else
        Sprite.sprite (Coord.toTuple position2) spriteSize (Coord.toTuple texturePosition) (Coord.toTuple size)
            ++ (case data.texturePositionTopLayer of
                    Just topLayer ->
                        let
                            texturePosition2 =
                                Coord.multiplyTuple ( Units.tileSize, Units.tileSize ) (Coord.tuple topLayer.texturePosition)
                        in
                        Sprite.sprite (Coord.toTuple position2) spriteSize (Coord.toTuple texturePosition2) (Coord.toTuple size)

                    Nothing ->
                        []
               )


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


speechBubbleMesh : Array (WebGL.Mesh Vertex)
speechBubbleMesh =
    List.range 0 (speechBubbleFrames - 1)
        |> List.map (\frame -> speechBubbleMeshHelper frame ( 391, 154 ) ( 8, 12 ))
        |> Array.fromList


speechBubbleRadioMesh : Array (WebGL.Mesh Vertex)
speechBubbleRadioMesh =
    List.range 0 (speechBubbleFrames - 1)
        |> List.map (\frame -> speechBubbleMeshHelper frame ( 399, 154 ) ( 8, 13 ))
        |> Array.fromList


speechBubbleFrames =
    3


speechBubbleMeshHelper frame bubbleTailTexturePosition bubbleTailTextureSize =
    let
        text =
            "Help!"

        padding =
            Coord.xy 6 5
    in
    Sprite.nineSlice
        { topLeft = Coord.xy 378 154
        , top = Coord.xy 384 154
        , topRight = Coord.xy 385 154
        , left = Coord.xy 378 160
        , center = Coord.xy 384 160
        , right = Coord.xy 385 160
        , bottomLeft = Coord.xy 378 161
        , bottom = Coord.xy 384 161
        , bottomRight = Coord.xy 385 161
        , cornerSize = Coord.xy 6 6
        , position = Coord.xy 0 0
        , size = Sprite.textSize 1 text |> Coord.plus (Coord.multiplyTuple ( 2, 2 ) padding)
        }
        ++ Sprite.shiverText frame 1 "Help!" padding
        ++ Sprite.sprite ( 7, 27 ) (Coord.xy 8 12) bubbleTailTexturePosition bubbleTailTextureSize
        |> Sprite.toMesh
