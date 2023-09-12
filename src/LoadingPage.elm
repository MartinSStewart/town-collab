module LoadingPage exposing
    ( canPlaceTile
    , createReportsMesh
    , cursorPosition
    , devicePixelRatioChanged
    , getAdminReports
    , getHandColor
    , getReports
    , getTileColor
    , loadingCanvasView
    , loadingCellBounds
    , mouseListeners
    , mouseScreenPosition
    , mouseWorldPosition
    , setCurrentTool
    , setCurrentToolWithColors
    , update
    , updateMeshes
    , viewBoundsUpdate
    , viewLoadingBoundingBox
    , windowResizedUpdate
    )

import Array
import AssocList
import BoundingBox2d exposing (BoundingBox2d)
import Bounds exposing (Bounds)
import Change exposing (BackendReport, Change(..), Report, UserStatus(..))
import Color exposing (Colors)
import Coord exposing (Coord)
import Cursor
import Dict exposing (Dict)
import Duration
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Effect.Task
import Effect.Time as Time
import Effect.WebGL
import Effect.WebGL.Texture exposing (Texture)
import Grid exposing (Grid)
import GridCell
import Html exposing (Html)
import Html.Attributes
import Html.Events.Extra.Mouse exposing (Button(..))
import Id exposing (Id, TrainId, UserId)
import IdDict exposing (IdDict)
import Image
import Keyboard
import List.Extra as List
import List.Nonempty exposing (Nonempty)
import LocalGrid exposing (LocalGrid, LocalGrid_)
import LocalModel exposing (LocalModel)
import MailEditor
import Math.Matrix4 as Mat4
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Ports
import Quantity exposing (Quantity)
import Random
import Set exposing (Set)
import Shaders exposing (Vertex)
import Sound
import Sprite
import Terrain
import TextInput
import Tile exposing (Tile, TileGroup(..))
import Tool exposing (Tool(..))
import Toolbar
import Train exposing (Train)
import Types exposing (CssPixels, FrontendLoaded, FrontendLoading, FrontendModel_(..), FrontendMsg_(..), LoadedLocalModel_, LoadingLocalModel(..), MouseButtonState(..), SubmitStatus(..), ToBackend(..), ToolButton(..), UpdateMeshesData, ViewPoint(..))
import Ui
import Units exposing (CellUnit, WorldUnit)
import WebGL.Texture


update : FrontendMsg_ -> FrontendLoading -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
update msg loadingModel =
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
                    ( Loading loadingModel, Command.none )

        SimplexLookupTextureLoaded result ->
            case result of
                Ok texture ->
                    ( Loading { loadingModel | simplexNoiseLookup = Just texture }, Command.none )

                Err _ ->
                    ( Loading loadingModel, Command.none )

        MouseMove mousePosition ->
            ( Loading { loadingModel | mousePosition = mousePosition }, Command.none )

        MouseUp MainButton mousePosition ->
            if insideStartButton mousePosition loadingModel then
                case tryLoading loadingModel of
                    Just a ->
                        a ()

                    Nothing ->
                        ( Loading loadingModel, Command.none )

            else
                ( Loading loadingModel, Command.none )

        KeyDown rawKey ->
            case Keyboard.anyKeyOriginal rawKey of
                Just Keyboard.Enter ->
                    case tryLoading loadingModel of
                        Just a ->
                            a ()

                        Nothing ->
                            ( Loading loadingModel, Command.none )

                _ ->
                    ( Loading loadingModel, Command.none )

        AnimationFrame time ->
            ( Loading { loadingModel | time = Just time }, Command.none )

        GotUserAgentPlatform userAgentPlatform ->
            ( Loading { loadingModel | hasCmdKey = String.startsWith "mac" (String.toLower userAgentPlatform) }
            , Ports.webGlFix
            )

        LoadedUserSettings userSettings ->
            ( Loading
                { loadingModel
                    | musicVolume = userSettings.musicVolume
                    , soundEffectVolume = userSettings.soundEffectVolume
                }
            , Command.none
            )

        GotWebGlFix ->
            ( Loading loadingModel
            , Command.batch
                [ Effect.WebGL.Texture.loadWith
                    { magnify = Effect.WebGL.Texture.nearest
                    , minify = Effect.WebGL.Texture.nearest
                    , horizontalWrap = Effect.WebGL.Texture.clampToEdge
                    , verticalWrap = Effect.WebGL.Texture.clampToEdge
                    , flipY = False
                    }
                    "/texture.png"
                    |> Effect.Task.attempt TextureLoaded
                , Effect.Task.attempt SimplexLookupTextureLoaded loadSimplexTexture
                ]
            )

        _ ->
            ( Loading loadingModel, Command.none )


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


