port module Frontend exposing (app, handleAddingTrain, init, update, updateFromBackend, view)

import Angle
import Array exposing (Array)
import AssocList
import Audio exposing (Audio, AudioCmd, AudioData)
import BoundingBox2d exposing (BoundingBox2d)
import Bounds exposing (Bounds)
import Browser exposing (UrlRequest(..))
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Change exposing (Change(..))
import Coord exposing (Coord)
import Cursor exposing (Cursor)
import Dict exposing (Dict)
import Direction2d
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import Env
import EverySet exposing (EverySet)
import Grid exposing (Grid, Vertex)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Touch
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
import Mail
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2
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
import WebGL.Settings.Blend as Blend
import WebGL.Texture exposing (Texture)


port martinsstewart_elm_device_pixel_ratio_from_js : (Float -> msg) -> Sub msg


port martinsstewart_elm_device_pixel_ratio_to_js : () -> Cmd msg


port supermario_copy_to_clipboard_to_js : String -> Cmd msg


port martinsstewart_elm_open_new_tab_to_js : String -> Cmd msg


port audioPortToJS : Json.Encode.Value -> Cmd msg


port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg


app =
    let
        _ =
            supermario_copy_to_clipboard_to_js

        _ =
            martinsstewart_elm_open_new_tab_to_js
    in
    Audio.lamderaFrontendWithAudio
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \_ msg model -> update msg model |> (\( a, b ) -> ( a, b, Audio.cmdNone ))
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

        volumeOffset : Float
        volumeOffset =
            0.5 / ((List.map .volume movingTrains |> List.sum) + 1)

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
        Just { time, overwroteTiles } ->
            if overwroteTiles then
                playSound CrackleSound time |> Audio.scaleVolume 0.2

            else
                playSound PopSound time |> Audio.scaleVolume 0.2

        _ ->
            Audio.silence
    , trainSounds
    , case model.lastTrainWhistle of
        Just time ->
            playSound TrainWhistleSound time |> Audio.scaleVolume 0.2

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
        cursor : Cursor
        cursor =
            Cursor.setCursor loading.viewPoint

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = LocalGrid.init loadingData
            , trains = loadingData.trains
            , meshes = Dict.empty
            , cursorMesh = Cursor.toMesh cursor
            , viewPoint = Coord.toPoint2d loading.viewPoint
            , viewPointLastInterval = Point2d.origin
            , cursor = cursor
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
            , lastTouchMove = Nothing
            , userHoverHighlighted = Nothing
            , highlightContextMenu = Nothing
            , adminEnabled = False
            , animationElapsedTime = Duration.seconds 0
            , ignoreNextUrlChanged = False
            , textAreaText = ""
            , lastTilePlaced = Nothing
            , sounds = loading.sounds
            , removedTileParticles = []
            , debrisMesh = WebGL.triangleFan []
            , lastTrainWhistle = Nothing
            , mail = loadingData.mail
            , showMailEditor = False
            , mailEditor = Mail.initEditor loadingData.mailEditor
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


isTouchDevice : FrontendLoaded -> Bool
isTouchDevice model =
    model.lastTouchMove /= Nothing


update : FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Cmd FrontendMsg_ )
update msg model =
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
            updateLoaded msg frontendLoaded
                |> Tuple.mapFirst (updateMeshes frontendLoaded >> Cursor.updateMesh frontendLoaded)
                |> viewBoundsUpdate
                |> Tuple.mapFirst Loaded


