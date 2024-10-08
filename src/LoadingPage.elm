module LoadingPage exposing
    ( animalActualPosition
    , canPlaceTile
    , createReportsMesh
    , cursorActualPosition
    , cursorPosition
    , devicePixelRatioChanged
    , getAdminReports
    , getHandColor
    , getReports
    , getTileColor
    , handleOutMsg
    , hoverAt
    , initWorldPage
    , loadingCanvasView
    , loadingCellBounds
    , mouseListeners
    , mouseScreenPosition
    , mouseWorldPosition
    , npcActualPosition
    , setCurrentTool
    , setCurrentToolWithColors
    , shortDelayDuration
    , showWorldPreview
    , update
    , updateLocalModel
    , updateMeshes
    , viewBoundsUpdate
    , windowResizedUpdate
    )

import AdminPage
import Animal exposing (Animal)
import AssocList
import AssocSet
import Audio exposing (AudioCmd)
import BoundingBox2d exposing (BoundingBox2d)
import Bounds exposing (Bounds)
import Change exposing (BackendReport, Change(..), Report, UserStatus(..))
import Codec
import Color exposing (Colors)
import Coord exposing (Coord)
import Cursor exposing (AnimalOrNpcId(..), Cursor, Holding(..))
import Dict exposing (Dict)
import Duration exposing (Duration)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File.Download
import Effect.File.Select
import Effect.Lamdera
import Effect.Task
import Effect.Time as Time
import Effect.WebGL
import Effect.WebGL.Texture exposing (Texture)
import Grid exposing (Grid)
import GridCell exposing (FrontendHistory)
import Html exposing (Html)
import Html.Attributes
import Html.Events.Extra.Mouse exposing (Button(..))
import Hyperlink
import Id exposing (AnimalId, Id, NpcId, TrainId, UserId)
import Keyboard
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Local exposing (Local)
import LocalGrid exposing (LocalGrid)
import MailEditor
import Math.Matrix4 as Mat4
import Math.Vector4 as Vec4
import Npc exposing (Npc)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Ports
import Quantity exposing (Quantity)
import Random
import Route exposing (PageRoute(..))
import SeqDict exposing (SeqDict)
import Set exposing (Set)
import Shaders
import Sound
import Sprite exposing (Vertex)
import TextInput
import TextInputMultiline
import Tile exposing (Category(..), Tile(..), TileGroup(..))
import Tool exposing (Tool(..))
import Toolbar
import Train exposing (Train)
import Types exposing (ContextMenu(..), CssPixels, FrontendLoaded, FrontendLoading, FrontendModel_(..), FrontendMsg_(..), Hover(..), LoadedLocalModel_, LoadingLocalModel(..), MouseButtonState(..), Page(..), SubmitStatus(..), ToBackend(..), ToolButton(..), UiId(..), UpdateMeshesData, ViewPoint(..), WorldPage2)
import Ui
import Units exposing (CellUnit, WorldUnit)
import Vector2d


update :
    FrontendMsg_
    -> FrontendLoading
    -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
