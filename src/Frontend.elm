port module Frontend exposing
    ( app
    , init
    , update
    , updateFromBackend
    , view
    )

import Angle
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
import Direction2d
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Env
import EverySet exposing (EverySet)
import Grid exposing (Grid, Vertex)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Wheel
import Icons
import Id exposing (Id, TrainId, UserId)
import Json.Decode
import Json.Encode
import Keyboard
import Lamdera
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import LocalGrid exposing (LocalGrid, LocalGrid_)
import LocalModel
import MailEditor exposing (ShowMailEditor(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Shaders exposing (DebrisVertex)
import Sound exposing (Sound(..))
import Task
import Tile exposing (RailPathType(..), Tile(..))
import Time
import Train exposing (Train)
import Types exposing (..)
import UiColors
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

        movingTrains =
            List.filterMap
                (\( _, train ) ->
                    if abs (Quantity.unwrap train.speed) > 0.1 then
                        let
                            position =
                                Train.actualPosition train
                        in
                        Just
                            { playbackRate = 0.9 * (abs (Quantity.unwrap train.speed) / Train.maxSpeed) + 0.1
                            , volume = volume model position * Quantity.unwrap train.speed / Train.maxSpeed |> abs
                            }

                    else
                        Nothing
                )
                (AssocList.toList model.trains)

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
            mailEditorVolumeScale * 0.5 / ((List.map .volume movingTrains |> List.sum) + 1)

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


loadedInit : Time.Posix -> FrontendLoading -> LoadingData_ -> ( FrontendModel_, Cmd FrontendMsg_ )
loadedInit time loading loadingData =
    let
        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = LocalGrid.init loadingData
            , trains = loadingData.trains
            , meshes = Dict.empty
            , viewPoint = Coord.toPoint2d loading.viewPoint
            , viewPointLastInterval = Point2d.origin
            , texture = Nothing
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
            , debrisMesh = WebGL.triangleFan []
            , lastTrainWhistle = Nothing
            , mail = loadingData.mail
            , mailEditor = MailEditor.initEditor loadingData.mailEditor
            , currentTile = Nothing
            , lastTileRotation = []
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
                    |> Coord.addTuple ( Units.cellUnit -2, Units.cellUnit -2 )
                )
                (Grid.worldToCellAndLocalCoord viewPoint
                    |> Tuple.first
                    |> Coord.addTuple ( Units.cellUnit 2, Units.cellUnit 2 )
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
                        { model
                            | viewPoint = viewPoint |> Coord.toPoint2d
                        }

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
                        ( { model | mailEditor = MailEditor.handleKeyDown model key model.mailEditor }, Cmd.none )

                    else
                        keyMsgCanvasUpdate key model

                Nothing ->
                    ( model, Cmd.none )

        WindowResized windowSize ->
            windowResizedUpdate windowSize model

        GotDevicePixelRatio devicePixelRatio ->
            devicePixelRatioUpdate devicePixelRatio model

        MouseDown button mousePosition ->
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
                                    { start = mousePosition, start_ = screenToWorld model mousePosition, current = mousePosition }
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
                                    { start = mousePosition, start_ = screenToWorld model mousePosition, current = mousePosition }
                        }
                            |> (\model2 ->
                                    case model2.currentTile of
                                        Just { tile } ->
                                            placeTile tile model2

                                        Nothing ->
                                            model2
                               )

                      else if button == MiddleButton then
                        { model
                            | mouseMiddle =
                                MouseButtonDown
                                    { start = mousePosition, start_ = screenToWorld model mousePosition, current = mousePosition }
                        }

                      else
                        model
                    , Browser.Dom.focus "textareaId" |> Task.attempt (\_ -> NoOpFrontendMsg)
                    )

        MouseUp button mousePosition ->
            case ( button, model.mouseLeft, model.mouseMiddle ) of
                ( MainButton, MouseButtonDown mouseState, _ ) ->
                    mainMouseButtonUp mousePosition mouseState model

                ( MiddleButton, _, MouseButtonDown mouseState ) ->
                    ( { model
                        | mouseMiddle = MouseButtonUp { current = mousePosition }
                        , viewPoint =
                            if MailEditor.isOpen model.mailEditor then
                                model.viewPoint

                            else
                                offsetViewPoint model mouseState.start mousePosition
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
                            | currentTile = Just { tile = nextTile, mesh = Grid.tileMesh Coord.origin nextTile }
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
            ( case ( event.deltaY > 0, model.currentTile ) of
                ( True, Just currentTile ) ->
                    rotationHelper Tile.rotateClockwise currentTile.tile

                ( False, Just currentTile ) ->
                    rotationHelper Tile.rotateAntiClockwise currentTile.tile

                ( _, Nothing ) ->
                    model
            , Cmd.none
            )

        MouseMove mousePosition ->
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
              }
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
                            Duration.from whistleTime time |> Quantity.greaterThan (Duration.seconds 120)

                        Nothing ->
                            True
                    )
                        && List.any
                            (\( _, train ) -> BoundingBox2d.contains (Train.actualPosition train) viewBounds)
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
            ( model |> updateLocalModel Change.LocalUndo, Cmd.none )

        RedoPressed ->
            ( model |> updateLocalModel Change.LocalRedo, Cmd.none )

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
            , Cmd.none
            )

        UserTagMouseEntered userId ->
            ( { model | userHoverHighlighted = Just userId }, Cmd.none )

        UserTagMouseExited _ ->
            ( { model | userHoverHighlighted = Nothing }, Cmd.none )

        HideForAllTogglePressed userToHide ->
            ( updateLocalModel (Change.LocalToggleUserVisibilityForAll userToHide) model, Cmd.none )

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
            , Cmd.none
            )

        AnimationFrame time ->
            let
                localGrid : LocalGrid_
                localGrid =
                    LocalGrid.localModel model.localModel
            in
            ( { model
                | time = time
                , animationElapsedTime = Duration.from model.time time |> Quantity.plus model.animationElapsedTime
                , trains =
                    AssocList.map
                        (\_ train ->
                            Train.moveTrain
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
              }
            , Cmd.none
            )

        SoundLoaded sound result ->
            ( { model | sounds = AssocList.insert sound result model.sounds }, Cmd.none )

        VisibilityChanged ->
            ( { model | currentTile = Nothing }, Cmd.none )


replaceUrl : String -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
replaceUrl url model =
    ( { model | ignoreNextUrlChanged = True }, Browser.Navigation.replaceUrl model.key url )


keyMsgCanvasUpdate : Keyboard.Key -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
keyMsgCanvasUpdate key model =
    let
        handleUndo () =
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                if MailEditor.isOpen model.mailEditor then
                    ( { model | mailEditor = MailEditor.undo model.mailEditor }, Cmd.none )

                else
                    ( updateLocalModel Change.LocalUndo model, Cmd.none )

            else
                ( model, Cmd.none )

        handleRedo () =
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                if MailEditor.isOpen model.mailEditor then
                    ( { model | mailEditor = MailEditor.redo model.mailEditor }, Cmd.none )

                else
                    ( updateLocalModel Change.LocalRedo model, Cmd.none )

            else
                ( model, Cmd.none )
    in
    case ( key, keyDown Keyboard.Control model, keyDown Keyboard.Meta model ) of
        ( Keyboard.Character "z", True, _ ) ->
            handleUndo ()

        ( Keyboard.Character "z", _, True ) ->
            handleUndo ()

        ( Keyboard.Character "Z", True, _ ) ->
            handleRedo ()

        ( Keyboard.Character "Z", _, True ) ->
            handleRedo ()

        ( Keyboard.Character "y", True, _ ) ->
            handleRedo ()

        ( Keyboard.Character "y", _, True ) ->
            handleRedo ()

        ( Keyboard.Escape, _, _ ) ->
            ( { model | currentTile = Nothing }, Cmd.none )

        ( Keyboard.Spacebar, False, False ) ->
            ( case Tile.fromChar ' ' of
                Just tile ->
                    { model | currentTile = Just { tile = tile, mesh = Grid.tileMesh Coord.origin tile } }

                Nothing ->
                    model
            , Cmd.none
            )

        ( Keyboard.Character char, False, False ) ->
            ( case String.toList char of
                head :: _ ->
                    case Tile.fromChar head of
                        Just tile ->
                            { model | currentTile = Just { tile = tile, mesh = Grid.tileMesh Coord.origin tile } }

                        Nothing ->
                            model

                [] ->
                    model
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


mainMouseButtonUp :
    Point2d Pixels Pixels
    -> { a | start : Point2d Pixels Pixels }
    -> FrontendLoaded
    -> ( FrontendLoaded, Cmd FrontendMsg_ )
mainMouseButtonUp mousePosition mouseState model =
    let
        isSmallDistance =
            Vector2d.from mouseState.start mousePosition
                |> Vector2d.length
                |> Quantity.lessThan (Pixels.pixels 5)

        model2 =
            { model
                | mouseLeft = MouseButtonUp { current = mousePosition }
                , viewPoint =
                    case ( MailEditor.isOpen model.mailEditor, model.mouseMiddle, model.tool ) of
                        ( False, MouseButtonUp _, DragTool ) ->
                            offsetViewPoint model mouseState.start mousePosition

                        _ ->
                            model.viewPoint
                , highlightContextMenu =
                    if isSmallDistance then
                        Nothing

                    else
                        model.highlightContextMenu
                , lastMouseLeftUp = Just ( model.time, mousePosition )
            }

        canOpenMailEditor =
            case ( model.mailEditor.showMailEditor, model.currentTile ) of
                ( MailEditorClosed, Nothing ) ->
                    True

                ( MailEditorClosing { startTime }, Nothing ) ->
                    Duration.from startTime model.time |> Quantity.greaterThan MailEditor.openAnimationLength

                _ ->
                    False
    in
    ( if isSmallDistance && canOpenMailEditor then
        let
            localModel : LocalGrid_
            localModel =
                LocalGrid.localModel model2.localModel

            maybeTile : Maybe { userId : Id UserId, value : Tile, position : Coord WorldUnit }
            maybeTile =
                Grid.getTile (screenToWorld model2 mousePosition |> Coord.floorPoint) localModel.grid
        in
        case maybeTile of
            Just tile ->
                if tile.userId == localModel.user && tile.value == PostOffice then
                    { model2
                        | mailEditor =
                            MailEditor.open
                                model
                                (Coord.toPoint2d tile.position
                                    |> Point2d.translateBy (Vector2d.unsafe { x = 1, y = 1.5 })
                                    |> worldToScreen model2
                                )
                                model.mailEditor
                    }

                else
                    model2

            Nothing ->
                model2

      else
        model2
    , Cmd.none
    )


updateLocalModel : Change.LocalChange -> FrontendLoaded -> FrontendLoaded
updateLocalModel msg model =
    { model
        | pendingChanges = model.pendingChanges ++ [ msg ]
        , localModel = LocalGrid.update model.time (LocalChange msg) model.localModel
    }


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
    (case model.mouseLeft of
        MouseButtonDown { current } ->
            current

        MouseButtonUp { current } ->
            current
    )
        |> screenToWorld model


placeTile : Tile -> FrontendLoaded -> FrontendLoaded
placeTile tile model =
    let
        model2 =
            if Duration.from model.undoAddLast model.time |> Quantity.greaterThan (Duration.seconds 0.5) then
                updateLocalModel Change.LocalAddUndo { model | undoAddLast = model.time }

            else
                model

        tileSize : ( Int, Int )
        tileSize =
            Tile.getData tile |> .size

        cursorPosition =
            mouseWorldPosition model
                |> Coord.floorPoint
                |> Coord.minusTuple (Coord.fromTuple tileSize |> Coord.divideTuple (Coord.fromTuple ( 2, 2 )))

        ( cellPos, localPos ) =
            Grid.worldToCellAndLocalCoord cursorPosition

        neighborCells : List ( Coord CellUnit, Coord Units.CellLocalUnit )
        neighborCells =
            ( cellPos, localPos ) :: Grid.closeNeighborCells cellPos localPos

        oldGrid : Grid
        oldGrid =
            LocalGrid.localModel model2.localModel |> .grid

        model3 =
            updateLocalModel
                (Change.LocalGridChange
                    { position = cursorPosition
                    , change = tile
                    }
                )
                model2

        newGrid : Grid
        newGrid =
            LocalGrid.localModel model3.localModel |> .grid

        removedTiles =
            List.concatMap
                (\( neighborCellPos, _ ) ->
                    let
                        oldCell : List { userId : Id UserId, position : Coord Units.CellLocalUnit, value : Tile }
                        oldCell =
                            Grid.getCell neighborCellPos oldGrid |> Maybe.map GridCell.flatten |> Maybe.withDefault []

                        newCell : List { userId : Id UserId, position : Coord Units.CellLocalUnit, value : Tile }
                        newCell =
                            Grid.getCell neighborCellPos newGrid |> Maybe.map GridCell.flatten |> Maybe.withDefault []
                    in
                    List.foldl
                        (\item state ->
                            if List.any ((==) item) newCell then
                                state

                            else
                                { time = model.time
                                , tile = item.value
                                , position = Grid.cellAndLocalCoordToAscii ( neighborCellPos, item.position )
                                }
                                    :: state
                        )
                        []
                        oldCell
                )
                neighborCells
    in
    { model3
        | lastTilePlaced =
            Just
                { time = model.time
                , overwroteTiles = List.isEmpty removedTiles |> not
                , tile = tile
                }
        , removedTileParticles = removedTiles ++ model3.removedTileParticles
        , debrisMesh = createDebrisMesh model.startTime (removedTiles ++ model3.removedTileParticles)
    }


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

        indices : List ( Int, Int, Int )
        indices =
            List.map
                (\{ tile } ->
                    let
                        data =
                            Tile.getData tile

                        ( textureW, textureH ) =
                            data.size
                    in
                    textureW
                        * textureH
                        * (case data.texturePositionTopLayer of
                            Just _ ->
                                2

                            Nothing ->
                                1
                          )
                )
                list
                |> List.sum
                |> (+) -1
                |> List.range 0
                |> List.concatMap Grid.getIndices
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
        |> (\vertices -> WebGL.indexedTriangles vertices indices)


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

        showHighlighted : { a | userHoverHighlighted : Maybe b } -> EverySet b -> EverySet b
        showHighlighted model hidden =
            EverySet.diff
                hidden
                ([ model.userHoverHighlighted ]
                    |> List.filterMap identity
                    |> EverySet.fromList
                )

        oldHidden : EverySet (Id UserId)
        oldHidden =
            LocalGrid.localModel oldModel.localModel |> .hiddenUsers |> showHighlighted oldModel

        oldHiddenForAll : EverySet (Id UserId)
        oldHiddenForAll =
            LocalGrid.localModel oldModel.localModel |> .adminHiddenUsers |> showHighlighted oldModel

        newCells : Dict ( Int, Int ) GridCell.Cell
        newCells =
            LocalGrid.localModel newModel.localModel |> .grid |> Grid.allCellsDict

        newHidden : EverySet (Id UserId)
        newHidden =
            LocalGrid.localModel newModel.localModel |> .hiddenUsers |> showHighlighted newModel

        newHiddenForAll : EverySet (Id UserId)
        newHiddenForAll =
            LocalGrid.localModel newModel.localModel |> .adminHiddenUsers |> showHighlighted newModel

        newMesh : GridCell.Cell -> ( Int, Int ) -> WebGL.Mesh Grid.Vertex
        newMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.fromTuple rawCoord
            in
            Grid.mesh
                coord
                (GridCell.flatten newCell)

        hiddenUnchanged : Bool
        hiddenUnchanged =
            oldHidden == newHidden && oldHiddenForAll == newHiddenForAll

        hiddenChanges : List (Id UserId)
        hiddenChanges =
            EverySet.union (EverySet.diff newHidden oldHidden) (EverySet.diff oldHidden newHidden)
                |> EverySet.union (EverySet.diff newHiddenForAll oldHiddenForAll)
                |> EverySet.union (EverySet.diff oldHiddenForAll newHiddenForAll)
                |> EverySet.toList
    in
    { newModel
        | meshes =
            Dict.map
                (\coord newCell ->
                    case Dict.get coord oldCells of
                        Just oldCell ->
                            if oldCell == newCell then
                                case Dict.get coord newModel.meshes of
                                    Just mesh ->
                                        if hiddenUnchanged then
                                            mesh

                                        else if List.any (\userId -> GridCell.hasChangesBy userId newCell) hiddenChanges then
                                            newMesh newCell coord

                                        else
                                            mesh

                                    Nothing ->
                                        newMesh newCell coord

                            else
                                newMesh newCell coord

                        Nothing ->
                            newMesh newCell coord
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
                |> Coord.addTuple ( Units.cellUnit 1, Units.cellUnit 1 )

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
          }
        , Cmd.batch [ cmd, Lamdera.sendToBackend (ChangeViewBounds newBounds) ]
        )


offsetViewPoint :
    FrontendLoaded
    -> Point2d Pixels Pixels
    -> Point2d Pixels Pixels
    -> Point2d WorldUnit WorldUnit
offsetViewPoint ({ windowSize, viewPoint, devicePixelRatio, zoomFactor } as model) mouseStart mouseCurrent =
    let
        delta : Vector2d WorldUnit WorldUnit
        delta =
            Vector2d.from mouseCurrent mouseStart
                |> Vector2d.at (scaleForScreenToWorld model)
                |> Vector2d.placeIn (Units.screenFrame viewPoint)
    in
    Point2d.translateBy delta viewPoint


actualViewPoint : FrontendLoaded -> Point2d WorldUnit WorldUnit
actualViewPoint model =
    case ( MailEditor.isOpen model.mailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( False, _, MouseButtonDown { start, current } ) ->
            offsetViewPoint model start current

        ( False, MouseButtonDown { start, current }, _ ) ->
            case model.tool of
                DragTool ->
                    offsetViewPoint model start current

        _ ->
            model.viewPoint


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

        TrainUpdate trains ->
            ( { model | trains = trains }, Cmd.none )

        MailEditorToFrontend mailEditorToFrontend ->
            ( { model | mailEditor = MailEditor.updateFromBackend model mailEditorToFrontend model.mailEditor }, Cmd.none )


lostConnection : FrontendLoaded -> Bool
lostConnection model =
    case LocalModel.localMsgs model.localModel of
        ( time, _ ) :: _ ->
            Duration.from time model.time |> Quantity.greaterThan (Duration.seconds 10)

        [] ->
            False


view : AudioData -> FrontendModel_ -> Browser.Document FrontendMsg_
view _ model =
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
                Element.layout
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    ]
                    (Element.text "Loading")

            Loaded loadedModel ->
                Element.layout
                    (Element.width Element.fill
                        :: Element.height Element.fill
                        :: Element.clip
                        :: Element.inFront
                            (if MailEditor.isOpen loadedModel.mailEditor then
                                Element.none

                             else
                                toolbarView loadedModel
                            )
                        :: Element.htmlAttribute (Html.Events.Extra.Mouse.onContextMenu (\_ -> NoOpFrontendMsg))
                        :: mouseAttributes
                    )
                    (Element.html (canvasView loadedModel))
        , Html.node "style"
            []
            [ Html.text "@font-face { font-family: ascii; src: url('ascii.ttf'); }" ]
        ]
    }


