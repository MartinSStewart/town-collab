port module Frontend exposing (app, init, update, updateFromBackend, view)

import Audio exposing (AudioCmd, AudioData)
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
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import Env
import EverySet exposing (EverySet)
import Grid exposing (Grid)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Html.Events.Extra.Mouse exposing (Button(..))
import Html.Events.Extra.Touch
import Icons
import Json.Decode
import Json.Encode
import Keyboard
import Lamdera
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import LocalGrid exposing (LocalGrid, LocalGrid_)
import LocalModel
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2
import NotifyMe
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Shaders
import Task
import Tile exposing (RailPath(..), Tile(..))
import Time
import Types exposing (..)
import UiColors
import Units exposing (CellUnit, ScreenCoordinate, WorldCoordinate, WorldPixel, WorldUnit)
import Url exposing (Url)
import Url.Parser exposing ((<?>))
import UrlHelper
import User exposing (UserId(..))
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


audio audioData model =
    Audio.silence


loadedInit : FrontendLoading -> LoadingData_ -> ( FrontendModel_, Cmd FrontendMsg_ )
loadedInit loading loadingData =
    let
        cursor : Cursor
        cursor =
            Cursor.setCursor loading.viewPoint

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = LocalGrid.init loadingData
            , trains = []
            , meshes = Dict.empty
            , cursorMesh = Cursor.toMesh cursor
            , viewPoint = Tile.tileToWorld loading.viewPoint |> Coord.toPoint2d
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
            , time = loading.time
            , lastTouchMove = Nothing
            , userHoverHighlighted = Nothing
            , highlightContextMenu = Nothing
            , adminEnabled = False
            , animationElapsedTime = Duration.seconds 0
            , ignoreNextUrlChanged = False
            , showNotifyMe = loading.showNotifyMe
            , notifyMeModel = loading.notifyMeModel
            , textAreaText = ""
            , popSound = loading.popSound
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
        { viewPoint, showNotifyMe, notifyMe, emailEvent, cmd } =
            let
                defaultRoute =
                    UrlHelper.internalRoute False UrlHelper.startPointAt
            in
            case Url.Parser.parse UrlHelper.urlParser url of
                Just (UrlHelper.InternalRoute a) ->
                    { viewPoint = a.viewPoint
                    , showNotifyMe = a.showNotifyMe
                    , notifyMe = NotifyMe.init
                    , emailEvent = Nothing
                    , cmd = Cmd.none
                    }

                Just (UrlHelper.EmailConfirmationRoute a) ->
                    { viewPoint = UrlHelper.startPointAt
                    , showNotifyMe = True
                    , notifyMe = NotifyMe.init |> NotifyMe.emailConfirmed
                    , emailEvent = Just (ConfirmationEmailConfirmed_ a)
                    , cmd = Browser.Navigation.replaceUrl key (UrlHelper.encodeUrl defaultRoute)
                    }

                Just (UrlHelper.EmailUnsubscribeRoute a) ->
                    { viewPoint = UrlHelper.startPointAt
                    , showNotifyMe = True
                    , notifyMe = NotifyMe.init |> NotifyMe.unsubscribing
                    , emailEvent = Just (UnsubscribeEmail a)
                    , cmd = Browser.Navigation.replaceUrl key (UrlHelper.encodeUrl defaultRoute)
                    }

                Nothing ->
                    { viewPoint = UrlHelper.startPointAt
                    , showNotifyMe = False
                    , notifyMe = NotifyMe.init
                    , emailEvent = Nothing
                    , cmd = Browser.Navigation.replaceUrl key (UrlHelper.encodeUrl defaultRoute)
                    }

        -- We only load in a portion of the grid since we don't know the window size yet. The rest will get loaded in later anyway.
        bounds =
            Bounds.bounds
                (Grid.tileToCellAndLocalCoord viewPoint
                    |> Tuple.first
                    |> Coord.addTuple ( Units.cellUnit -2, Units.cellUnit -2 )
                )
                (Grid.tileToCellAndLocalCoord viewPoint
                    |> Tuple.first
                    |> Coord.addTuple ( Units.cellUnit 2, Units.cellUnit 2 )
                )
    in
    ( Loading
        { key = key
        , windowSize = ( Pixels.pixels 1920, Pixels.pixels 1080 )
        , devicePixelRatio = Quantity 1
        , zoomFactor = 1
        , time = Time.millisToPosix 0
        , viewPoint = viewPoint
        , mousePosition = Point2d.origin
        , showNotifyMe = showNotifyMe
        , notifyMeModel = notifyMe
        , popSound = Nothing
        }
    , Cmd.batch
        [ Lamdera.sendToBackend (ConnectToBackend bounds emailEvent)
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
    , Audio.loadAudio PopSoundLoaded "/pop.mp3"
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
                    ( Loading { loadingModel | time = time }, Cmd.none )

                GotDevicePixelRatio devicePixelRatio ->
                    devicePixelRatioUpdate devicePixelRatio loadingModel |> Tuple.mapFirst Loading

                PopSoundLoaded result ->
                    ( Loading { loadingModel | popSound = Just result }, Cmd.none )

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
                    Just (UrlHelper.InternalRoute { viewPoint, showNotifyMe }) ->
                        { model
                            | cursor = Cursor.setCursor viewPoint
                            , viewPoint = Tile.tileToWorld viewPoint |> Coord.toPoint2d
                            , showNotifyMe = showNotifyMe
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
            if newText /= "" && cursorEnabled model2 then
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
                        screenToWorld model mousePosition |> Tile.worldToTile

                    maybeUserId =
                        selectionPoint
                            position
                            localModel.hiddenUsers
                            localModel.adminHiddenUsers
                            localModel.grid
                            |> Maybe.map .userId
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
                        , viewPoint = offsetViewPoint model mouseState.start mousePosition
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
                                    (mouseState.start_ |> Tile.worldToTile)
                                    (screenToWorld model mousePosition |> Tile.worldToTile)

                            _ ->
                                model.cursor
                    , tool =
                        case model.tool of
                            HighlightTool _ ->
                                let
                                    localModel =
                                        LocalGrid.localModel model.localModel

                                    position : Coord WorldUnit
                                    position =
                                        screenToWorld model mousePosition |> Tile.worldToTile

                                    hideUserId =
                                        selectionPoint
                                            position
                                            localModel.hiddenUsers
                                            localModel.adminHiddenUsers
                                            localModel.grid
                                            |> Maybe.map .userId
                                in
                                hideUserId |> Maybe.map (\a -> ( a, position )) |> HighlightTool

                            _ ->
                                model.tool
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
                    if Tile.worldToTile actualViewPoint_ /= Tile.worldToTile model.viewPointLastInterval then
                        Tile.worldToTile actualViewPoint_
                            |> UrlHelper.internalRoute model.showNotifyMe
                            |> UrlHelper.encodeUrl
                            |> (\a -> replaceUrl a model2)

                    else
                        ( model2, Cmd.none )
            in
            case List.Nonempty.fromList model3.pendingChanges of
                Just nonempty ->
                    ( { model3 | pendingChanges = [] }
                    , Cmd.batch
                        [ GridChange nonempty |> Lamdera.sendToBackend
                        , urlChange
                        ]
                    )

                Nothing ->
                    ( model3, urlChange )

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
                                            (mouseState.start_ |> Tile.worldToTile)
                                            (screenToWorld model touchPosition |> Tile.worldToTile)

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

                moveTrain : Train -> Train
                moveTrain train =
                    let
                        ( cellPos, localPos ) =
                            Grid.tileToCellAndLocalCoord (Coord.floorPoint train.position)
                    in
                    case Grid.getCell cellPos localGrid.grid of
                        Just cell ->
                            GridCell.flatten EverySet.empty EverySet.empty cell
                                |> List.filterMap
                                    (\{ position, value } ->
                                        case Tile.getData value |> .railPath of
                                            NoRailPath ->
                                                Nothing

                                            SingleRailPath path ->
                                                let
                                                    { t, distance } =
                                                        Tile.nearestRailT localPos path
                                                in
                                                { t = t
                                                , distance = distance
                                                , position = position
                                                , tile = value
                                                }
                                                    |> Just
                                    )
                                |> Quantity.minimumBy .distance

                        Nothing ->
                            train
            in
            ( { model
                | time = time
                , animationElapsedTime = Duration.from model.time time |> Quantity.plus model.animationElapsedTime
                , trains = List.map moveTrain model.trains
              }
            , Cmd.none
            )

        PressedCancelNotifyMe ->
            closeNotifyMe model

        PressedSubmitNotifyMe validated ->
            ( { model | notifyMeModel = NotifyMe.inProgress model.notifyMeModel }, Lamdera.sendToBackend (NotifyMeSubmitted validated) )

        NotifyMeModelChanged notifyMeModel ->
            ( { model | notifyMeModel = notifyMeModel }, Cmd.none )

        PopSoundLoaded result ->
            ( { model | popSound = Just result }, Cmd.none )


closeNotifyMe : FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
closeNotifyMe model =
    UrlHelper.internalRoute False (Tile.worldToTile (actualViewPoint model))
        |> UrlHelper.encodeUrl
        |> (\a -> pushUrl a { model | showNotifyMe = False, notifyMeModel = NotifyMe.init })


replaceUrl : String -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
replaceUrl url model =
    ( { model | ignoreNextUrlChanged = True }, Browser.Navigation.replaceUrl model.key url )


pushUrl : String -> FrontendLoaded -> ( FrontendLoaded, Cmd FrontendMsg_ )
pushUrl url model =
    ( { model | ignoreNextUrlChanged = True }, Browser.Navigation.pushUrl model.key url )


cursorEnabled : FrontendLoaded -> Bool
cursorEnabled model =
    case ( model.tool, model.showNotifyMe ) of
        ( HighlightTool _, _ ) ->
            False

        ( _, True ) ->
            False

        _ ->
            True


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
                if cursorEnabled model then
                    -- TODO
                    ( model, Cmd.none )

                else
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
            if cursorEnabled model then
                let
                    bounds =
                        Cursor.bounds model.cursor
                in
                ( clearTextSelection bounds model
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Keyboard.ArrowLeft ->
            if cursorEnabled model then
                ( { model
                    | cursor =
                        Cursor.moveCursor
                            (keyDown Keyboard.Shift model)
                            ( Units.tileUnit -1, Units.tileUnit 0 )
                            model.cursor
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Keyboard.ArrowRight ->
            if cursorEnabled model then
                ( { model
                    | cursor =
                        Cursor.moveCursor
                            (keyDown Keyboard.Shift model)
                            ( Units.tileUnit 1, Units.tileUnit 0 )
                            model.cursor
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Keyboard.ArrowUp ->
            if cursorEnabled model then
                ( { model
                    | cursor =
                        Cursor.moveCursor
                            (keyDown Keyboard.Shift model)
                            ( Units.tileUnit 0, Units.tileUnit -1 )
                            model.cursor
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Keyboard.ArrowDown ->
            if cursorEnabled model then
                ( { model
                    | cursor =
                        Cursor.moveCursor
                            (keyDown Keyboard.Shift model)
                            ( Units.tileUnit 0, Units.tileUnit 1 )
                            model.cursor
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Keyboard.Backspace ->
            if cursorEnabled model then
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

            else
                ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


mainMouseButtonUp :
    Point2d Pixels ScreenCoordinate
    -> { a | start : Point2d Pixels ScreenCoordinate }
    -> FrontendLoaded
    -> ( FrontendLoaded, Cmd FrontendMsg_ )
mainMouseButtonUp mousePosition mouseState model =
    let
        isSmallDistance =
            Vector2d.from mouseState.start mousePosition
                |> Vector2d.length
                |> Quantity.lessThan (Pixels.pixels 5)

        model_ =
            { model
                | mouseLeft = MouseButtonUp { current = mousePosition }
                , viewPoint =
                    case ( model.mouseMiddle, model.tool ) of
                        ( MouseButtonUp _, DragTool ) ->
                            offsetViewPoint model mouseState.start mousePosition

                        ( MouseButtonUp _, HighlightTool _ ) ->
                            offsetViewPoint model mouseState.start mousePosition

                        _ ->
                            model.viewPoint
                , cursor =
                    if not (cursorEnabled model) then
                        model.cursor

                    else if isSmallDistance then
                        screenToWorld model mousePosition |> Tile.worldToTile |> Cursor.setCursor

                    else
                        model.cursor
                , highlightContextMenu =
                    if isSmallDistance then
                        Nothing

                    else
                        model.highlightContextMenu
                , lastMouseLeftUp = Just ( model.time, mousePosition )
            }
    in
    case model_.tool of
        HighlightTool (Just ( userId, hidePoint )) ->
            if isSmallDistance then
                ( highlightUser userId hidePoint model_, Cmd.none )

            else
                ( model_, Cmd.none )

        _ ->
            ( model_, Cmd.none )


highlightUser : UserId -> Coord WorldUnit -> FrontendLoaded -> FrontendLoaded
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
                |> Coord.toRawCoord
    in
    { model | cursor = Cursor.setCursor (Bounds.minimum bounds) }
        |> changeText (String.repeat w " " |> List.repeat h |> String.join "\n")
        |> (\m -> { m | cursor = model.cursor })


screenToWorld : FrontendLoaded -> Point2d Pixels ScreenCoordinate -> Point2d WorldPixel WorldCoordinate
screenToWorld model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> Point2d.at (Quantity.divideBy (toFloat model.zoomFactor) model.devicePixelRatio)
        >> Point2d.placeIn (Units.screenFrame (actualViewPoint model))


worldToScreen : FrontendLoaded -> Point2d WorldPixel WorldCoordinate -> Point2d Pixels ScreenCoordinate
worldToScreen model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5 |> Vector2d.reverse)
        << Point2d.at_ (Quantity.divideBy (toFloat model.zoomFactor) model.devicePixelRatio)
        << Point2d.relativeTo (Units.screenFrame (actualViewPoint model))


selectionPoint : Coord WorldUnit -> EverySet UserId -> EverySet UserId -> Grid -> Maybe { userId : UserId, value : Tile }
selectionPoint position hiddenUsers hiddenUsersForAll grid =
    let
        ( cellPosition, localPosition ) =
            Grid.tileToCellAndLocalCoord position
    in
    case Grid.getCell cellPosition grid of
        Just cell ->
            GridCell.flatten hiddenUsers hiddenUsersForAll cell
                |> List.find (.position >> (==) localPosition)
                |> Maybe.map (\{ userId, value } -> { userId = userId, value = value })

        Nothing ->
            Nothing


windowResizedUpdate : Coord Pixels -> { b | windowSize : Coord Pixels } -> ( { b | windowSize : Coord Pixels }, Cmd msg )
windowResizedUpdate windowSize model =
    ( { model | windowSize = windowSize }, martinsstewart_elm_device_pixel_ratio_to_js () )


devicePixelRatioUpdate :
    Quantity Float (Rate WorldPixel Pixels)
    -> { b | devicePixelRatio : Quantity Float (Rate WorldPixel Pixels), zoomFactor : Int }
    -> ( { b | devicePixelRatio : Quantity Float (Rate WorldPixel Pixels), zoomFactor : Int }, Cmd msg )
devicePixelRatioUpdate devicePixelRatio model =
    ( { model
        | devicePixelRatio = devicePixelRatio
        , zoomFactor = toFloat model.zoomFactor * Quantity.ratio devicePixelRatio model.devicePixelRatio |> round
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
                        model_ =
                            if Duration.from model.undoAddLast model.time |> Quantity.greaterThan (Duration.seconds 0.5) then
                                updateLocalModel Change.LocalAddUndo { model | undoAddLast = model.time }

                            else
                                model
                    in
                    updateLocalModel
                        (Change.LocalGridChange
                            { position = Cursor.position model.cursor
                            , change = tile
                            }
                        )
                        { model_
                            | trains =
                                if tile == TrainHouseLeft || tile == TrainHouseRight then
                                    let
                                        v =
                                            Vector2d.unsafe { x = 2, y = 2.5 }
                                    in
                                    { position =
                                        Cursor.position model.cursor
                                            |> Coord.toPoint2d
                                            |> Point2d.translateBy v
                                    }
                                        :: model_.trains

                                else
                                    model_.trains
                        }

                Nothing ->
                    model

        [] ->
            model


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

        oldHidden : EverySet UserId
        oldHidden =
            LocalGrid.localModel oldModel.localModel |> .hiddenUsers |> showHighlighted oldModel

        oldHiddenForAll : EverySet UserId
        oldHiddenForAll =
            LocalGrid.localModel oldModel.localModel |> .adminHiddenUsers |> showHighlighted oldModel

        newCells : Dict ( Int, Int ) GridCell.Cell
        newCells =
            LocalGrid.localModel newModel.localModel |> .grid |> Grid.allCellsDict

        newHidden : EverySet UserId
        newHidden =
            LocalGrid.localModel newModel.localModel |> .hiddenUsers |> showHighlighted newModel

        newHiddenForAll : EverySet UserId
        newHiddenForAll =
            LocalGrid.localModel newModel.localModel |> .adminHiddenUsers |> showHighlighted newModel

        newMesh : GridCell.Cell -> ( Int, Int ) -> WebGL.Mesh Grid.Vertex
        newMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.fromRawCoord rawCoord
            in
            Grid.mesh
                coord
                (GridCell.flatten newHidden newHiddenForAll newCell)

        hiddenUnchanged : Bool
        hiddenUnchanged =
            oldHidden == newHidden && oldHiddenForAll == newHiddenForAll

        hiddenChanges : List UserId
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
            Point2d.xy minX minY |> Tile.worldToTile |> Grid.tileToCellAndLocalCoord |> Tuple.first

        max_ =
            Point2d.xy maxX maxY
                |> Tile.worldToTile
                |> Grid.tileToCellAndLocalCoord
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
    -> Point2d Pixels ScreenCoordinate
    -> Point2d Pixels ScreenCoordinate
    -> Point2d WorldPixel WorldCoordinate
offsetViewPoint { windowSize, viewPoint, devicePixelRatio, zoomFactor } mouseStart mouseCurrent =
    let
        delta : Vector2d WorldPixel WorldCoordinate
        delta =
            Vector2d.from mouseCurrent mouseStart
                |> Vector2d.at (Quantity.divideBy (toFloat zoomFactor) devicePixelRatio)
                |> Vector2d.placeIn (Units.screenFrame viewPoint)
    in
    Point2d.translateBy delta viewPoint


actualViewPoint : FrontendLoaded -> Point2d WorldPixel WorldCoordinate
actualViewPoint model =
    case ( model.mouseLeft, model.mouseMiddle ) of
        ( _, MouseButtonDown { start, current } ) ->
            offsetViewPoint model start current

        ( MouseButtonDown { start, current }, _ ) ->
            case model.tool of
                DragTool ->
                    offsetViewPoint model start current

                HighlightTool _ ->
                    offsetViewPoint model start current

                SelectTool ->
                    model.viewPoint

        _ ->
            model.viewPoint


updateFromBackend : ToFrontend -> FrontendModel_ -> ( FrontendModel_, Cmd FrontendMsg_ )
updateFromBackend msg model =
    case ( model, msg ) of
        ( Loading loading, LoadingData loadingData ) ->
            loadedInit loading loadingData

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

        NotifyMeEmailSent result ->
            ( { model | notifyMeModel = NotifyMe.confirmSubmit result model.notifyMeModel }, Cmd.none )

        NotifyMeConfirmed ->
            ( { model | notifyMeModel = NotifyMe.emailConfirmed model.notifyMeModel }, Cmd.none )

        UnsubscribeEmailConfirmed ->
            ( { model | notifyMeModel = NotifyMe.unsubscribed model.notifyMeModel }, Cmd.none )


textarea : FrontendLoaded -> Element.Attribute FrontendMsg_
textarea model =
    if cursorEnabled model then
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

    else
        Element.el
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.htmlAttribute <|
                Html.Events.Extra.Mouse.onDown
                    (\{ clientPos, button } ->
                        MouseDown button (Point2d.pixels (Tuple.first clientPos) (Tuple.second clientPos))
                    )
            ]
            Element.none
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
    let
        notifyMeView : { a | showNotifyMe : Bool, notifyMeModel : NotifyMe.Model } -> Element.Attribute FrontendMsg_
        notifyMeView a =
            Element.inFront
                (if a.showNotifyMe then
                    (case model of
                        Loading loading ->
                            NotifyMe.view loading

                        Loaded loaded ->
                            NotifyMe.view loaded
                    )
                        NotifyMeModelChanged
                        PressedSubmitNotifyMe
                        PressedCancelNotifyMe
                        a.notifyMeModel

                 else
                    Element.none
                )
    in
    { title =
        case model of
            Loading _ ->
                "Ascii Collab"

            Loaded loadedModel ->
                if lostConnection loadedModel then
                    "Ascii Collab (offline)"

                else
                    "Ascii Collab"
    , body =
        [ case model of
            Loading loadingModel ->
                Element.layout
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    , notifyMeView loadingModel
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
                        ++ [ notifyMeView loadedModel ]
                    )
                    (Element.html (canvasView loadedModel))
        , Html.node "style"
            []
            [ Html.text "@font-face { font-family: ascii; src: url('ascii.ttf'); }" ]
        ]
    }


contextMenuView : { userId : UserId, hidePoint : Coord WorldUnit } -> FrontendLoaded -> Element FrontendMsg_
contextMenuView { userId, hidePoint } loadedModel =
    let
        { x, y } =
            Coord.addTuple ( Units.tileUnit 1, Units.tileUnit 1 ) hidePoint
                |> Tile.tileToWorld
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


currentUserId : FrontendLoaded -> UserId
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
                    :: buttonAttributes (isActive userId)
                )
                (colorSquareInner userId)

        colorSquareInner : UserId -> Element FrontendMsg_
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
                        [ User.rawId userId |> String.fromInt |> Element.text ]

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

        baseTag : Bool -> Bool -> Element FrontendMsg_ -> UserId -> Element FrontendMsg_
        baseTag isFirst isLast content userId =
            Element.row
                [ Element.width Element.fill
                , "User Id: "
                    ++ String.fromInt (User.rawId userId)
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

        hiddenUserTag : Bool -> Bool -> UserId -> Element FrontendMsg_
        hiddenUserTag isFirst isLast userId =
            Element.Input.button
                (Element.Events.onMouseEnter (UserTagMouseEntered userId)
                    :: Element.Events.onMouseLeave (UserTagMouseExited userId)
                    :: Element.width Element.fill
                    :: Element.padding 4
                    :: rowBorderWidth isFirst isLast
                    ++ buttonAttributes (isActive userId)
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

        hiddenUserForAllTag : Bool -> Bool -> UserId -> Element FrontendMsg_
        hiddenUserForAllTag isFirst isLast userId =
            Element.Input.button
                (Element.Events.onMouseEnter (UserTagMouseEntered userId)
                    :: Element.Events.onMouseLeave (UserTagMouseExited userId)
                    :: Element.width Element.fill
                    :: Element.padding 4
                    :: rowBorderWidth isFirst isLast
                    ++ buttonAttributes (isActive userId)
                )
                { onPress = Just (HideForAllTogglePressed userId)
                , label =
                    Element.row [ Element.width Element.fill ]
                        [ colorSquareInner userId
                        , Element.el [ Element.centerX ] (Element.text "Unhide for all")
                        ]
                }

        buttonAttributes isActive_ =
            [ Element.Border.color UiColors.border
            , Element.Background.color
                (if isActive_ then
                    UiColors.buttonActive

                 else
                    UiColors.button
                )
            ]

        hiddenUserList : List UserId
        hiddenUserList =
            EverySet.diff localModel.hiddenUsers localModel.adminHiddenUsers
                |> EverySet.toList

        isActive : UserId -> Bool
        isActive userId =
            (model.userHoverHighlighted == Just userId)
                || (case model.tool of
                        HighlightTool (Just ( hideUserId, _ )) ->
                            hideUserId == userId

                        _ ->
                            False
                   )

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

        hiddenusersForAllList : List UserId
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
                (cursorEnabled model)
                (Element.image
                    [ Element.width (Element.px 22) ]
                    { src = "copy.svg", description = "Copy text button" }
                )
            , toolbarButton
                []
                CutPressed
                (cursorEnabled model)
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
    , ( HighlightTool Nothing
      , \tool ->
            case tool of
                HighlightTool _ ->
                    True

                _ ->
                    False
      , Icons.highlightTool
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
        (Quantity pixelRatio) =
            frontendModel.devicePixelRatio

        findValue : Quantity Int Pixels -> ( Int, Int )
        findValue value =
            List.range 0 9
                |> List.map ((+) (Pixels.inPixels value))
                |> List.find
                    (\v ->
                        let
                            a =
                                toFloat v * pixelRatio
                        in
                        a == toFloat (round a) && modBy 2 (round a) == 0
                    )
                |> Maybe.map (\v -> ( v, toFloat v * pixelRatio |> round ))
                |> Maybe.withDefault ( Pixels.inPixels value, toFloat (Pixels.inPixels value) * pixelRatio |> round )

        ( w, actualW ) =
            findValue (Tuple.first frontendModel.windowSize)

        ( h, actualH ) =
            findValue (Tuple.second frontendModel.windowSize)
    in
    { canvasSize = ( w, h ), actualCanvasSize = ( actualW, actualH ) }


viewBoundingBox : FrontendLoaded -> BoundingBox2d WorldPixel WorldCoordinate
viewBoundingBox model =
    let
        viewMin =
            screenToWorld model Point2d.origin
                |> Point2d.translateBy
                    (Coord.fromRawCoord ( -1, -1 )
                        |> Units.cellToTile
                        |> Tile.tileToWorld
                        |> Coord.toVector2d
                    )

        viewMax =
            screenToWorld model (Coord.toPoint2d model.windowSize)
    in
    BoundingBox2d.from viewMin viewMax


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
                    (negate <| toFloat <| round x)
                    (negate <| toFloat <| round y)
                    0
    in
    WebGL.toHtmlWith
        [ WebGL.alpha False, WebGL.antialias, WebGL.clearColor 0.8 1 0.7 1 ]
        [ Html.Attributes.width windowWidth
        , Html.Attributes.height windowHeight
        , Html.Attributes.style "width" (String.fromInt cssWindowWidth ++ "px")
        , Html.Attributes.style "height" (String.fromInt cssWindowHeight ++ "px")
        ]
        ((if cursorEnabled model then
            [ Cursor.draw viewMatrix (Element.rgba 1 0 1 0.5) model ]

          else
            []
         )
            ++ (case model.texture of
                    Just texture ->
                        drawText
                            (Dict.filter
                                (\key _ ->
                                    Coord.fromRawCoord key
                                        |> Units.cellToTile
                                        |> Tile.tileToWorld
                                        |> Coord.toPoint2d
                                        |> (\p -> BoundingBox2d.contains p viewBounds_)
                                )
                                model.meshes
                            )
                            viewMatrix
                            texture
                            ++ drawTrains model.trains viewMatrix texture

                    Nothing ->
                        []
               )
        )


getHighlight : FrontendLoaded -> Maybe UserId
getHighlight model =
    case model.highlightContextMenu of
        Just { userId } ->
            Just userId

        Nothing ->
            model.userHoverHighlighted


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
                    }
            )


drawTrains : List Train -> Mat4 -> Texture -> List WebGL.Entity
drawTrains trains viewMatrix texture =
    List.map
        (\train ->
            let
                { x, y } =
                    Point2d.unwrap train.position

                ( Quantity w, Quantity h ) =
                    Tile.size
            in
            WebGL.entityWith
                [ Blend.add Blend.one Blend.oneMinusSrcAlpha
                ]
                Shaders.vertexShader
                Shaders.fragmentShader2
                square
                { view = Mat4.makeTranslate3 (x * w) (y * h) 0 |> Mat4.mul viewMatrix
                , texture = texture
                }
        )
        trains


square =
    WebGL.triangleFan
        [ { position = Vec2.vec2 -10 -10, texturePosition = Vec2.vec2 0 0 }
        , { position = Vec2.vec2 -10 10, texturePosition = Vec2.vec2 0 1 }
        , { position = Vec2.vec2 10 10, texturePosition = Vec2.vec2 1 1 }
        , { position = Vec2.vec2 10 -10, texturePosition = Vec2.vec2 1 0 }
        ]


subscriptions : AudioData -> FrontendModel_ -> Sub FrontendMsg_
subscriptions _ model =
    Sub.batch
        [ martinsstewart_elm_device_pixel_ratio_from_js
            (Units.worldUnit >> Quantity.per Pixels.pixel >> GotDevicePixelRatio)
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
                    , if getHighlight loadedModel /= Nothing then
                        Browser.Events.onAnimationFrame AnimationFrame

                      else
                        Sub.none
                    ]
        ]