update msg loadingModel =
    case msg of
        ShortIntervalElapsed time ->
            ( Loading { loadingModel | time = Just time }, Command.none, Audio.cmdNone )

        WindowResized windowSize ->
            windowResizedUpdate windowSize loadingModel |> (\( a, b ) -> ( Loading a, b, Audio.cmdNone ))

        GotDevicePixelRatio devicePixelRatio ->
            devicePixelRatioChanged devicePixelRatio loadingModel
                |> (\( a, b ) -> ( Loading a, b, Audio.cmdNone ))

        SoundLoaded sound result ->
            ( Loading { loadingModel | sounds = AssocList.insert sound result loadingModel.sounds }
            , Command.none
            , Audio.cmdNone
            )

        TextureLoaded result ->
            case result of
                Ok texture ->
                    ( Loading { loadingModel | texture = Just texture }, Command.none, Sound.load SoundLoaded )

                Err _ ->
                    ( Loading loadingModel, Command.none, Audio.cmdNone )

        LightsTextureLoaded result ->
            case result of
                Ok texture ->
                    ( Loading { loadingModel | lightsTexture = Just texture }, Command.none, Audio.cmdNone )

                Err _ ->
                    ( Loading loadingModel, Command.none, Audio.cmdNone )

        DepthTextureLoaded result ->
            case result of
                Ok texture ->
                    ( Loading { loadingModel | depthTexture = Just texture }, Command.none, Audio.cmdNone )

                Err _ ->
                    ( Loading loadingModel, Command.none, Audio.cmdNone )

        MouseMove mousePosition ->
            ( Loading { loadingModel | mousePosition = mousePosition }, Command.none, Audio.cmdNone )

        MouseUp MainButton mousePosition ->
            if insideStartButton mousePosition loadingModel then
                case tryLoading loadingModel of
                    Just a ->
                        a ()

                    Nothing ->
                        ( Loading loadingModel, Command.none, Audio.cmdNone )

            else
                ( Loading loadingModel, Command.none, Audio.cmdNone )

        KeyDown rawKey ->
            case Keyboard.anyKeyOriginal rawKey of
                Just Keyboard.Enter ->
                    case tryLoading loadingModel of
                        Just a ->
                            a ()

                        Nothing ->
                            ( Loading loadingModel, Command.none, Audio.cmdNone )

                _ ->
                    ( Loading loadingModel, Command.none, Audio.cmdNone )

        AnimationFrame time ->
            ( Loading { loadingModel | time = Just time }, Command.none, Audio.cmdNone )

        GotUserAgentPlatform userAgentPlatform ->
            ( Loading { loadingModel | hasCmdKey = String.startsWith "mac" (String.toLower userAgentPlatform) }
            , Command.none
            , Audio.cmdNone
            )

        LoadedUserSettings userSettings ->
            ( Loading
                { loadingModel
                    | musicVolume = userSettings.musicVolume
                    , soundEffectVolume = userSettings.soundEffectVolume
                }
            , Command.none
            , Audio.cmdNone
            )

        _ ->
            ( Loading loadingModel, Command.none, Audio.cmdNone )


tryLoading :
    FrontendLoading
    ->
        Maybe
            (()
             ->
                ( FrontendModel_
                , Command FrontendOnly ToBackend FrontendMsg_
                , AudioCmd FrontendMsg_
                )
            )
tryLoading frontendLoading =
    case frontendLoading.localModel of
        LoadingLocalModel _ ->
            Nothing

        LoadedLocalModel loadedLocalModel ->
            Maybe.map5
                (\time texture lightsTexture depthTexture simplexNoiseLookup () ->
                    loadedInit time frontendLoading texture lightsTexture depthTexture simplexNoiseLookup loadedLocalModel
                )
                frontendLoading.time
                frontendLoading.texture
                frontendLoading.lightsTexture
                frontendLoading.depthTexture
                frontendLoading.simplexNoiseLookup


initWorldPage : WorldPage2
initWorldPage =
    { showMap = False, showInvite = False }


loadedInit :
    Time.Posix
    -> FrontendLoading
    -> Texture
    -> Texture
    -> Texture
    -> Texture
    -> LoadedLocalModel_
    -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