offlineWarningView : Element msg
offlineWarningView =
    Element.text "⚠ Unable to reach server. Your changes won't be saved."
        |> Element.el
            [ Element.Background.color UiColors.warning
            , Element.padding 8
            , Element.Border.rounded 4
            , Element.centerX
            , Element.moveUp 8
            ]


mouseAttributes : List (Element.Attribute FrontendMsg_)
mouseAttributes =
    [ Html.Events.Extra.Mouse.onMove
        (\{ clientPos } ->
            MouseMove (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
        )
    , Html.Events.Extra.Mouse.onUp
        (\{ clientPos, button } ->
            MouseUp button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
        )
    , Html.Events.Extra.Wheel.onWheel MouseWheel
    ]
        |> List.map Element.htmlAttribute


currentUserId : FrontendLoaded -> Id UserId
currentUserId =
    .localModel >> LocalGrid.localModel >> .user


canUndo : FrontendLoaded -> Bool
canUndo model =
    LocalGrid.localModel model.localModel |> .undoHistory |> List.isEmpty |> not


canRedo : FrontendLoaded -> Bool
canRedo model =
    LocalGrid.localModel model.localModel |> .redoHistory |> List.isEmpty |> not


toolbarView : FrontendLoaded -> Element FrontendMsg_
toolbarView model =
    let
        zoomView =
            List.range 1 3
                |> List.map
                    (\zoom ->
                        toolbarButton
                            [ if model.zoomFactor == zoom then
                                Element.Background.color UiColors.buttonActive

                              else
                                Element.Background.color UiColors.button
                            ]
                            (ZoomFactorPressed zoom)
                            True
                            (Element.el [ Element.moveDown 1 ] (Element.text (String.fromInt zoom ++ "x")))
                    )

        toolView =
            List.map
                (\( toolDefault, isTool, icon ) ->
                    toolbarButton
                        [ if isTool model.tool then
                            Element.Background.color UiColors.buttonActive

                          else
                            Element.Background.color UiColors.button
                        ]
                        (SelectToolPressed toolDefault)
                        True
                        icon
                )
                tools

        undoRedoView =
            [ toolbarButton
                []
                UndoPressed
                (canUndo model)
                (Element.image
                    [ Element.width (Element.px 22) ]
                    { src = "undo.svg", description = "Undo button" }
                )
            , toolbarButton
                []
                RedoPressed
                (canRedo model)
                (Element.image
                    [ Element.width (Element.px 22) ]
                    { src = "redo.svg", description = "Undo button" }
                )
            ]

        copyView =
            [ toolbarButton
                []
                CopyPressed
                True
                (Element.image
                    [ Element.width (Element.px 22) ]
                    { src = "copy.svg", description = "Copy text button" }
                )
            , toolbarButton
                []
                CutPressed
                True
                (Element.image
                    [ Element.width (Element.px 22) ]
                    { src = "cut.svg", description = "Cut text button" }
                )
            ]

        groups =
            [ Element.el [ Element.paddingXY 4 0 ] (Element.text "🔎") :: zoomView
            , toolView
            , undoRedoView
            , copyView
            ]
                |> List.map (Element.row [ Element.spacing 2 ])
    in
    Element.wrappedRow
        [ Element.Background.color UiColors.background
        , Element.spacingXY 10 8
        , Element.padding 6
        , Element.Border.color UiColors.border
        , Element.Border.width 1
        , Element.Border.rounded 3
        , Element.Font.color UiColors.text
        , Element.above
            (if lostConnection model then
                offlineWarningView

             else
                Element.none
            )
        ]
        groups
        |> Element.el
            [ Element.paddingXY 8 0
            , Element.alignBottom
            , Element.centerX
            , Element.moveUp 8
            ]


tools : List ( ToolType, ToolType -> Bool, Element msg )
tools =
    [ ( DragTool, (==) DragTool, Icons.dragTool )
    ]


toolbarButton : List (Element.Attribute msg) -> msg -> Bool -> Element msg -> Element msg
toolbarButton attributes onPress isEnabled label =
    Element.Input.button
        (Element.Background.color UiColors.button
            :: Element.width (Element.px 40)
            :: Element.height (Element.px 40)
            :: Element.mouseOver
                (if isEnabled then
                    [ Element.Background.color UiColors.buttonActive ]

                 else
                    []
                )
            :: Element.Border.width 1
            :: Element.Border.rounded 2
            :: Element.Border.color UiColors.border
            :: attributes
        )
        { onPress = Just onPress
        , label =
            Element.el
                [ if isEnabled then
                    Element.alpha 1

                  else
                    Element.alpha 0.5
                , Element.centerX
                , Element.centerY
                ]
                label
        }


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
                    (Coord.fromTuple ( -1, -1 )
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


canvasView : FrontendLoaded -> Html FrontendMsg_
canvasView model =
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
    in
    WebGL.toHtmlWith
        [ WebGL.alpha False
        , WebGL.antialias
        , WebGL.clearColor 0.8 1 0.7 1
        , WebGL.depth 1
        ]
        [ Html.Attributes.width windowWidth
        , Html.Attributes.height windowHeight
        , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
        , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
        , Html.Events.Extra.Mouse.onDown
            (\{ clientPos, button } ->
                MouseDown button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
            )
        ]
        (case model.texture of
            Just texture ->
                let
                    textureSize =
                        WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                in
                drawText
                    (Dict.filter
                        (\key _ ->
                            Coord.fromTuple key
                                |> Units.cellToTile
                                |> Coord.toPoint2d
                                |> (\p -> BoundingBox2d.contains p viewBounds_)
                        )
                        model.meshes
                    )
                    viewMatrix
                    texture
                    ++ drawTrains model.trains viewMatrix texture
                    ++ List.filterMap
                        (\flag ->
                            case
                                Array.get
                                    (Time.posixToMillis model.time |> toFloat |> (*) 0.005 |> round |> modBy 3)
                                    flagMeshes
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
                    ++ (case model.currentTile of
                            Just currentTile ->
                                let
                                    ( mouseX, mouseY ) =
                                        mouseWorldPosition model |> Coord.floorPoint |> Coord.toTuple

                                    ( w, h ) =
                                        Tile.getData currentTile.tile |> .size
                                in
                                [ WebGL.entityWith
                                    [ Shaders.blend ]
                                    Shaders.colorAndTextureVertexShader
                                    Shaders.colorAndTextureFragmentShader
                                    currentTile.mesh
                                    { view =
                                        viewMatrix
                                            |> Mat4.translate3
                                                (toFloat (mouseX - (w // 2)) * Units.tileSize)
                                                (toFloat (mouseY - (h // 2)) * Units.tileSize)
                                                0
                                    , texture = texture
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 0.5
                                    , time = Duration.from model.startTime model.time |> Duration.inSeconds
                                    }
                                ]

                            Nothing ->
                                []
                       )
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
                        model.mailEditor

            Nothing ->
                []
        )


getFlags : FrontendLoaded -> List { position : Point2d WorldUnit WorldUnit }
getFlags model =
    let
        localModel =
            LocalGrid.localModel model.localModel
    in
    Bounds.coordRangeFold
        (\coord postOffices ->
            case Grid.getCell coord localModel.grid of
                Just cell ->
                    List.filterMap
                        (\tile ->
                            if
                                (tile.value == PostOffice)
                                    && List.any (\mail -> mail.from == tile.userId) (AssocList.values model.mail)
                            then
                                Just
                                    { position =
                                        Grid.cellAndLocalCoordToAscii ( coord, tile.position )
                                            |> Coord.toPoint2d
                                            |> Point2d.translateBy postOfficeFlagOffset
                                    }

                            else
                                Nothing
                        )
                        (GridCell.flatten cell)
                        ++ postOffices

                Nothing ->
                    postOffices
        )
        identity
        localModel.viewBounds
        []


postOfficeFlagOffset : Vector2d WorldUnit WorldUnit
postOfficeFlagOffset =
    Vector2d.unsafe { x = 3.5, y = 1 + 13 / 18 }


drawText : Dict ( Int, Int ) (WebGL.Mesh Grid.Vertex) -> Mat4 -> Texture -> List WebGL.Entity
drawText meshes viewMatrix texture =
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
                    mesh
                    { view = viewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                    }
            )


drawTrains : AssocList.Dict (Id TrainId) Train -> Mat4 -> Texture -> List WebGL.Entity
drawTrains trains viewMatrix texture =
    List.concatMap
        (\( _, train ) ->
            let
                railData =
                    Tile.railPathData train.path

                { x, y } =
                    Train.actualPosition train |> Point2d.unwrap

                trainFrame =
                    Direction2d.angleFrom
                        Direction2d.x
                        (Tile.pathDirection railData.path train.t
                            |> (if Quantity.lessThanZero train.speed then
                                    Direction2d.reverse

                                else
                                    identity
                               )
                        )
                        |> Angle.inTurns
                        |> (*) 20
                        |> round
                        |> modBy 20
            in
            case Array.get trainFrame trainMeshes of
                Just trainMesh_ ->
                    [ WebGL.entityWith
                        [ WebGL.Settings.DepthTest.default, Shaders.blend ]
                        Shaders.vertexShader
                        Shaders.fragmentShader
                        trainMesh_
                        { view = Mat4.makeTranslate3 (x * Units.tileSize) (y * Units.tileSize) (Grid.tileZ True y 0) |> Mat4.mul viewMatrix
                        , texture = texture
                        , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                        }
                    ]

                Nothing ->
                    []
        )
        (AssocList.toList trains)


trainFrames =
    20


trainMeshes : Array (WebGL.Mesh Vertex)
trainMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map trainMesh
        |> Array.fromList


trainMesh : Int -> WebGL.Mesh Vertex
trainMesh frame =
    let
        offsetY =
            -5

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePosition_ ( 11, frame * 2 ) ( 2, 2 )
    in
    WebGL.triangleFan
        [ { position = Vec3.vec3 -Units.tileSize (-Units.tileSize + offsetY) 0, texturePosition = topLeft }
        , { position = Vec3.vec3 Units.tileSize (-Units.tileSize + offsetY) 0, texturePosition = topRight }
        , { position = Vec3.vec3 Units.tileSize (Units.tileSize + offsetY) 0, texturePosition = bottomRight }
        , { position = Vec3.vec3 -Units.tileSize (Units.tileSize + offsetY) 0, texturePosition = bottomLeft }
        ]


flagMeshes : Array (WebGL.Mesh Vertex)
flagMeshes =
    List.range 0 2
        |> List.map flagMesh
        |> Array.fromList


flagMesh : Int -> WebGL.Mesh Vertex
flagMesh frame =
    let
        width =
            11

        height =
            6

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels ( 72, 594 + frame * 6 ) ( width, 6 )
    in
    WebGL.triangleFan
        [ { position = Vec3.vec3 0 0 0, texturePosition = topLeft }
        , { position = Vec3.vec3 width 0 0, texturePosition = topRight }
        , { position = Vec3.vec3 width height 0, texturePosition = bottomRight }
        , { position = Vec3.vec3 0 height 0, texturePosition = bottomLeft }
        ]


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