loadedInit :
    Time.Posix
    -> FrontendLoading
    -> Texture
    -> Texture
    -> LoadedLocalModel_
    -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_ )
loadedInit time loading texture simplexNoiseLookup loadedLocalModel =
    let
        currentTool2 =
            HandTool

        defaultTileColors =
            AssocList.empty

        currentUserId2 =
            LocalGrid.currentUserId loadedLocalModel

        viewpoint =
            Coord.toPoint2d loading.viewPoint |> NormalViewPoint

        mouseLeft =
            MouseButtonUp { current = loading.mousePosition }

        mouseMiddle =
            MouseButtonUp { current = loading.mousePosition }

        previousUpdateMeshData : UpdateMeshesData
        previousUpdateMeshData =
            { localModel = loadedLocalModel.localModel
            , pressedKeys = []
            , currentTool = currentTool2
            , mouseLeft = mouseLeft
            , mouseMiddle = mouseMiddle
            , windowSize = loading.windowSize
            , devicePixelRatio = loading.devicePixelRatio
            , zoomFactor = loading.zoomFactor
            , mailEditor = Nothing
            , viewPoint = viewpoint
            , trains = loadedLocalModel.trains
            , time = time
            }

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = loadedLocalModel.localModel
            , trains = loadedLocalModel.trains
            , meshes = Dict.empty
            , viewPoint = viewpoint
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
            , mouseLeft = mouseLeft
            , mouseMiddle = mouseMiddle
            , pendingChanges = []
            , undoAddLast = Time.millisToPosix 0
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
            , currentTool = currentTool2
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
            , contextMenu = Nothing
            , previousUpdateMeshData = previousUpdateMeshData
            , reportsMesh =
                createReportsMesh
                    (getReports loadedLocalModel.localModel)
                    (getAdminReports loadedLocalModel.localModel)
            , lastReportTilePlaced = Nothing
            , lastReportTileRemoved = Nothing
            , hideUi = False
            }
                |> setCurrentTool HandToolButton
    in
    ( updateMeshes model
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


canPlaceTile : Time.Posix -> Grid.GridChange -> IdDict TrainId Train -> Grid -> Bool
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


updateMeshes : FrontendLoaded -> FrontendLoaded
updateMeshes newModel =
    let
        oldModel =
            newModel.previousUpdateMeshData

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
            case LocalGrid.currentTool model of
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

                ReportTool ->
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
            LocalGrid.currentUserId newModel

        newMesh : Maybe (Effect.WebGL.Mesh Vertex) -> GridCell.Cell -> ( Int, Int ) -> { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
        newMesh backgroundMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.tuple rawCoord
            in
            { foreground =
                Grid.foregroundMesh2
                    newShowEmptyTiles
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

        newShowEmptyTiles =
            newModel.currentTool == ReportTool

        oldShowEmptyTiles =
            newModel.previousUpdateMeshData.currentTool == ReportTool
    in
    { newModel
        | meshes =
            Dict.map
                (\coord newCell ->
                    case Dict.get coord oldCells of
                        Just oldCell ->
                            if oldCell == newCell && (newShowEmptyTiles == oldShowEmptyTiles) then
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
        , previousUpdateMeshData =
            { localModel = newModel.localModel
            , pressedKeys = newModel.pressedKeys
            , currentTool = newModel.currentTool
            , mouseLeft = newModel.mouseLeft
            , windowSize = newModel.windowSize
            , devicePixelRatio = newModel.devicePixelRatio
            , zoomFactor = newModel.zoomFactor
            , mailEditor = newModel.mailEditor
            , mouseMiddle = newModel.mouseMiddle
            , viewPoint = newModel.viewPoint
            , trains = newModel.trains
            , time = newModel.time
            }
    }


mouseWorldPosition :
    { a
        | mouseLeft : MouseButtonState
        , windowSize : ( Quantity Int Pixels, Quantity Int Pixels )
        , devicePixelRatio : Float
        , zoomFactor : Int
        , mailEditor : Maybe b
        , mouseMiddle : MouseButtonState
        , viewPoint : ViewPoint
        , trains : IdDict TrainId Train
        , time : Time.Posix
        , currentTool : Tool
    }
    -> Point2d WorldUnit WorldUnit
mouseWorldPosition model =
    mouseScreenPosition model |> Toolbar.screenToWorld model


mouseScreenPosition : { a | mouseLeft : MouseButtonState } -> Point2d Pixels Pixels
mouseScreenPosition model =
    case model.mouseLeft of
        MouseButtonDown { current } ->
            current

        MouseButtonUp { current } ->
            current


cursorPosition :
    { a | size : Coord WorldUnit }
    ->
        { b
            | mouseLeft : MouseButtonState
            , windowSize : ( Quantity Int Pixels, Quantity Int Pixels )
            , devicePixelRatio : Float
            , zoomFactor : Int
            , mailEditor : Maybe c
            , mouseMiddle : MouseButtonState
            , viewPoint : ViewPoint
            , trains : IdDict TrainId Train
            , time : Time.Posix
            , currentTool : Tool
        }
    -> Coord WorldUnit
cursorPosition tileData model =
    mouseWorldPosition model
        |> Coord.floorPoint
        |> Coord.minus (tileData.size |> Coord.divide (Coord.tuple ( 2, 2 )))


defaultTileHotkeys : Dict String TileGroup
defaultTileHotkeys =
    Dict.fromList
        [ ( " ", EmptyTileGroup )
        , ( "1", HouseGroup )
        , ( "a", ApartmentGroup )
        , ( "2", HospitalGroup )
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


setCurrentTool : ToolButton -> FrontendLoaded -> FrontendLoaded
setCurrentTool toolButton model =
    let
        colors =
            case toolButton of
                TilePlacerToolButton tileGroup ->
                    getTileColor tileGroup model

                HandToolButton ->
                    case LocalGrid.currentUserId model of
                        Just userId ->
                            getHandColor userId model

                        Nothing ->
                            Cursor.defaultColors

                TilePickerToolButton ->
                    { primaryColor = Color.white, secondaryColor = Color.black }

                TextToolButton ->
                    getTileColor BigTextGroup model

                ReportToolButton ->
                    { primaryColor = Color.white, secondaryColor = Color.black }

        tool =
            case toolButton of
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

                ReportToolButton ->
                    ReportTool
    in
    setCurrentToolWithColors tool colors model


setCurrentToolWithColors : Tool -> Colors -> FrontendLoaded -> FrontendLoaded
setCurrentToolWithColors tool colors model =
    { model
        | currentTool = tool
        , primaryColorTextInput = TextInput.init |> TextInput.withText (Color.toHexCode colors.primaryColor)
        , secondaryColorTextInput = TextInput.init |> TextInput.withText (Color.toHexCode colors.secondaryColor)
        , tileColors =
            case tool of
                TilePlacerTool { tileGroup } ->
                    AssocList.insert tileGroup colors model.tileColors

                HandTool ->
                    model.tileColors

                TilePickerTool ->
                    model.tileColors

                TextTool _ ->
                    AssocList.insert BigTextGroup colors model.tileColors

                ReportTool ->
                    model.tileColors
    }


getTileColor : TileGroup -> { a | tileColors : AssocList.Dict TileGroup Colors } -> Colors
getTileColor tileGroup model =
    case AssocList.get tileGroup model.tileColors of
        Just a ->
            a

        Nothing ->
            Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary


getReports : LocalModel a LocalGrid -> List Report
getReports localModel =
    case LocalGrid.localModel localModel |> .userStatus of
        LoggedIn loggedIn ->
            loggedIn.reports

        NotLoggedIn ->
            []


getAdminReports : LocalModel a LocalGrid -> IdDict UserId (Nonempty BackendReport)
getAdminReports localModel =
    case LocalGrid.localModel localModel |> .userStatus of
        LoggedIn loggedIn ->
            case loggedIn.adminData of
                Just adminData ->
                    adminData.reported

                Nothing ->
                    IdDict.empty

        NotLoggedIn ->
            IdDict.empty


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


viewLoadingBoundingBox : FrontendLoaded -> BoundingBox2d WorldUnit WorldUnit
viewLoadingBoundingBox model =
    let
        viewMin =
            Toolbar.screenToWorld model Point2d.origin
                |> Point2d.translateBy
                    (Coord.tuple ( -2, -2 )
                        |> Units.cellToTile
                        |> Coord.toVector2d
                    )

        viewMax =
            Toolbar.screenToWorld model (Coord.toPoint2d model.windowSize)
    in
    BoundingBox2d.from viewMin viewMax


createReportsMesh : List Report -> IdDict UserId (Nonempty BackendReport) -> Effect.WebGL.Mesh Vertex
createReportsMesh localReports adminReports =
    List.concatMap
        (\( _, reports ) ->
            List.Nonempty.toList reports
                |> List.concatMap
                    (\report ->
                        Sprite.spriteWithColor
                            Color.adminReportColor
                            (Coord.multiply Units.tileSize report.position)
                            Units.tileSize
                            (Coord.xy 100 738)
                            Units.tileSize
                    )
        )
        (IdDict.toList adminReports)
        ++ List.concatMap
            (\report ->
                Sprite.spriteWithColor
                    Color.localReportColor
                    (Coord.multiply Units.tileSize report.position)
                    Units.tileSize
                    (Coord.xy 100 738)
                    Units.tileSize
            )
            localReports
        |> Sprite.toMesh


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


windowResizedUpdate :
    Coord CssPixels
    -> { b | cssWindowSize : Coord CssPixels, windowSize : Coord Pixels, cssCanvasSize : Coord CssPixels, devicePixelRatio : Float }
    ->
        ( { b | cssWindowSize : Coord CssPixels, windowSize : Coord Pixels, cssCanvasSize : Coord CssPixels, devicePixelRatio : Float }
        , Command FrontendOnly ToBackend msg
        )
windowResizedUpdate cssWindowSize model =
    let
        { cssCanvasSize, windowSize } =
            findPixelPerfectSize { devicePixelRatio = model.devicePixelRatio, cssWindowSize = cssWindowSize }
    in
    ( { model | cssWindowSize = cssWindowSize, cssCanvasSize = cssCanvasSize, windowSize = windowSize }
    , Ports.getDevicePixelRatio
    )


devicePixelRatioChanged devicePixelRatio model =
    let
        { cssCanvasSize, windowSize } =
            findPixelPerfectSize { devicePixelRatio = devicePixelRatio, cssWindowSize = model.cssWindowSize }
    in
    ( { model | devicePixelRatio = devicePixelRatio, cssCanvasSize = cssCanvasSize, windowSize = windowSize }
    , Command.none
    )


findPixelPerfectSize :
    { devicePixelRatio : Float, cssWindowSize : Coord CssPixels }
    -> { cssCanvasSize : Coord CssPixels, windowSize : Coord Pixels }
findPixelPerfectSize frontendModel =
    let
        findValue : Quantity Int CssPixels -> ( Int, Int )
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