loadedInit time loading texture lightsTexture depthTexture simplexNoiseLookup loadedLocalModel =
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
            , pressedKeys = AssocSet.empty
            , currentTool = currentTool2
            , mouseLeft = mouseLeft
            , mouseMiddle = mouseMiddle
            , windowSize = loading.windowSize
            , devicePixelRatio = loading.devicePixelRatio
            , zoomFactor = loading.zoomFactor
            , page = WorldPage initWorldPage
            , viewPoint = viewpoint
            , time = time
            }

        model : FrontendLoaded
        model =
            { key = loading.key
            , localModel = loadedLocalModel.localModel
            , meshes = Dict.empty
            , viewPoint = viewpoint
            , viewPointLastInterval = Point2d.origin
            , texture = texture
            , lightsTexture = lightsTexture
            , depthTexture = depthTexture
            , simplexNoiseLookup = simplexNoiseLookup
            , trainTexture = Nothing
            , trainLightsTexture = Nothing
            , trainDepthTexture = Nothing
            , pressedKeys = AssocSet.empty
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
            , ignoreNextUrlChanged = False
            , lastTilePlaced = Nothing
            , sounds = loading.sounds
            , musicVolume = loading.musicVolume
            , soundEffectVolume = loading.soundEffectVolume
            , removedTileParticles = []
            , debrisMesh = Shaders.triangleFan []
            , lastTrainWhistle = Nothing
            , page =
                case ( loading.route, Local.model loadedLocalModel.localModel |> .userStatus ) of
                    ( MailEditorRoute, LoggedIn _ ) ->
                        MailEditor.init Nothing |> MailPage

                    ( AdminRoute, LoggedIn loggedIn ) ->
                        case loggedIn.adminData of
                            Just _ ->
                                AdminPage.init |> AdminPage

                            Nothing ->
                                WorldPage initWorldPage

                    ( InviteTreeRoute, _ ) ->
                        InviteTreePage

                    _ ->
                        WorldPage initWorldPage
            , lastMailEditorToggle = Nothing
            , currentTool = currentTool2
            , lastTileRotation = []
            , lastPlacementError = Nothing
            , ui = Ui.none
            , uiMesh = Shaders.triangleFan []
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
            , previousHover = Nothing
            , music =
                { startTime = Duration.addTo time (Duration.seconds 10)
                , sound =
                    Random.step
                        (Sound.nextSong Nothing)
                        (Random.initialSeed (Time.posixToMillis time))
                        |> Tuple.first
                }
            , previousCursorPositions = SeqDict.empty
            , handMeshes =
                Local.model loadedLocalModel.localModel
                    |> .users
                    |> SeqDict.map
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
            , loginEmailInput = TextInput.init
            , pressedSubmitEmail = NotSubmitted { pressedSubmit = False }
            , topMenuOpened = Nothing
            , inviteTextInput = TextInput.init
            , inviteSubmitStatus = NotSubmitted { pressedSubmit = False }
            , railToggles = []
            , lastReceivedMail = Nothing
            , isReconnecting = False
            , lastCheckConnection = time
            , showOnlineUsers = False
            , contextMenu = NoContextMenu
            , previousUpdateMeshData = previousUpdateMeshData
            , reportsMesh =
                createReportsMesh
                    (getReports loadedLocalModel.localModel)
                    (getAdminReports loadedLocalModel.localModel)
            , lastReportTilePlaced = Nothing
            , lastReportTileRemoved = Nothing
            , hideUi = False
            , lightsSwitched = Nothing
            , selectedTileCategory = Buildings
            , tileCategoryPageIndex = AssocList.empty
            , lastHotkeyChange = Nothing
            , oneTimePasswordInput = TextInput.init
            , loginError = Nothing
            , hyperlinkInput = TextInputMultiline.init |> TextInputMultiline.withText "example.com"
            , lastTrainUpdate = time
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
            , premultiplyAlpha = False
            }
            "/trains.png"
            |> Effect.Task.attempt TrainTextureLoaded
        , Effect.WebGL.Texture.loadWith
            { magnify = Effect.WebGL.Texture.nearest
            , minify = Effect.WebGL.Texture.nearest
            , horizontalWrap = Effect.WebGL.Texture.clampToEdge
            , verticalWrap = Effect.WebGL.Texture.clampToEdge
            , flipY = False
            , premultiplyAlpha = False
            }
            "/train-lights.png"
            |> Effect.Task.attempt TrainLightsTextureLoaded
        , Effect.WebGL.Texture.loadWith
            { magnify = Effect.WebGL.Texture.nearest
            , minify = Effect.WebGL.Texture.nearest
            , horizontalWrap = Effect.WebGL.Texture.clampToEdge
            , verticalWrap = Effect.WebGL.Texture.clampToEdge
            , flipY = False
            , premultiplyAlpha = False
            }
            "/train-depth.png"
            |> Effect.Task.attempt TrainDepthTextureLoaded
        , Effect.Lamdera.sendToBackend PingRequest
        ]
    )
        |> viewBoundsUpdate
        |> (\( a, b ) -> ( Loaded a, b, Audio.cmdNone ))