updateLoaded : FrontendMsg_ -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
updateLoaded msg model =
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
                            | cursor = Cursor.setCursor viewPoint
                            , viewPoint = viewPoint |> Coord.toPoint2d
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
                    let
                        model2 =
                            if
                                (key == Keyboard.Delete)
                                    || (key == Keyboard.Alt)
                                    || (key == Keyboard.Control)
                                    || (key == Keyboard.Meta)
                                    || (key == Keyboard.ArrowDown)
                                    || (key == Keyboard.ArrowUp)
                                    || (key == Keyboard.ArrowRight)
                                    || (key == Keyboard.ArrowLeft)
                                    || (key == Keyboard.Escape)
                            then
                                { model | textAreaText = "" }

                            else
                                model
                    in
                    keyMsgCanvasUpdate key model2

                Nothing ->
                    ( model, Cmd.none )

        WindowResized windowSize ->
            windowResizedUpdate windowSize model

        GotDevicePixelRatio devicePixelRatio ->
            devicePixelRatioUpdate devicePixelRatio model

        UserTyped text ->
            let
                newText =
                    String.right (String.length text - String.length model.textAreaText) text

                model2 =
                    { model | textAreaText = text }
            in
            if newText /= "" then
                if newText == "\n" || newText == "\u{000D}" then
                    ( resetTouchMove model2 |> (\m -> { m | cursor = Cursor.newLine m.cursor }), Cmd.none )

                else
                    ( resetTouchMove model2 |> changeText newText, Cmd.none )

            else
                ( model2, Cmd.none )

        TextAreaFocused ->
            ( { model | textAreaText = "" }, Cmd.none )

        MouseDown button mousePosition ->
            let
                model_ =
                    resetTouchMove model
            in
            ( if button == MainButton then
                { model_
                    | mouseLeft =
                        MouseButtonDown
                            { start = mousePosition, start_ = screenToWorld model_ mousePosition, current = mousePosition }
                    , mailEditor =
                        if model_.showMailEditor then
                            let
                                ( windowWidth, windowHeight ) =
                                    actualCanvasSize

                                { canvasSize, actualCanvasSize } =
                                    findPixelPerfectSize model
                            in
                            Mail.mouseDownMailEditor windowWidth windowHeight model_ mousePosition model.mailEditor

                        else
                            model.mailEditor
                }

              else if button == MiddleButton then
                { model_
                    | mouseMiddle =
                        MouseButtonDown
                            { start = mousePosition, start_ = screenToWorld model_ mousePosition, current = mousePosition }
                }

              else if button == SecondButton then
                let
                    localModel =
                        LocalGrid.localModel model.localModel

                    position : Coord WorldUnit
                    position =
                        screenToWorld model mousePosition |> Coord.floorPoint

                    maybeUserId =
                        Grid.getTile position localModel.grid |> Maybe.map .userId
                in
                case maybeUserId of
                    Just userId ->
                        highlightUser userId position model_

                    Nothing ->
                        { model_ | highlightContextMenu = Nothing }

              else
                model_
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
                            if model.showMailEditor then
                                model.viewPoint

                            else
                                offsetViewPoint model mouseState.start mousePosition
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        MouseMove mousePosition ->
            if isTouchDevice model then
                ( model, Cmd.none )

            else
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
                    , cursor =
                        case ( model.mouseLeft, model.tool ) of
                            ( MouseButtonDown mouseState, SelectTool ) ->
                                Cursor.selection
                                    (mouseState.start_ |> Coord.floorPoint)
                                    (screenToWorld model mousePosition |> Coord.floorPoint)

                            _ ->
                                model.cursor
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
            ( resetTouchMove model |> (\m -> { m | zoomFactor = zoomFactor }), Cmd.none )

        SelectToolPressed toolType ->
            ( resetTouchMove model |> (\m -> { m | tool = toolType }), Cmd.none )

        UndoPressed ->
            ( resetTouchMove model |> updateLocalModel Change.LocalUndo, Cmd.none )

        RedoPressed ->
            ( resetTouchMove model |> updateLocalModel Change.LocalRedo, Cmd.none )

        CopyPressed ->
            -- TODO
            ( model, Cmd.none )

        CutPressed ->
            -- TODO
            ( model, Cmd.none )

        TouchMove touchPosition ->
            let
                mouseDown m =
                    { m
                        | mouseLeft =
                            MouseButtonDown
                                { start = touchPosition
                                , start_ = screenToWorld model touchPosition
                                , current = touchPosition
                                }
                        , lastTouchMove = Just model.time
                    }
            in
            case model.mouseLeft of
                MouseButtonDown mouseState ->
                    let
                        duration =
                            case model.lastTouchMove of
                                Just lastTouchMove ->
                                    Duration.from lastTouchMove model.time

                                Nothing ->
                                    Quantity.zero

                        rate : Quantity Float (Rate Pixels Duration.Seconds)
                        rate =
                            Quantity.per Duration.second (Pixels.pixels 30)

                        snapDistance =
                            Pixels.pixels 50 |> Quantity.minus (Quantity.for duration rate) |> Quantity.max (Pixels.pixels 10)
                    in
                    if Point2d.distanceFrom mouseState.current touchPosition |> Quantity.greaterThan snapDistance then
                        mainMouseButtonUp mouseState.current mouseState model
                            |> Tuple.mapFirst mouseDown

                    else
                        ( { model
                            | mouseLeft = MouseButtonDown { mouseState | current = touchPosition }
                            , cursor =
                                case model.tool of
                                    SelectTool ->
                                        Cursor.selection
                                            (Coord.floorPoint mouseState.start_)
                                            (screenToWorld model touchPosition |> Coord.floorPoint)

                                    _ ->
                                        model.cursor
                            , lastTouchMove = Just model.time
                          }
                        , Cmd.none
                        )

                MouseButtonUp _ ->
                    ( mouseDown model, Cmd.none )

        VeryShortIntervalElapsed time ->
            ( { model | time = time }, Cmd.none )

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


replaceUrl : String -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
replaceUrl url model =
    ( { model | ignoreNextUrlChanged = True }, Browser.Navigation.replaceUrl model.key url )


keyMsgCanvasUpdate : Keyboard.Key -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
keyMsgCanvasUpdate key model =
    case key of
        Keyboard.Character "c" ->
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                -- TODO
                ( model, Cmd.none )

            else
                ( model, Cmd.none )

        Keyboard.Character "x" ->
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                -- TODO
                ( model, Cmd.none )

            else
                ( model, Cmd.none )

        Keyboard.Character "z" ->
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                ( updateLocalModel Change.LocalUndo model, Cmd.none )

            else
                ( model, Cmd.none )

        Keyboard.Character "Z" ->
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                ( updateLocalModel Change.LocalRedo model, Cmd.none )

            else
                ( model, Cmd.none )

        Keyboard.Character "y" ->
            if keyDown Keyboard.Control model || keyDown Keyboard.Meta model then
                ( updateLocalModel Change.LocalRedo model, Cmd.none )

            else
                ( model, Cmd.none )

        Keyboard.Delete ->
            let
                bounds =
                    Cursor.bounds model.cursor
            in
            ( clearTextSelection bounds model
            , Cmd.none
            )

        Keyboard.ArrowLeft ->
            ( { model
                | cursor =
                    Cursor.moveCursor
                        (keyDown Keyboard.Shift model)
                        ( Units.tileUnit -1, Units.tileUnit 0 )
                        model.cursor
              }
            , Cmd.none
            )

        Keyboard.ArrowRight ->
            ( { model
                | cursor =
                    Cursor.moveCursor
                        (keyDown Keyboard.Shift model)
                        ( Units.tileUnit 1, Units.tileUnit 0 )
                        model.cursor
              }
            , Cmd.none
            )

        Keyboard.ArrowUp ->
            ( { model
                | cursor =
                    Cursor.moveCursor
                        (keyDown Keyboard.Shift model)
                        ( Units.tileUnit 0, Units.tileUnit -1 )
                        model.cursor
              }
            , Cmd.none
            )

        Keyboard.ArrowDown ->
            ( { model
                | cursor =
                    Cursor.moveCursor
                        (keyDown Keyboard.Shift model)
                        ( Units.tileUnit 0, Units.tileUnit 1 )
                        model.cursor
              }
            , Cmd.none
            )

        Keyboard.Backspace ->
            let
                newCursor =
                    Cursor.moveCursor
                        False
                        ( Units.tileUnit -1, Units.tileUnit 0 )
                        model.cursor
            in
            ( { model | cursor = newCursor } |> changeText " " |> (\m -> { m | cursor = newCursor })
            , Cmd.none
            )

        Keyboard.Escape ->
            ( { model | showMailEditor = False }, Cmd.none )

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
                    case ( model.showMailEditor, model.mouseMiddle, model.tool ) of
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
    in
    ( if isSmallDistance then
        let
            localModel : LocalGrid_
            localModel =
                LocalGrid.localModel model2.localModel

            maybeTile : Maybe { userId : Id UserId, value : Tile }
            maybeTile =
                Grid.getTile (screenToWorld model2 mousePosition |> Coord.floorPoint) localModel.grid
        in
        case maybeTile of
            Just tile ->
                if tile.userId == localModel.user && tile.value == PostOffice then
                    { model2 | showMailEditor = True }

                else
                    { model2
                        | cursor = screenToWorld model2 mousePosition |> Coord.floorPoint |> Cursor.setCursor
                    }

            Nothing ->
                { model2 | cursor = screenToWorld model2 mousePosition |> Coord.floorPoint |> Cursor.setCursor }

      else
        model2
    , Cmd.none
    )


highlightUser : Id UserId -> Coord WorldUnit -> FrontendLoaded -> FrontendLoaded
highlightUser highlightUserId highlightPoint model =
    { model
        | highlightContextMenu =
            case model.highlightContextMenu of
                Just { userId } ->
                    if highlightUserId == userId then
                        Nothing

                    else
                        Just { userId = highlightUserId, hidePoint = highlightPoint }

                Nothing ->
                    Just { userId = highlightUserId, hidePoint = highlightPoint }

        -- We add some delay because there's usually lag before the animation starts
        , animationElapsedTime = Duration.milliseconds -300
    }


resetTouchMove : FrontendLoaded -> FrontendLoaded
resetTouchMove model =
    case model.mouseLeft of
        MouseButtonUp _ ->
            model

        MouseButtonDown mouseState ->
            if isTouchDevice model then
                mainMouseButtonUp mouseState.current mouseState model |> Tuple.first

            else
                model


updateLocalModel : Change.LocalChange -> FrontendLoaded -> FrontendLoaded
updateLocalModel msg model =
    { model
        | pendingChanges = model.pendingChanges ++ [ msg ]
        , localModel = LocalGrid.update model.time (LocalChange msg) model.localModel
    }


clearTextSelection : Bounds WorldUnit -> FrontendLoaded -> FrontendLoaded
clearTextSelection bounds model =
    let
        ( w, h ) =
            Bounds.maximum bounds
                |> Coord.minusTuple (Bounds.minimum bounds)
                |> Coord.addTuple ( Units.tileUnit 1, Units.tileUnit 1 )
                |> Coord.toTuple
    in
    { model | cursor = Cursor.setCursor (Bounds.minimum bounds) }
        |> changeText (String.repeat w " " |> List.repeat h |> String.join "\n")
        |> (\m -> { m | cursor = model.cursor })


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
    ( { model
        | devicePixelRatio = devicePixelRatio
      }
    , Cmd.none
    )


changeText : String -> FrontendLoaded -> FrontendLoaded
changeText text model =
    case String.toList text of
        head :: _ ->
            case Tile.fromChar head of
                Just tile ->
                    let
                        model2 =
                            if Duration.from model.undoAddLast model.time |> Quantity.greaterThan (Duration.seconds 0.5) then
                                updateLocalModel Change.LocalAddUndo { model | undoAddLast = model.time }

                            else
                                model

                        ( cellPos, localPos ) =
                            Grid.worldToCellAndLocalCoord (Cursor.position model.cursor)

                        neighborCells : List ( Coord CellUnit, Coord Units.CellLocalUnit )
                        neighborCells =
                            ( cellPos, localPos ) :: Grid.closeNeighborCells cellPos localPos

                        oldGrid : Grid
                        oldGrid =
                            LocalGrid.localModel model2.localModel |> .grid

                        model3 =
                            updateLocalModel
                                (Change.LocalGridChange
                                    { position = Cursor.position model.cursor
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
                            Just { time = model.time, overwroteTiles = List.isEmpty removedTiles |> not }
                        , removedTileParticles = removedTiles ++ model3.removedTileParticles
                        , debrisMesh = createDebrisMesh model.startTime (removedTiles ++ model3.removedTileParticles)
                    }

                Nothing ->
                    model

        [] ->
            model


handleAddingTrain : Tile -> Coord WorldUnit -> Maybe Train
handleAddingTrain tile position =
    if tile == TrainHouseLeft || tile == TrainHouseRight then
        let
            ( path, speed ) =
                if tile == TrainHouseLeft then
                    ( Tile.trainHouseLeftRailPath
                    , Quantity -0.1
                    )

                else
                    ( Tile.trainHouseRightRailPath
                    , Quantity 0.1
                    )
        in
        { position = position
        , path = path
        , t = 0.5
        , speed = speed
        , stoppedAtPostOffice = Nothing
        }
            |> Just

    else
        Nothing


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
                        ( textureW, textureH ) =
                            Tile.getData tile |> .size
                    in
                    textureW * textureH
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

                ( Quantity x, Quantity y ) =
                    position

                ( textureX, textureY ) =
                    data.texturePosition

                ( textureW, textureH ) =
                    data.size
            in
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
        )
        list
        |> List.concat
        |> (\vertices -> WebGL.indexedTriangles vertices indices)


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
    case ( model.showMailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( False, _, MouseButtonDown { start, current } ) ->
            offsetViewPoint model start current

        ( False, MouseButtonDown { start, current }, _ ) ->
            case model.tool of
                DragTool ->
                    offsetViewPoint model start current

                SelectTool ->
                    model.viewPoint

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


textarea : FrontendLoaded -> Element.Attribute FrontendMsg_
textarea model =
    Html.textarea
        [ Html.Attributes.value model.textAreaText
        , Html.Events.onInput UserTyped
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "100%"
        , Html.Attributes.style "resize" "none"
        , Html.Attributes.style "opacity" "0"
        , Html.Attributes.id "textareaId"
        , Html.Events.onFocus TextAreaFocused
        , Html.Attributes.attribute "data-gramm" "false"
        , Html.Events.Extra.Touch.onWithOptions
            "touchmove"
            { stopPropagation = False, preventDefault = True }
            (\event ->
                case event.touches of
                    head :: _ ->
                        let
                            ( x, y ) =
                                head.pagePos
                        in
                        TouchMove (Point2d.pixels x y)

                    [] ->
                        NoOpFrontendMsg
            )
        , Html.Events.Extra.Mouse.onDown
            (\{ clientPos, button } ->
                MouseDown button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
            )
        ]
        []
        |> Element.html
        |> Element.inFront


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
                        :: textarea loadedModel
                        :: Element.inFront (toolbarView loadedModel)
                        :: Element.inFront (userListView loadedModel)
                        :: Element.htmlAttribute (Html.Events.Extra.Mouse.onContextMenu (\_ -> NoOpFrontendMsg))
                        :: mouseAttributes
                        ++ (case loadedModel.highlightContextMenu of
                                Just hideUser ->
                                    [ contextMenuView hideUser loadedModel |> Element.inFront ]

                                Nothing ->
                                    []
                           )
                    )
                    (Element.html (canvasView loadedModel))
        , Html.node "style"
            []
            [ Html.text "@font-face { font-family: ascii; src: url('ascii.ttf'); }" ]
        ]
    }