canPlaceTile : Time.Posix -> Grid.GridChange -> SeqDict (Id TrainId) Train -> Grid a -> Bool
canPlaceTile time change trains grid =
    if Grid.canPlaceTile change then
        let
            ( cellPosition, localPosition ) =
                Grid.worldToCellAndLocalCoord change.position
        in
        ( cellPosition, localPosition )
            :: Grid.closeNeighborCells cellPosition localPosition
            |> List.any
                (\( cellPos, localPos ) ->
                    case Grid.getCell cellPos grid of
                        Just cell ->
                            GridCell.flatten cell
                                |> List.any
                                    (\value ->
                                        if value.tile == TrainHouseLeft || value.tile == TrainHouseRight then
                                            if Tile.hasCollision localPos change.change value.position value.tile then
                                                case
                                                    Train.canRemoveTiles time
                                                        [ { tile = value.tile
                                                          , position =
                                                                Grid.cellAndLocalCoordToWorld ( cellPos, value.position )
                                                          }
                                                        ]
                                                        trains
                                                of
                                                    Ok _ ->
                                                        False

                                                    Err _ ->
                                                        True

                                            else
                                                False

                                        else
                                            False
                                    )

                        Nothing ->
                            False
                )
            |> not
        --case Train.canRemoveTiles time removed trains of
        --    Ok _ ->
        --        True
        --
        --    Err _ ->
        --        False

    else
        False


expandHyperlink : Coord Units.CellLocalUnit -> List GridCell.Value -> Coord Units.CellLocalUnit
expandHyperlink startPos flattenedValues =
    let
        nextPos =
            Coord.plus (Coord.xy -1 0) startPos
    in
    if
        List.any
            (\value ->
                case value.tile of
                    BigText _ ->
                        nextPos == value.position

                    _ ->
                        False
            )
            flattenedValues
    then
        expandHyperlink nextPos flattenedValues

    else
        startPos


hardUpdateMeshes : FrontendLoaded -> FrontendLoaded
hardUpdateMeshes newModel =
    let
        localModel : LocalGrid
        localModel =
            Local.model newModel.localModel

        newCells : Dict ( Int, Int ) (GridCell.Cell FrontendHistory)
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

        newCurrentTile : Maybe { tile : Tile, position : Coord WorldUnit, cellPosition : Set ( Int, Int ), colors : Colors }
        newCurrentTile =
            currentTile newModel

        newMaybeUserId =
            LocalGrid.currentUserId newModel

        hyperlinksVisited : Set String
        hyperlinksVisited =
            case localModel.userStatus of
                LoggedIn loggedIn ->
                    loggedIn.hyperlinksVisited

                NotLoggedIn _ ->
                    Set.empty

        newMesh :
            Maybe (Effect.WebGL.Mesh Vertex)
            -> GridCell.Cell FrontendHistory
            -> ( Int, Int )
            -> { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
        newMesh backgroundMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.tuple rawCoord

                flattened : List GridCell.Value
                flattened =
                    GridCell.flatten newCell
            in
            { foreground =
                Grid.foregroundMesh2
                    (List.filterMap
                        (\value ->
                            case value.tile of
                                HyperlinkTile hyperlink ->
                                    let
                                        linkPos =
                                            expandHyperlink value.position flattened
                                    in
                                    Just
                                        { linkTopLeft = Grid.cellAndLocalCoordToWorld ( coord, linkPos )
                                        , linkWidth = Coord.x value.position - Coord.x linkPos
                                        , isVisited = Set.member (Hyperlink.toString hyperlink) hyperlinksVisited
                                        }

                                _ ->
                                    Nothing
                        )
                        flattened
                    )
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
                                    , time = newModel.time
                                    }
                                    localModel.trains
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
                    (Local.model newModel.localModel |> .users)
                    (GridCell.getToggledRailSplit newCell)
                    flattened
            , background =
                case backgroundMesh of
                    Just background ->
                        background

                    Nothing ->
                        Grid.backgroundMesh coord
            }

        newShowEmptyTiles =
            newModel.currentTool == ReportTool
    in
    { newModel
        | meshes =
            Dict.map
                (\coord newCell ->
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
            , page = newModel.page
            , mouseMiddle = newModel.mouseMiddle
            , viewPoint = newModel.viewPoint
            , time = newModel.time
            }
    }