contextMenuView : { userId : Id UserId, hidePoint : Coord WorldUnit } -> FrontendLoaded -> Element FrontendMsg_
contextMenuView { userId, hidePoint } loadedModel =
    let
        { x, y } =
            Coord.addTuple ( Units.tileUnit 1, Units.tileUnit 1 ) hidePoint
                |> Coord.toPoint2d
                |> worldToScreen loadedModel
                |> Point2d.unwrap

        attributes =
            [ Element.padding 8
            , Element.moveRight x
            , Element.moveDown y
            , Element.Border.roundEach { topLeft = 0, topRight = 4, bottomLeft = 4, bottomRight = 4 }
            , Element.Border.width 1
            , Element.Border.color UiColors.border
            ]
    in
    if userId == currentUserId loadedModel then
        Element.el (Element.Background.color UiColors.background :: attributes) (Element.text "You")

    else
        Element.Input.button
            (Element.Background.color UiColors.button
                :: Element.mouseOver [ Element.Background.color UiColors.buttonActive ]
                :: attributes
            )
            { onPress = Just (HideUserPressed { userId = userId, hidePoint = hidePoint })
            , label = Element.text "Hide user"
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
    ]
        |> List.map Element.htmlAttribute


isAdmin : FrontendLoaded -> Bool
isAdmin model =
    currentUserId model |> Just |> (==) Env.adminUserId |> (&&) model.adminEnabled


currentUserId : FrontendLoaded -> Id UserId
currentUserId =
    .localModel >> LocalGrid.localModel >> .user


userListView : FrontendLoaded -> Element FrontendMsg_
userListView model =
    let
        localModel =
            LocalGrid.localModel model.localModel

        colorSquare isFirst isLast userId =
            Element.el
                (Element.padding 4
                    :: Element.Border.widthEach
                        { left = 0
                        , right = 1
                        , top =
                            if isFirst then
                                0

                            else
                                1
                        , bottom =
                            if isLast then
                                0

                            else
                                1
                        }
                    :: Element.Events.onMouseEnter (UserTagMouseEntered userId)
                    :: Element.Events.onMouseLeave (UserTagMouseExited userId)
                    :: buttonAttributes
                )
                (colorSquareInner userId)

        colorSquareInner : Id UserId -> Element FrontendMsg_
        colorSquareInner userId =
            Element.el
                [ Element.width (Element.px 20)
                , Element.height (Element.px 20)
                , Element.Border.rounded 2
                , Element.Border.width 1
                , Element.Border.color UiColors.colorSquareBorder
                ]
                (if isAdmin model then
                    Element.paragraph
                        [ Element.Font.size 9, Element.spacing 0, Element.moveDown 1, Element.moveRight 1 ]
                        [ Id.toInt userId |> String.fromInt |> Element.text ]

                 else
                    Element.none
                )

        youText =
            if isAdmin model then
                Element.el
                    [ Element.Font.bold, Element.centerX, Element.Font.color UiColors.adminText ]
                    (Element.text "⇽ Admin")

            else
                Element.el [ Element.Font.bold, Element.centerX ] (Element.text "⇽ You")

        userTag : Element FrontendMsg_
        userTag =
            baseTag
                True
                (List.isEmpty hiddenUsers && not showHiddenUsersForAll)
                (if Just (currentUserId model) == Env.adminUserId then
                    Element.Input.button
                        [ Element.width Element.fill, Element.height Element.fill ]
                        { onPress = Just ToggleAdminEnabledPressed
                        , label = youText
                        }

                 else
                    youText
                )
                localModel.user

        baseTag : Bool -> Bool -> Element FrontendMsg_ -> Id UserId -> Element FrontendMsg_
        baseTag isFirst isLast content userId =
            Element.row
                [ Element.width Element.fill
                , "User Id: "
                    ++ String.fromInt (Id.toInt userId)
                    |> Element.text
                    |> Element.el [ Element.htmlAttribute <| Html.Attributes.style "visibility" "collapse" ]
                    |> Element.behindContent
                ]
                [ colorSquare isFirst isLast userId
                , content
                ]

        rowBorderWidth : Bool -> Bool -> List (Element.Attribute msg)
        rowBorderWidth isFirst isLast =
            Element.Border.widthEach
                { left = 0
                , right = 0
                , top =
                    if isFirst then
                        0

                    else
                        1
                , bottom =
                    if isLast then
                        0

                    else
                        1
                }
                :: (if isLast then
                        [ Element.Border.roundEach { bottomLeft = 1, topLeft = 0, topRight = 0, bottomRight = 0 } ]

                    else
                        []
                   )

        hiddenUserTag : Bool -> Bool -> Id UserId -> Element FrontendMsg_
        hiddenUserTag isFirst isLast userId =
            Element.Input.button
                (Element.Events.onMouseEnter (UserTagMouseEntered userId)
                    :: Element.Events.onMouseLeave (UserTagMouseExited userId)
                    :: Element.width Element.fill
                    :: Element.padding 4
                    :: rowBorderWidth isFirst isLast
                    ++ buttonAttributes
                )
                { onPress = Just (UnhideUserPressed userId)
                , label =
                    Element.row [ Element.width Element.fill ]
                        [ colorSquareInner userId
                        , Element.el [ Element.centerX ] (Element.text "Unhide")
                        ]
                }
                |> (\a ->
                        if isAdmin model then
                            Element.row [ Element.width Element.fill ]
                                [ a
                                , Element.Input.button
                                    (Element.Border.color UiColors.border
                                        :: Element.Background.color UiColors.button
                                        :: Element.mouseOver [ Element.Background.color UiColors.buttonActive ]
                                        :: Element.height Element.fill
                                        :: Element.width Element.fill
                                        :: rowBorderWidth isFirst isLast
                                    )
                                    { onPress = Just (HideForAllTogglePressed userId)
                                    , label = Element.el [ Element.centerX ] (Element.text "Hide for all")
                                    }
                                ]

                        else
                            a
                   )

        hiddenUserForAllTag : Bool -> Bool -> Id UserId -> Element FrontendMsg_
        hiddenUserForAllTag isFirst isLast userId =
            Element.Input.button
                (Element.Events.onMouseEnter (UserTagMouseEntered userId)
                    :: Element.Events.onMouseLeave (UserTagMouseExited userId)
                    :: Element.width Element.fill
                    :: Element.padding 4
                    :: rowBorderWidth isFirst isLast
                    ++ buttonAttributes
                )
                { onPress = Just (HideForAllTogglePressed userId)
                , label =
                    Element.row [ Element.width Element.fill ]
                        [ colorSquareInner userId
                        , Element.el [ Element.centerX ] (Element.text "Unhide for all")
                        ]
                }

        buttonAttributes =
            [ Element.Border.color UiColors.border
            , Element.Background.color UiColors.button
            ]

        hiddenUserList : List (Id UserId)
        hiddenUserList =
            EverySet.diff localModel.hiddenUsers localModel.adminHiddenUsers
                |> EverySet.toList

        hiddenUsers : List (Element FrontendMsg_)
        hiddenUsers =
            hiddenUserList
                |> List.indexedMap
                    (\index otherUser ->
                        hiddenUserTag
                            False
                            (List.length hiddenUserList - 1 == index && not showHiddenUsersForAll)
                            otherUser
                    )

        hiddenusersForAllList : List (Id UserId)
        hiddenusersForAllList =
            EverySet.toList localModel.adminHiddenUsers

        hiddenUsersForAll : List (Element FrontendMsg_)
        hiddenUsersForAll =
            hiddenusersForAllList
                |> List.indexedMap
                    (\index otherUser ->
                        hiddenUserForAllTag
                            False
                            (List.length hiddenusersForAllList - 1 == index)
                            otherUser
                    )

        showHiddenUsersForAll =
            not (List.isEmpty hiddenUsersForAll) && isAdmin model
    in
    Element.column
        [ Element.Background.color UiColors.background
        , Element.alignRight
        , Element.spacing 8
        , Element.Border.widthEach { bottom = 1, left = 1, right = 1, top = 0 }
        , Element.Border.roundEach { bottomLeft = 3, topLeft = 0, topRight = 0, bottomRight = 0 }
        , Element.Border.color UiColors.border
        , Element.Font.color UiColors.text
        , if isAdmin model then
            Element.width (Element.px 230)

          else
            Element.width (Element.px 130)
        ]
        [ userTag
        , if List.isEmpty hiddenUsers && not showHiddenUsersForAll then
            Element.none

          else
            Element.column
                [ Element.width Element.fill, Element.spacing 4 ]
                [ Element.el [ Element.paddingXY 8 0 ] (Element.text "Hidden")
                , Element.column
                    [ Element.width Element.fill, Element.spacing 2 ]
                    hiddenUsers
                ]
        , if showHiddenUsersForAll then
            Element.column
                [ Element.width Element.fill, Element.spacing 4 ]
                [ Element.el [ Element.paddingXY 8 0 ] (Element.text "Hidden for all")
                , Element.column
                    [ Element.width Element.fill, Element.spacing 2 ]
                    hiddenUsersForAll
                ]

          else
            Element.none
        ]


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
    , ( SelectTool
      , (==) SelectTool
      , Element.el
            [ Element.Border.width 2
            , Element.Border.dashed
            , Element.width (Element.px 22)
            , Element.height (Element.px 22)
            ]
            Element.none
      )
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
        [ WebGL.alpha False, WebGL.antialias, WebGL.clearColor 0.8 1 0.7 1 ]
        [ Html.Attributes.width windowWidth
        , Html.Attributes.height windowHeight
        , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
        , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
        ]
        (Cursor.draw viewMatrix (Element.rgba 1 0 1 0.5) model
            :: (case model.texture of
                    Just texture ->
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
                            ++ [ WebGL.entityWith
                                    [ Blend.add Blend.one Blend.oneMinusSrcAlpha ]
                                    Shaders.debrisVertexShader
                                    Shaders.fragmentShader
                                    model.debrisMesh
                                    { view = viewMatrix
                                    , texture = texture
                                    , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                                    , time = Duration.from model.startTime model.time |> Duration.inSeconds
                                    }
                               ]
                            ++ (if model.showMailEditor then
                                    Mail.drawMail
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

                                else
                                    []
                               )

                    Nothing ->
                        []
               )
        )