updateMeshes : FrontendLoaded -> FrontendLoaded
updateMeshes newModel =
    let
        oldModel =
            newModel.previousUpdateMeshData

        oldCells : Dict ( Int, Int ) (GridCell.Cell FrontendHistory)
        oldCells =
            Local.model oldModel.localModel |> .grid |> Grid.allCellsDict

        localModel : LocalGrid
        localModel =
            Local.model newModel.localModel

        newCells : Dict ( Int, Int ) (GridCell.Cell FrontendHistory)
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

        hyperlinksVisited : Set String
        hyperlinksVisited =
            case localModel.userStatus of
                LoggedIn loggedIn ->
                    loggedIn.hyperlinksVisited

                NotLoggedIn _ ->
                    Set.empty

        newMesh :
            Maybe (Effect.WebGL.Mesh Vertex)
            -> GridCell.Cell FrontendHistory
            -> ( Int, Int )
            -> { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
        newMesh backgroundMesh newCell rawCoord =
            let
                coord : Coord CellUnit
                coord =
                    Coord.tuple rawCoord

                flattened : List GridCell.Value
                flattened =
                    GridCell.flatten newCell
            in
            { foreground =
                Grid.foregroundMesh2
                    (List.filterMap
                        (\value ->
                            case value.tile of
                                HyperlinkTile hyperlink ->
                                    let
                                        linkPos =
                                            expandHyperlink value.position flattened
                                    in
                                    Just
                                        { linkTopLeft = Grid.cellAndLocalCoordToWorld ( coord, linkPos )
                                        , linkWidth = Coord.x value.position - Coord.x linkPos
                                        , isVisited = Set.member (Hyperlink.toString hyperlink) hyperlinksVisited
                                        }

                                _ ->
                                    Nothing
                        )
                        flattened
                    )
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
                                    , time = newModel.time
                                    }
                                    localModel.trains
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
                    (Local.model newModel.localModel |> .users)
                    (GridCell.getToggledRailSplit newCell)
                    flattened
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
            , page = newModel.page
            , mouseMiddle = newModel.mouseMiddle
            , viewPoint = newModel.viewPoint
            , time = newModel.time
            }
    }


mouseWorldPosition :
    { a
        | mouseLeft : MouseButtonState
        , windowSize : ( Quantity Int Pixels, Quantity Int Pixels )
        , devicePixelRatio : Float
        , zoomFactor : Int
        , page : Page
        , mouseMiddle : MouseButtonState
        , viewPoint : ViewPoint
        , localModel : Local Change LocalGrid
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
            , page : Page
            , mouseMiddle : MouseButtonState
            , viewPoint : ViewPoint
            , localModel : Local Change LocalGrid
            , time : Time.Posix
            , currentTool : Tool
        }
    -> Coord WorldUnit
cursorPosition tileData model =
    mouseWorldPosition model
        |> Coord.floorPoint
        |> Coord.minus (tileData.size |> Coord.divide (Coord.tuple ( 2, 2 )))


getHandColor : Id UserId -> { a | localModel : Local b LocalGrid } -> Colors
getHandColor userId model =
    let
        localGrid : LocalGrid
        localGrid =
            Local.model model.localModel
    in
    case SeqDict.get userId localGrid.users of
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

        tool : Tool
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


getReports : Local a LocalGrid -> List Report
getReports localModel =
    case Local.model localModel |> .userStatus of
        LoggedIn loggedIn ->
            loggedIn.reports

        NotLoggedIn _ ->
            []


getAdminReports : Local a LocalGrid -> SeqDict (Id UserId) (Nonempty BackendReport)
getAdminReports localModel =
    case Local.model localModel |> .userStatus of
        LoggedIn loggedIn ->
            case loggedIn.adminData of
                Just adminData ->
                    adminData.reported

                Nothing ->
                    SeqDict.empty

        NotLoggedIn _ ->
            SeqDict.empty


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


viewBoundsUpdate : ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ ) -> ( FrontendLoaded, Command FrontendOnly ToBackend FrontendMsg_ )
viewBoundsUpdate ( model, cmd ) =
    let
        bounds : Bounds CellUnit
        bounds =
            loadingCellBounds model

        localModel : LocalGrid
        localModel =
            Local.model model.localModel

        newBoundsContained : Bool
        newBoundsContained =
            Bounds.containsBounds bounds localModel.viewBounds

        mousePosition : Point2d Pixels Pixels
        mousePosition =
            case model.mouseLeft of
                MouseButtonDown { current } ->
                    current

                MouseButtonUp { current } ->
                    current

        getPreviewBounds : Coord WorldUnit -> Bounds CellUnit
        getPreviewBounds viewPosition =
            Nonempty
                (viewPosition
                    |> Coord.minus LocalGrid.notificationViewportHalfSize
                    |> Grid.worldToCellAndLocalCoord
                    |> Tuple.first
                )
                [ viewPosition
                    |> Coord.plus LocalGrid.notificationViewportHalfSize
                    |> Grid.worldToCellAndLocalCoord
                    |> Tuple.first
                ]
                |> Bounds.fromCoords

        newPreview : Maybe (Bounds CellUnit)
        newPreview =
            case ( showWorldPreview (hoverAt model mousePosition), localModel.previewBounds ) of
                ( Just ( position, _ ), Just oldPreviewBounds ) ->
                    let
                        previewBounds =
                            getPreviewBounds position
                    in
                    if
                        Bounds.containsBounds previewBounds oldPreviewBounds
                            || Bounds.containsBounds previewBounds localModel.viewBounds
                    then
                        Nothing

                    else
                        Just previewBounds

                ( Nothing, _ ) ->
                    Nothing

                ( Just ( position, _ ), Nothing ) ->
                    let
                        previewBounds =
                            getPreviewBounds position
                    in
                    if Bounds.containsBounds previewBounds localModel.viewBounds then
                        Nothing

                    else
                        Just previewBounds
    in
    if newBoundsContained && newPreview == Nothing then
        ( model, cmd )

    else
        updateLocalModel
            (Change.ViewBoundsChange
                { viewBounds = bounds
                , previewBounds = newPreview
                , newCells = []
                , newCows = []
                }
            )
            model
            |> handleOutMsg False
            |> Tuple.mapSecond (\cmd2 -> Command.batch [ cmd, cmd2 ])