drawText : Dict ( Int, Int ) (WebGL.Mesh Grid.Vertex) -> Mat4 -> Texture -> List WebGL.Entity
drawText meshes viewMatrix texture =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                WebGL.entityWith
                    [ WebGL.Settings.cullFace WebGL.Settings.back
                    , Blend.add Blend.one Blend.oneMinusSrcAlpha
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
                        [ Blend.add Blend.one Blend.oneMinusSrcAlpha
                        ]
                        Shaders.vertexShader
                        Shaders.fragmentShader
                        trainMesh_
                        { view = Mat4.makeTranslate3 (x * Units.tileSize) (y * Units.tileSize) 0 |> Mat4.mul viewMatrix
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
        [ { position = Vec2.vec2 -Units.tileSize (-Units.tileSize + offsetY), texturePosition = topLeft }
        , { position = Vec2.vec2 Units.tileSize (-Units.tileSize + offsetY), texturePosition = topRight }
        , { position = Vec2.vec2 Units.tileSize (Units.tileSize + offsetY), texturePosition = bottomRight }
        , { position = Vec2.vec2 -Units.tileSize (Units.tileSize + offsetY), texturePosition = bottomLeft }
        ]


subscriptions : AudioData -> FrontendModel_ -> Sub FrontendMsg_
subscriptions _ model =
    Sub.batch
        [ martinsstewart_elm_device_pixel_ratio_from_js GotDevicePixelRatio
        , Browser.Events.onResize (\width height -> WindowResized ( Pixels.pixels width, Pixels.pixels height ))
        , case model of
            Loading _ ->
                Sub.none

            Loaded loadedModel ->
                Sub.batch
                    [ Sub.map KeyMsg Keyboard.subscriptions
                    , Keyboard.downs KeyDown
                    , Time.every 1000 ShortIntervalElapsed
                    , case ( loadedModel.mouseLeft, isTouchDevice loadedModel ) of
                        ( MouseButtonDown _, True ) ->
                            Time.every 100 VeryShortIntervalElapsed

                        _ ->
                            Sub.none
                    , Browser.Events.onAnimationFrame AnimationFrame
                    ]
        ]