hoverAt : FrontendLoaded -> Point2d Pixels Pixels -> Hover
hoverAt model mousePosition =
    case Ui.hover (Coord.roundPoint mousePosition) model.ui of
        ( WorldContainer, _ ) :: _ ->
            let
                mouseWorldPosition_ : Point2d WorldUnit WorldUnit
                mouseWorldPosition_ =
                    Toolbar.screenToWorld model mousePosition

                tileHover : Maybe Hover
                tileHover =
                    let
                        localModel : LocalGrid
                        localModel =
                            Local.model model.localModel
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
                            SeqDict.toList localGrid.trains
                                |> List.filterMap
                                    (\( trainId, train ) ->
                                        let
                                            distance =
                                                Train.trainPosition model.time train |> Point2d.distanceFrom mouseWorldPosition_
                                        in
                                        if distance |> Quantity.lessThan (Quantity.unsafe 0.9) then
                                            Just ( { trainId = trainId, train = train }, distance )

                                        else
                                            Nothing
                                    )
                                |> Quantity.minimumBy Tuple.second

                        TextTool _ ->
                            Nothing

                        ReportTool ->
                            Nothing

                localGrid : LocalGrid
                localGrid =
                    Local.model model.localModel

                animalHovers : Maybe ( Id AnimalId, Animal )
                animalHovers =
                    case model.currentTool of
                        HandTool ->
                            SeqDict.toList localGrid.animals
                                |> List.filter
                                    (\( animalId, animal ) ->
                                        case animalActualPosition animalId model of
                                            Just a ->
                                                if a.isHeld then
                                                    False

                                                else
                                                    Animal.inside
                                                        mouseWorldPosition_
                                                        { animal | position = a.position }

                                            Nothing ->
                                                False
                                    )
                                |> Quantity.maximumBy (\( _, animal ) -> Point2d.yCoordinate animal.position)

                        _ ->
                            Nothing

                npcHovers : Maybe ( Id NpcId, Npc )
                npcHovers =
                    case model.currentTool of
                        HandTool ->
                            SeqDict.toList localGrid.npcs
                                |> List.filter
                                    (\( npcId, npc ) ->
                                        case npcActualPosition npcId model of
                                            Just a ->
                                                if a.isHeld then
                                                    False

                                                else
                                                    Npc.inside
                                                        mouseWorldPosition_
                                                        { npc | position = a.position }

                                            Nothing ->
                                                False
                                    )
                                |> Quantity.maximumBy (\( _, npc ) -> Point2d.yCoordinate npc.position)

                        _ ->
                            Nothing
            in
            case trainHovers of
                Just ( train, _ ) ->
                    TrainHover train

                Nothing ->
                    case ( animalHovers, npcHovers ) of
                        ( Just ( animalId, animal ), Nothing ) ->
                            AnimalHover { animalId = animalId, animal = animal }

                        ( Nothing, Just ( npcId, npc ) ) ->
                            NpcHover { npcId = npcId, npc = npc }

                        ( Just ( animalId, animal ), Just ( npcId, npc ) ) ->
                            if Point2d.yCoordinate npc.position |> Quantity.lessThan (Point2d.yCoordinate animal.position) then
                                AnimalHover { animalId = animalId, animal = animal }

                            else
                                NpcHover { npcId = npcId, npc = npc }

                        ( Nothing, Nothing ) ->
                            case tileHover of
                                Just hover ->
                                    hover

                                Nothing ->
                                    MapHover

        list ->
            UiHover list


npcActualPosition : Id NpcId -> FrontendLoaded -> Maybe { position : Point2d WorldUnit WorldUnit, isHeld : Bool }
npcActualPosition npcId model =
    let
        localGrid : LocalGrid
        localGrid =
            Local.model model.localModel

        cursorHoldingNpc : Maybe ( Id UserId, Cursor )
        cursorHoldingNpc =
            SeqDict.toList localGrid.cursors
                |> List.find
                    (\( _, cursor ) ->
                        case cursor.holding of
                            HoldingAnimalOrNpc holding ->
                                NpcId npcId == holding.animalOrNpcId

                            NotHolding ->
                                False
                    )
    in
    case cursorHoldingNpc of
        Just ( userId, cursor ) ->
            { position =
                cursorActualPosition (Just userId == LocalGrid.currentUserId model) userId cursor model
                    |> Point2d.translateBy (Vector2d.unsafe { x = 0, y = 0.2 })
            , isHeld = True
            }
                |> Just

        Nothing ->
            case SeqDict.get npcId localGrid.npcs of
                Just npc ->
                    { position = Npc.actualPositionWithoutCursor model.time npc, isHeld = False } |> Just

                Nothing ->
                    Nothing


animalActualPosition : Id AnimalId -> FrontendLoaded -> Maybe { position : Point2d WorldUnit WorldUnit, isHeld : Bool }
animalActualPosition animalId model =
    let
        localGrid : LocalGrid
        localGrid =
            Local.model model.localModel

        cursorHoldingAnimal : Maybe ( Id UserId, Cursor )
        cursorHoldingAnimal =
            SeqDict.toList localGrid.cursors
                |> List.find
                    (\( _, cursor ) ->
                        case cursor.holding of
                            HoldingAnimalOrNpc holding ->
                                AnimalId animalId == holding.animalOrNpcId

                            NotHolding ->
                                False
                    )
    in
    case cursorHoldingAnimal of
        Just ( userId, cursor ) ->
            { position =
                cursorActualPosition (Just userId == LocalGrid.currentUserId model) userId cursor model
                    |> Point2d.translateBy (Vector2d.unsafe { x = 0, y = 0.2 })
            , isHeld = True
            }
                |> Just

        Nothing ->
            case SeqDict.get animalId localGrid.animals of
                Just animal ->
                    { position = Animal.actualPositionWithoutCursor model.time animal, isHeld = False } |> Just

                Nothing ->
                    Nothing


cursorActualPosition : Bool -> Id UserId -> Cursor -> FrontendLoaded -> Point2d WorldUnit WorldUnit
cursorActualPosition isCurrentUser userId cursor model =
    if isCurrentUser then
        cursor.position

    else
        case ( cursor.currentTool, SeqDict.get userId model.previousCursorPositions ) of
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


shortDelayDuration : Duration
shortDelayDuration =
    Duration.milliseconds 100


showWorldPreview : Hover -> Maybe ( Coord WorldUnit, { relativePositionToUi : Coord Pixels } )
showWorldPreview hoverAt2 =
    case hoverAt2 of
        UiHover (( MapChangeNotification changeAt, { relativePositionToUi } ) :: _) ->
            Just ( changeAt, { relativePositionToUi = relativePositionToUi } )

        _ ->
            Nothing


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
                            SeqDict.insert
                                userId
                                { position = previousPosition2, time = model.time }
                                model.previousCursorPositions

                        Nothing ->
                            SeqDict.remove userId model.previousCursorPositions
              }
            , Command.none
            )

        LocalGrid.HandColorOrNameChanged userId ->
            ( case Local.model model.localModel |> .users |> SeqDict.get userId of
                Just user ->
                    { model
                        | handMeshes =
                            SeqDict.insert
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

        LocalGrid.LoggedOut ->
            ( { model
                | loginError = Nothing
                , loginEmailInput = TextInput.init
                , oneTimePasswordInput = TextInput.init
                , topMenuOpened = Nothing
                , pressedSubmitEmail = NotSubmitted { pressedSubmit = False }
                , inviteSubmitStatus = NotSubmitted { pressedSubmit = False }
              }
            , Command.none
            )

        LocalGrid.VisitedHyperlinkOutMsg hyperlink ->
            ( hardUpdateMeshes model
            , if isFromBackend then
                Command.none

              else
                Ports.openNewTab hyperlink
            )


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


createReportsMesh : List Report -> SeqDict (Id UserId) (Nonempty BackendReport) -> Effect.WebGL.Mesh Vertex
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
        (SeqDict.toList adminReports)
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


devicePixelRatioChanged :
    Float
    -> { a | cssWindowSize : Coord CssPixels, devicePixelRatio : Float, cssCanvasSize : Coord CssPixels, windowSize : Coord Pixels }
    -> ( { a | cssWindowSize : Coord CssPixels, devicePixelRatio : Float, cssCanvasSize : Coord CssPixels, windowSize : Coord Pixels }, Command restriction toMsg msg )
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
        (case ( model.texture, model.lightsTexture, model.depthTexture ) of
            ( Just texture, Just lightsTexture, Just depth ) ->
                let
                    textureSize =
                        Effect.WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
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
                    , lights = lightsTexture
                    , depth = depth
                    , textureSize = textureSize
                    , color = Vec4.vec4 1 1 1 1
                    , userId = Shaders.noUserIdSelected
                    , time = 0
                    , night = 0
                    , waterReflection = 0
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
                                    , lights = lightsTexture
                                    , depth = depth
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    , userId = Shaders.noUserIdSelected
                                    , time = 0
                                    , night = 0
                                    , waterReflection = 0
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
                                    , lights = lightsTexture
                                    , depth = depth
                                    , textureSize = textureSize
                                    , color = Vec4.vec4 1 1 1 1
                                    , userId = Shaders.noUserIdSelected
                                    , time = 0
                                    , night = 0
                                    , waterReflection = 0
                                    }
                                ]
                       )

            _ ->
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
