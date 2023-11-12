module Grid exposing
    ( Grid(..)
    , GridChange
    , GridData(..)
    , IntersectionType(..)
    , LocalGridChange
    , RemovedTile
    , addChangeBackend
    , addChangeFrontend
    , allCellsDict
    , backgroundMesh
    , canPlaceTile
    , cellAndLocalCoordToWorld
    , cellAndLocalPointToWorld
    , closeNeighborCells
    , dataToGrid
    , empty
    , foregroundMesh2
    , from
    , fromData
    , getCell
    , getCell2
    , getPostOffice
    , getTile
    , latestChanges
    , localChangeToChange
    , localTilePointPlusCellLocalCoord
    , localTilePointPlusWorld
    , moveUndoPointBackend
    , moveUndoPointFrontend
    , pointInside
    , rayIntersection
    , rayIntersection2
    , regenerateGridCellCacheBackend
    , regenerateGridCellCacheFrontend
    , setCell
    , tileMesh
    , tileMeshHelper2
    , toggleRailSplit
    , worldToCellAndLocalCoord
    , worldToCellAndLocalPoint
    , worldToCellPoint
    )

import Array2D exposing (Array2D)
import AssocSet
import Basics.Extra
import BoundingBox2d exposing (BoundingBox2d)
import BoundingBox2dExtra as BoundingBox2d
import Bounds exposing (Bounds)
import Bytes.Decode
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import DisplayName
import Duration
import Effect.Time
import GridCell exposing (BackendHistory(..), Cell, CellData, FrontendHistory(..))
import Id exposing (Id, UserId)
import IdDict exposing (IdDict)
import LineSegment2d exposing (LineSegment2d)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Point2dExtra
import Quantity exposing (Quantity(..))
import Set
import Shaders
import Sprite exposing (Vertex)
import Terrain exposing (TerrainType(..), TerrainValue)
import Tile exposing (RailPathType(..), Tile(..), TileData)
import Units exposing (CellLocalUnit, CellUnit, TerrainUnit, TileLocalUnit, WorldUnit)
import User exposing (FrontendUser)
import Vector2d exposing (Vector2d)
import WebGL


type GridData
    = GridData (Dict ( Int, Int ) CellData)


dataToGrid : GridData -> Grid FrontendHistory
dataToGrid (GridData gridData) =
    Dict.map (\_ cell -> GridCell.dataToCell cell) gridData |> Grid


type Grid a
    = Grid (Dict ( Int, Int ) (Cell a))


empty : Grid a
empty =
    Grid Dict.empty


from : Dict ( Int, Int ) (Cell a) -> Grid a
from =
    Grid


fromData : Dict ( Int, Int ) CellData -> GridData
fromData =
    GridData


localTilePointPlusWorld : Coord WorldUnit -> Point2d TileLocalUnit TileLocalUnit -> Point2d WorldUnit WorldUnit
localTilePointPlusWorld world local =
    Point2d.translateBy (Point2d.unwrap local |> Vector2d.unsafe) (Coord.toPoint2d world)


localTilePointPlusCellLocalCoord :
    Coord CellLocalUnit
    -> Point2d TileLocalUnit TileLocalUnit
    -> Point2d CellLocalUnit CellLocalUnit
localTilePointPlusCellLocalCoord cellLocal local =
    Point2d.translateBy (Point2d.unwrap local |> Vector2d.unsafe) (Coord.toPoint2d cellLocal)


worldToCellAndLocalCoord : Coord WorldUnit -> ( Coord CellUnit, Coord CellLocalUnit )
worldToCellAndLocalCoord ( Quantity x, Quantity y ) =
    let
        offset =
            1000000
    in
    ( Coord.tuple
        ( (x + (Units.cellSize * offset)) // Units.cellSize - offset
        , (y + (Units.cellSize * offset)) // Units.cellSize - offset
        )
    , Coord.tuple
        ( modBy Units.cellSize x
        , modBy Units.cellSize y
        )
    )


worldToCellPoint : Point2d WorldUnit WorldUnit -> Point2d CellUnit CellUnit
worldToCellPoint point =
    Point2d.scaleAbout Point2d.origin (1 / Units.cellSize) point |> Point2d.unwrap |> Point2d.unsafe


worldToCellAndLocalPoint : Point2d WorldUnit WorldUnit -> ( Coord CellUnit, Point2d CellLocalUnit CellLocalUnit )
worldToCellAndLocalPoint point =
    let
        offset =
            1000000

        { x, y } =
            Point2d.unwrap point
    in
    ( Coord.tuple
        ( (floor x + (Units.cellSize * offset)) // Units.cellSize - offset
        , (floor y + (Units.cellSize * offset)) // Units.cellSize - offset
        )
    , { x = Basics.Extra.fractionalModBy Units.cellSize x
      , y = Basics.Extra.fractionalModBy Units.cellSize y
      }
        |> Point2d.unsafe
    )


cellAndLocalCoordToWorld : ( Coord CellUnit, Coord CellLocalUnit ) -> Coord WorldUnit
cellAndLocalCoordToWorld ( cell, local ) =
    Coord.plus
        (Coord.multiplyTuple ( Units.cellSize, Units.cellSize ) cell)
        (Coord.toTuple local |> Coord.tuple)
        |> Coord.toTuple
        |> Coord.tuple


cellAndLocalPointToWorld : Coord CellUnit -> Point2d CellLocalUnit CellLocalUnit -> Point2d WorldUnit WorldUnit
cellAndLocalPointToWorld cell local =
    Coord.multiplyTuple ( Units.cellSize, Units.cellSize ) cell
        |> Coord.toPoint2d
        |> Point2d.translateBy (Vector2d.from Point2d.origin local |> Vector2d.unwrap |> Vector2d.unsafe)
        |> Point2d.unwrap
        |> Point2d.unsafe


type alias GridChange =
    { position : Coord WorldUnit, change : Tile, userId : Id UserId, colors : Colors, time : Effect.Time.Posix }


type alias LocalGridChange =
    { position : Coord WorldUnit, change : Tile, colors : Colors, time : Effect.Time.Posix }


localChangeToChange : Id UserId -> LocalGridChange -> GridChange
localChangeToChange userId change_ =
    { position = change_.position
    , change = change_.change
    , userId = userId
    , colors = change_.colors
    , time = change_.time
    }


latestChanges : Effect.Time.Posix -> Id UserId -> Grid BackendHistory -> List (Coord WorldUnit)
latestChanges time currentUser (Grid grid) =
    Dict.toList grid
        |> List.filterMap
            (\( coord, cell ) ->
                case GridCell.latestChange currentUser cell of
                    Just latestChange ->
                        if Duration.from time latestChange.time |> Quantity.greaterThanZero then
                            cellAndLocalCoordToWorld ( Coord.tuple coord, latestChange.position )
                                |> Coord.plus (Coord.divide (Coord.xy 2 2) (Tile.getData latestChange.tile).size)
                                |> Just

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )


moveUndoPointFrontend : Id UserId -> Dict RawCellCoord Int -> Grid FrontendHistory -> Grid FrontendHistory
moveUndoPointFrontend userId undoPoint grid =
    moveUndoPoint
        (\a ->
            case a of
                FrontendEncoded bytes ->
                    Bytes.Decode.decode GridCell.historyDecoder bytes |> Maybe.withDefault []

                FrontendDecoded list ->
                    list
        )
        (\history _ -> FrontendDecoded history)
        userId
        undoPoint
        grid


moveUndoPointBackend : Id UserId -> Dict RawCellCoord Int -> Grid BackendHistory -> Grid BackendHistory
moveUndoPointBackend userId undoPoint grid =
    moveUndoPoint
        (\a ->
            case a of
                BackendDecoded list ->
                    list

                BackendEncodedAndDecoded _ list ->
                    list
        )
        (\_ a -> a)
        userId
        undoPoint
        grid


moveUndoPoint :
    (a -> List GridCell.Value)
    -> (List GridCell.Value -> a -> a)
    -> Id UserId
    -> Dict RawCellCoord Int
    -> Grid a
    -> Grid a
moveUndoPoint getHistory setHistory userId undoPoint (Grid grid) =
    Dict.foldl
        (\coord moveAmount newGrid ->
            Dict.update coord (Maybe.map (GridCell.moveUndoPoint getHistory setHistory userId moveAmount (Coord.tuple coord))) newGrid
        )
        grid
        undoPoint
        |> Grid


closeNeighborCells : Coord CellUnit -> Coord CellLocalUnit -> List ( Coord CellUnit, Coord CellLocalUnit )
closeNeighborCells cellPosition localPosition =
    List.filterMap
        (\offset ->
            let
                ( Quantity x, Quantity y ) =
                    Coord.tuple offset
                        |> Coord.multiplyTuple ( maxTileSize, maxTileSize )
                        |> Coord.plus localPosition

                ( Quantity localX, Quantity localY ) =
                    localPosition

                ( a, b ) =
                    ( if x < 0 then
                        -1

                      else if x < Units.cellSize then
                        0

                      else
                        1
                    , if y < 0 then
                        -1

                      else if y < Units.cellSize then
                        0

                      else
                        1
                    )

                newCellPos : Coord CellUnit
                newCellPos =
                    Coord.tuple offset |> Coord.plus cellPosition
            in
            if ( a, b ) == offset then
                ( newCellPos
                , Coord.tuple
                    ( localX - Units.cellSize * a
                    , localY - Units.cellSize * b
                    )
                )
                    |> Just

            else
                Nothing
        )
        [ ( 1, 1 )
        , ( 0, 1 )
        , ( -1, 1 )
        , ( 1, -1 )
        , ( 0, -1 )
        , ( -1, -1 )
        , ( 1, 0 )
        , ( -1, 0 )
        ]


canPlaceTile : { a | position : Coord WorldUnit, change : Tile } -> Bool
canPlaceTile change =
    let
        ( cellPosition, ( Quantity x, Quantity y ) ) =
            worldToCellAndLocalCoord change.position

        tileData : TileData unit
        tileData =
            Tile.getData change.change

        ( Quantity tileW, Quantity tileH ) =
            tileData.size
    in
    List.range 0 (1 + tileW // Terrain.terrainSize)
        |> List.any
            (\x2 ->
                List.range 0 (1 + tileH // Terrain.terrainSize)
                    |> List.any
                        (\y2 ->
                            let
                                x3 =
                                    x2 + (x // Terrain.terrainSize)

                                y3 =
                                    y2 + (y // Terrain.terrainSize)

                                terrain =
                                    Terrain.getTerrainValue (Coord.xy x3 y3) cellPosition
                            in
                            if terrain.terrainType == Ground then
                                False

                            else
                                let
                                    terrainPosition : Coord WorldUnit
                                    terrainPosition =
                                        cellAndLocalCoordToWorld
                                            ( cellPosition
                                            , Coord.tuple ( x3 * Terrain.terrainSize, y3 * Terrain.terrainSize )
                                            )

                                    ( Quantity x8, Quantity y8 ) =
                                        change.position

                                    ( Quantity x9, Quantity y9 ) =
                                        terrainPosition

                                    tileDataA =
                                        Tile.getData change.change

                                    ( Quantity width, Quantity height ) =
                                        tileDataA.size
                                in
                                case tileDataA.tileCollision of
                                    Tile.DefaultCollision ->
                                        ((x9 >= x8 && x9 < x8 + width) || (x8 >= x9 && x8 < x9 + Terrain.terrainSize))
                                            && ((y9 >= y8 && y9 < y8 + height) || (y8 >= y9 && y8 < y9 + Terrain.terrainSize))

                                    Tile.CustomCollision setA ->
                                        Set.toList setA
                                            |> List.any
                                                (\( cx, cy ) ->
                                                    x9 <= x8 + cx && x9 + Terrain.terrainSize > x8 + cx && y9 <= y8 + cy && y9 + Terrain.terrainSize > y8 + cy
                                                )
                        )
            )
        |> not


type alias RemovedTile =
    { tile : Tile
    , position : Coord WorldUnit
    , userId : Id UserId
    , colors : Colors
    }


addChangeFrontend :
    GridChange
    -> Grid FrontendHistory
    -> { grid : Grid FrontendHistory, removed : List RemovedTile, newCells : List (Coord CellUnit) }
addChangeFrontend change grid =
    addChange
        (FrontendDecoded [])
        (\a ->
            case a of
                FrontendEncoded bytes ->
                    let
                        _ =
                            Debug.log "decode2" ""
                    in
                    Bytes.Decode.decode GridCell.historyDecoder bytes |> Maybe.withDefault []

                FrontendDecoded list ->
                    list
        )
        FrontendDecoded
        change
        grid


addChangeBackend :
    GridChange
    -> Grid BackendHistory
    -> { grid : Grid BackendHistory, removed : List RemovedTile, newCells : List (Coord CellUnit) }
addChangeBackend change grid =
    addChange
        (BackendDecoded [])
        (\a ->
            case a of
                BackendDecoded list ->
                    list

                BackendEncodedAndDecoded _ list ->
                    list
        )
        BackendDecoded
        change
        grid


addChange :
    a
    -> (a -> List GridCell.Value)
    -> (List GridCell.Value -> a)
    -> GridChange
    -> Grid a
    ->
        { grid : Grid a
        , removed : List RemovedTile
        , newCells : List (Coord CellUnit)
        }
addChange emptyHistory getHistory setHistory change grid =
    let
        ( cellPosition, localPosition ) =
            worldToCellAndLocalCoord change.position

        value : GridCell.Value
        value =
            { userId = change.userId
            , position = localPosition
            , tile = change.change
            , colors = change.colors
            , time = change.time
            }

        neighborCells_ :
            List
                { neighborPos : Coord CellUnit
                , neighbor : { cell : Cell a, removed : List GridCell.Value }
                , isNewCell : Bool
                }
        neighborCells_ =
            closeNeighborCells cellPosition localPosition
                |> List.map
                    (\( newCellPos, newLocalPos ) ->
                        let
                            oldCell =
                                getCell newCellPos grid
                        in
                        { neighborPos = newCellPos
                        , neighbor =
                            (case oldCell of
                                Just cell2 ->
                                    cell2

                                Nothing ->
                                    GridCell.empty emptyHistory newCellPos
                            )
                                |> GridCell.addValue getHistory setHistory { value | position = newLocalPos }
                        , isNewCell = oldCell == Nothing
                        }
                    )

        ( cell, newCells ) =
            case getCell cellPosition grid of
                Just cell2 ->
                    ( cell2, [] )

                Nothing ->
                    ( GridCell.empty emptyHistory cellPosition, [ cellPosition ] )
    in
    GridCell.addValue getHistory setHistory value cell
        |> (\cell_ ->
                { grid =
                    List.foldl
                        (\{ neighborPos, neighbor } grid2 ->
                            setCell neighborPos neighbor.cell grid2
                        )
                        (setCell cellPosition cell_.cell grid)
                        neighborCells_
                , removed =
                    { neighborPos = cellPosition, neighbor = cell_, isNewCell = False }
                        :: neighborCells_
                        |> List.concatMap
                            (\{ neighborPos, neighbor } ->
                                List.map
                                    (\removed ->
                                        { tile = removed.tile
                                        , position = cellAndLocalCoordToWorld ( neighborPos, removed.position )
                                        , userId = removed.userId
                                        , colors = removed.colors
                                        }
                                    )
                                    neighbor.removed
                            )
                , newCells =
                    newCells
                        ++ List.filterMap
                            (\{ neighborPos, isNewCell } ->
                                if isNewCell then
                                    Just neighborPos

                                else
                                    Nothing
                            )
                            neighborCells_
                }
           )


getCell2 :
    Coord CellUnit
    -> Grid BackendHistory
    -> { cell : Cell BackendHistory, isNew : Bool, grid : Grid BackendHistory }
getCell2 coord (Grid grid) =
    case Dict.get (Coord.toTuple coord) grid of
        Just cell ->
            { cell = cell, isNew = False, grid = Grid grid }

        Nothing ->
            let
                newCell =
                    GridCell.empty (BackendDecoded []) coord
            in
            { cell = newCell, isNew = True, grid = Dict.insert (Coord.toTuple coord) newCell grid |> Grid }


maxTileSize : number
maxTileSize =
    6


allCellsDict : Grid a -> Dict ( Int, Int ) (Cell a)
allCellsDict (Grid grid) =
    grid


getCell : Coord CellUnit -> Grid a -> Maybe (Cell a)
getCell ( Quantity x, Quantity y ) (Grid grid) =
    Dict.get ( x, y ) grid


setCell : Coord CellUnit -> Cell a -> Grid a -> Grid a
setCell ( Quantity x, Quantity y ) value (Grid grid) =
    Dict.insert ( x, y ) value grid |> Grid


foregroundMesh2 :
    List { linkTopLeft : Coord WorldUnit, linkWidth : Int }
    -> Bool
    -> Maybe { a | tile : Tile, position : Coord WorldUnit }
    -> Coord CellUnit
    -> Maybe (Id UserId)
    -> IdDict UserId FrontendUser
    -> AssocSet.Set (Coord CellLocalUnit)
    -> List GridCell.Value
    -> WebGL.Mesh Vertex
foregroundMesh2 hyperlinks showEmptyTiles maybeCurrentTile cellPosition maybeCurrentUserId users railSplitToggled tiles =
    List.concatMap
        (\{ position, userId, tile, colors } ->
            if showEmptyTiles || tile /= EmptyTile then
                let
                    position2 : Coord WorldUnit
                    position2 =
                        cellAndLocalCoordToWorld ( cellPosition, position )

                    data : TileData unit
                    data =
                        Tile.getData tile

                    ( texturePosition, colors2 ) =
                        case tile of
                            BigText _ ->
                                if
                                    List.any
                                        (\{ linkTopLeft, linkWidth } ->
                                            (Coord.yRaw position2 - Coord.yRaw linkTopLeft == 0)
                                                && (Coord.xRaw position2 >= Coord.xRaw linkTopLeft)
                                                && (Coord.xRaw position2 <= Coord.xRaw linkTopLeft + linkWidth)
                                        )
                                        hyperlinks
                                then
                                    ( Coord.plus (Coord.xy 0 180) data.texturePosition
                                    , { primaryColor = Color.linkColor
                                      , secondaryColor = Color.linkColor
                                      }
                                    )

                                else
                                    ( data.texturePosition, colors )

                            _ ->
                                ( data.texturePosition, colors )

                    opacity : Float
                    opacity =
                        case maybeCurrentTile of
                            Just currentTile ->
                                if Tile.hasCollision currentTile.position currentTile.tile position2 tile then
                                    0.5

                                else
                                    1

                            Nothing ->
                                1

                    opacityAndUserId : Float
                    opacityAndUserId =
                        Shaders.opacityAndUserId opacity userId
                in
                case data.railPath of
                    RailSplitPath pathData ->
                        if AssocSet.member position railSplitToggled then
                            tileMeshHelper2
                                opacityAndUserId
                                colors2
                                (Coord.multiply Units.tileSize position2)
                                1
                                pathData.texturePosition
                                data.size

                        else
                            tileMeshHelper2
                                opacityAndUserId
                                colors2
                                (Coord.multiply Units.tileSize position2)
                                1
                                data.texturePosition
                                data.size

                    _ ->
                        if tile == PostOffice && Just userId /= maybeCurrentUserId then
                            let
                                text =
                                    Sprite.textWithZAndOpacityAndUserId
                                        opacityAndUserId
                                        colors2.secondaryColor
                                        1
                                        (case IdDict.get userId users of
                                            Just user ->
                                                let
                                                    name =
                                                        DisplayName.toString user.name
                                                in
                                                String.left 5 name ++ "\n" ++ String.dropLeft 5 name

                                            Nothing ->
                                                ""
                                        )
                                        -5
                                        (Coord.multiply position2 Units.tileSize
                                            |> Coord.plus (Coord.xy 15 19)
                                        )
                                        -0.55
                            in
                            text
                                ++ tileMeshHelper2
                                    opacityAndUserId
                                    colors2
                                    (Coord.multiply Units.tileSize position2)
                                    1
                                    (Coord.xy 4 35 |> Coord.multiply Units.tileSize)
                                    data.size

                        else
                            tileMeshHelper2
                                opacityAndUserId
                                colors2
                                (Coord.multiply Units.tileSize position2)
                                (case tile of
                                    BigText _ ->
                                        2

                                    _ ->
                                        1
                                )
                                texturePosition
                                data.size
                --++ List.concatMap
                --    (\boundingBox ->
                --        Sprite.spriteWithZ
                --            0.25
                --            Color.white
                --            Color.white
                --            (Coord.multiply Units.tileSize position2
                --                |> Coord.plus (Bounds.minimum boundingBox |> Coord.changeUnit)
                --            )
                --            -0.9
                --            (Bounds.size boundingBox |> Coord.changeUnit)
                --            (Coord.xy 508 28)
                --            (Coord.xy 1 1)
                --    )
                --    data.movementCollision

            else
                []
        )
        tiles
        |> Sprite.toMesh


getTerrainLookupValue : Coord TerrainUnit -> Array2D TerrainValue -> TerrainType
getTerrainLookupValue ( Quantity x, Quantity y ) lookup =
    case Array2D.get (x + 1) (y + 1) lookup of
        Just terrain ->
            terrain.terrainType

        Nothing ->
            Ground


backgroundMesh : Coord CellUnit -> WebGL.Mesh Vertex
backgroundMesh cellPosition =
    let
        lookup : Array2D TerrainValue
        lookup =
            Terrain.createTerrainLookup cellPosition

        ( Quantity x, Quantity y ) =
            cellAndLocalCoordToWorld ( cellPosition, Coord.origin )
    in
    List.range 0 (Terrain.terrainDivisionsPerCell - 1)
        |> List.concatMap
            (\x2 ->
                List.range 0 (Terrain.terrainDivisionsPerCell - 1)
                    |> List.concatMap
                        (\y2 ->
                            let
                                getValue : Int -> Int -> TerrainType
                                getValue x3 y3 =
                                    getTerrainLookupValue (Coord.xy (x2 + x3) (y2 + y3)) lookup

                                draw : Int -> Int -> List Vertex
                                draw textureX textureY =
                                    Sprite.sprite
                                        (Coord.xy
                                            ((x2 * Terrain.terrainDivisionsPerCell + x) * Units.tileWidth)
                                            ((y2 * Terrain.terrainDivisionsPerCell + y) * Units.tileHeight)
                                        )
                                        (Coord.xy 80 72)
                                        (Coord.xy textureX textureY)
                                        (Coord.xy 80 72)

                                corners =
                                    [ { side1 = getValue 0 -1 /= Water
                                      , corner = getValue -1 -1 /= Water
                                      , side2 = getValue -1 0 /= Water
                                      , texturePos = ( 480, 504 )
                                      }
                                    , { side1 = getValue 0 -1 /= Water
                                      , corner = getValue 1 -1 /= Water
                                      , side2 = getValue 1 0 /= Water
                                      , texturePos = ( 400, 504 )
                                      }
                                    , { side1 = getValue 0 1 /= Water
                                      , corner = getValue 1 1 /= Water
                                      , side2 = getValue 1 0 /= Water
                                      , texturePos = ( 400, 432 )
                                      }
                                    , { side1 = getValue 0 1 /= Water
                                      , corner = getValue -1 1 /= Water
                                      , side2 = getValue -1 0 /= Water
                                      , texturePos = ( 480, 432 )
                                      }
                                    ]
                                        |> List.concatMap
                                            (\{ side1, corner, side2, texturePos } ->
                                                if side1 == False && corner == True && side2 == False then
                                                    draw (Tuple.first texturePos) (Tuple.second texturePos)

                                                else
                                                    []
                                            )

                                originValue =
                                    getValue 0 0

                                tile =
                                    case originValue of
                                        Mountain ->
                                            draw 680 72

                                        Ground ->
                                            draw 220 216

                                        Water ->
                                            case
                                                ( {- Top -} getValue 0 -1 /= Water
                                                , ( getValue -1 0 /= Water, getValue 1 0 /= Water ) {- Left, Right -}
                                                , {- Bottom -} getValue 0 1 /= Water
                                                )
                                            of
                                                ( False, ( False, False ), False ) ->
                                                    draw 480 288

                                                ( True, ( False, False ), False ) ->
                                                    draw 480 216

                                                ( False, ( True, False ), False ) ->
                                                    draw 400 288

                                                ( True, ( True, False ), False ) ->
                                                    draw 400 216

                                                ( False, ( False, True ), False ) ->
                                                    draw 560 288

                                                ( True, ( False, True ), False ) ->
                                                    draw 560 216

                                                ( False, ( True, True ), False ) ->
                                                    draw 560 504

                                                ( True, ( True, True ), False ) ->
                                                    draw 560 432

                                                ( False, ( False, False ), True ) ->
                                                    draw 480 360

                                                ( True, ( False, False ), True ) ->
                                                    draw 480 648

                                                ( False, ( True, False ), True ) ->
                                                    draw 400 360

                                                ( True, ( True, False ), True ) ->
                                                    draw 400 648

                                                ( False, ( False, True ), True ) ->
                                                    draw 560 360

                                                ( True, ( False, True ), True ) ->
                                                    draw 560 648

                                                ( False, ( True, True ), True ) ->
                                                    draw 560 576

                                                ( True, ( True, True ), True ) ->
                                                    draw 480 288
                            in
                            corners ++ tile
                        )
            )
        |> Sprite.toMesh


tileMesh : Tile -> Coord Pixels -> Int -> Colors -> List Vertex
tileMesh tile position scale colors =
    let
        data : TileData unit
        data =
            Tile.getData tile
    in
    if tile == EmptyTile then
        Sprite.sprite (Coord.plus (Coord.xy 6 -16) position) (Coord.xy 28 27) (Coord.xy 504 42) (Coord.xy 28 27)

    else
        tileMeshHelper2
            Sprite.opaque
            colors
            position
            (case tile of
                BigText _ ->
                    2 * scale

                _ ->
                    scale
            )
            data.texturePosition
            data.size


tileMeshHelper2 :
    Float
    -> Colors
    -> Coord unit2
    -> Int
    -> Coord unit
    -> Coord unit
    -> List Vertex
tileMeshHelper2 opacityAndUserId { primaryColor, secondaryColor } position scale texturePosition size =
    Sprite.spriteWithZAndOpacityAndUserId
        opacityAndUserId
        primaryColor
        secondaryColor
        position
        0
        (Coord.multiply Units.tileSize size |> Coord.toTuple |> Coord.tuple)
        texturePosition
        (Coord.multiply Units.tileSize size |> Coord.divide (Coord.xy scale scale))


regenerateGridCellCacheBackend : Grid BackendHistory -> Grid BackendHistory
regenerateGridCellCacheBackend (Grid grid) =
    Dict.map
        (\cellPos cell ->
            GridCell.updateCache
                (\a ->
                    case a of
                        BackendDecoded list ->
                            list

                        BackendEncodedAndDecoded _ list ->
                            list
                )
                (\history _ -> BackendDecoded history)
                (Coord.tuple cellPos)
                cell
        )
        grid
        |> Grid


regenerateGridCellCacheFrontend : Grid FrontendHistory -> Grid FrontendHistory
regenerateGridCellCacheFrontend (Grid grid) =
    Dict.map
        (\cellPos cell ->
            GridCell.updateCache
                (\a ->
                    case a of
                        FrontendEncoded bytes ->
                            Bytes.Decode.decode GridCell.historyDecoder bytes |> Maybe.withDefault []

                        FrontendDecoded list ->
                            list
                )
                (\history _ -> FrontendDecoded history)
                (Coord.tuple cellPos)
                cell
        )
        grid
        |> Grid


getTile :
    Coord WorldUnit
    -> Grid a
    ->
        Maybe
            { userId : Id UserId
            , tile : Tile
            , position : Coord WorldUnit
            , colors : Colors
            , time : Effect.Time.Posix
            }
getTile coord grid =
    let
        ( cellPos, localPos ) =
            worldToCellAndLocalCoord coord
    in
    (( cellPos, localPos ) :: closeNeighborCells cellPos localPos)
        |> List.filterMap
            (\( cellPos2, localPos2 ) ->
                case getCell cellPos2 grid of
                    Just cell ->
                        GridCell.flatten cell
                            |> List.find
                                (\{ tile, position } ->
                                    Tile.hasCollisionWithCoord localPos2 position (Tile.getData tile)
                                )
                            |> Maybe.map
                                (\tile ->
                                    { userId = tile.userId
                                    , tile = tile.tile
                                    , position = cellAndLocalCoordToWorld ( cellPos2, tile.position )
                                    , colors = tile.colors
                                    , time = tile.time
                                    }
                                )

                    Nothing ->
                        Nothing
            )
        |> List.head


toggleRailSplit : Coord WorldUnit -> Grid a -> Grid a
toggleRailSplit coord grid =
    let
        ( cellPos, localPos ) =
            worldToCellAndLocalCoord coord
    in
    case getCell cellPos grid of
        Just cell ->
            setCell cellPos (GridCell.toggleRailSplit localPos cell) grid

        Nothing ->
            grid


getPostOffice : Id UserId -> Grid BackendHistory -> Maybe (Coord WorldUnit)
getPostOffice userId (Grid grid) =
    Dict.toList grid
        |> List.findMap
            (\( position, cell ) ->
                GridCell.getPostOffices cell
                    |> List.findMap
                        (\postOffice ->
                            if postOffice.userId == userId then
                                Just (cellAndLocalCoordToWorld ( Coord.tuple position, postOffice.position ))

                            else
                                Nothing
                        )
            )


type IntersectionType
    = TileIntersection
    | UnloadedCellIntersection
    | WaterIntersection


rayIntersection :
    Bool
    -> Vector2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Grid a
    -> Maybe { intersection : Point2d WorldUnit WorldUnit, intersectionType : IntersectionType }
rayIntersection includeWater expandBoundsBy start end grid =
    let
        line : LineSegment2d WorldUnit WorldUnit
        line =
            LineSegment2d.from start end

        minReach : Vector2d WorldUnit WorldUnit
        minReach =
            Vector2d.xy
                (BoundingBox2d.minX Tile.aggregateMovementCollision)
                (BoundingBox2d.minY Tile.aggregateMovementCollision)

        maxReach : Vector2d WorldUnit WorldUnit
        maxReach =
            Vector2d.xy
                (BoundingBox2d.maxX Tile.aggregateMovementCollision)
                (BoundingBox2d.maxY Tile.aggregateMovementCollision)
                |> Vector2d.reverse

        cellBounds : Bounds CellUnit
        cellBounds =
            Bounds.fromCoords
                (Nonempty
                    (Point2d.translateBy expandBoundsBy start
                        |> Point2d.translateBy minReach
                        |> worldToCellPoint
                        |> Coord.floorPoint
                    )
                    [ Point2d.translateBy (Vector2d.reverse expandBoundsBy) start
                        |> Point2d.translateBy maxReach
                        |> worldToCellPoint
                        |> Coord.floorPoint
                    , Point2d.translateBy expandBoundsBy end
                        |> Point2d.translateBy minReach
                        |> worldToCellPoint
                        |> Coord.floorPoint
                    , Point2d.translateBy (Vector2d.reverse expandBoundsBy) end
                        |> Point2d.translateBy maxReach
                        |> worldToCellPoint
                        |> Coord.floorPoint
                    ]
                )
    in
    List.filterMap
        (\{ bounds, intersectionType } ->
            case BoundingBox2d.lineIntersection line bounds |> Quantity.minimumBy (Point2d.distanceFrom start) of
                Just intersection ->
                    Just { intersectionType = intersectionType, intersection = intersection }

                Nothing ->
                    Nothing
        )
        (getBounds includeWater cellBounds expandBoundsBy grid)
        |> Quantity.minimumBy (\a -> Point2d.distanceFrom start a.intersection)


pointInside :
    Bool
    -> Vector2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Grid a
    -> List { bounds : BoundingBox2d WorldUnit WorldUnit, intersectionType : IntersectionType }
pointInside includeWater expandBoundsBy start grid =
    let
        minReach : Vector2d WorldUnit WorldUnit
        minReach =
            Vector2d.xy
                (BoundingBox2d.minX Tile.aggregateMovementCollision)
                (BoundingBox2d.minY Tile.aggregateMovementCollision)

        maxReach : Vector2d WorldUnit WorldUnit
        maxReach =
            Vector2d.xy
                (BoundingBox2d.maxX Tile.aggregateMovementCollision)
                (BoundingBox2d.maxY Tile.aggregateMovementCollision)
                |> Vector2d.reverse

        pointMin : Point2d WorldUnit WorldUnit
        pointMin =
            Point2d.translateBy maxReach start

        pointMax : Point2d WorldUnit WorldUnit
        pointMax =
            Point2d.translateBy minReach start
    in
    List.filterMap
        (\{ bounds, intersectionType } ->
            if BoundingBox2d.contains start bounds then
                Just { intersectionType = intersectionType, bounds = bounds }

            else
                Nothing
        )
        (getBounds2 includeWater pointMin pointMax expandBoundsBy grid)


getBounds :
    Bool
    -> Bounds CellUnit
    -> Vector2d WorldUnit WorldUnit
    -> Grid a
    -> List { bounds : BoundingBox2d WorldUnit WorldUnit, intersectionType : IntersectionType }
getBounds includeWater cellBounds expandBoundsBy grid =
    Bounds.coordRangeFold
        (\coord list ->
            let
                water =
                    if includeWater then
                        List.range 0 (Terrain.terrainDivisionsPerCell - 1)
                            |> List.concatMap
                                (\x2 ->
                                    List.range 0 (Terrain.terrainDivisionsPerCell - 1)
                                        |> List.filterMap
                                            (\y2 ->
                                                let
                                                    terrainUnit : Coord TerrainUnit
                                                    terrainUnit =
                                                        Coord.xy x2 y2

                                                    worldPosMin =
                                                        cellAndLocalCoordToWorld
                                                            ( coord
                                                            , Coord.scalar Terrain.terrainSize terrainUnit
                                                                |> Coord.changeUnit
                                                            )
                                                            |> Coord.toPoint2d

                                                    worldPosMax =
                                                        cellAndLocalCoordToWorld
                                                            ( coord
                                                            , Coord.plus (Coord.xy 1 1) terrainUnit
                                                                |> Coord.scalar Terrain.terrainSize
                                                                |> Coord.changeUnit
                                                            )
                                                            |> Coord.toPoint2d
                                                in
                                                case (Terrain.getTerrainValue terrainUnit coord).terrainType of
                                                    Water ->
                                                        { bounds = BoundingBox2d.from worldPosMin worldPosMax
                                                        , intersectionType = WaterIntersection
                                                        }
                                                            |> Just

                                                    Mountain ->
                                                        { bounds = BoundingBox2d.from worldPosMin worldPosMax
                                                        , intersectionType = WaterIntersection
                                                        }
                                                            |> Just

                                                    Ground ->
                                                        Nothing
                                            )
                                )

                    else
                        []
            in
            case getCell coord grid of
                Just cell ->
                    GridCell.flatten cell
                        |> List.concatMap
                            (\tile ->
                                cellAndLocalCoordToWorld ( coord, tile.position )
                                    |> Tile.worldMovementBounds expandBoundsBy tile.tile
                                    |> List.map (\a -> { bounds = a, intersectionType = TileIntersection })
                            )
                        |> (\a -> a ++ water ++ list)

                Nothing ->
                    { bounds =
                        Bounds.from2Coords
                            (cellAndLocalCoordToWorld ( coord, Coord.xy 0 0 ))
                            (cellAndLocalCoordToWorld ( Coord.plus (Coord.xy 1 1) coord, Coord.xy 0 0 ))
                            |> Bounds.boundsToBounds2d
                    , intersectionType = UnloadedCellIntersection
                    }
                        :: water
                        ++ list
        )
        identity
        cellBounds
        []


rayIntersection2 :
    Bool
    -> Vector2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Grid a
    -> Maybe { intersection : Point2d WorldUnit WorldUnit, intersectionType : IntersectionType }
rayIntersection2 includeWater expandBoundsBy start end grid =
    let
        line : LineSegment2d WorldUnit WorldUnit
        line =
            LineSegment2d.from start end

        minReach : Vector2d WorldUnit WorldUnit
        minReach =
            Vector2d.xy
                (BoundingBox2d.minX Tile.aggregateMovementCollision)
                (BoundingBox2d.minY Tile.aggregateMovementCollision)

        maxReach : Vector2d WorldUnit WorldUnit
        maxReach =
            Vector2d.xy
                (BoundingBox2d.maxX Tile.aggregateMovementCollision)
                (BoundingBox2d.maxY Tile.aggregateMovementCollision)
                |> Vector2d.reverse

        pointMin : Point2d WorldUnit WorldUnit
        pointMin =
            Point2dExtra.componentMin start end |> Point2d.translateBy maxReach

        pointMax : Point2d WorldUnit WorldUnit
        pointMax =
            Point2dExtra.componentMax start end |> Point2d.translateBy minReach
    in
    List.filterMap
        (\{ bounds, intersectionType } ->
            case BoundingBox2d.lineIntersection line bounds |> Quantity.minimumBy (Point2d.distanceFrom start) of
                Just intersection ->
                    Just { intersectionType = intersectionType, intersection = intersection }

                Nothing ->
                    Nothing
        )
        (getBounds2 includeWater pointMin pointMax expandBoundsBy grid)
        |> Quantity.minimumBy (\a -> Point2d.distanceFrom start a.intersection)


getBounds2 :
    Bool
    -> Point2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Vector2d WorldUnit WorldUnit
    -> Grid a
    -> List { bounds : BoundingBox2d WorldUnit WorldUnit, intersectionType : IntersectionType }
getBounds2 includeWater minPoint maxPoint expandBoundsBy grid =
    let
        bounds : BoundingBox2d WorldUnit WorldUnit
        bounds =
            BoundingBox2d.from minPoint maxPoint

        cellBounds : Bounds CellUnit
        cellBounds =
            Bounds.fromCoords
                (Nonempty
                    (Point2d.translateBy expandBoundsBy maxPoint |> worldToCellPoint |> Coord.floorPoint)
                    [ Point2d.translateBy (Vector2d.reverse expandBoundsBy) minPoint
                        |> worldToCellPoint
                        |> Coord.floorPoint
                    ]
                )
    in
    Bounds.coordRangeFold
        (\coord list ->
            let
                water : List { bounds : BoundingBox2d WorldUnit WorldUnit, intersectionType : IntersectionType }
                water =
                    if includeWater then
                        List.range 0 (Terrain.terrainDivisionsPerCell - 1)
                            |> List.concatMap
                                (\x2 ->
                                    List.range 0 (Terrain.terrainDivisionsPerCell - 1)
                                        |> List.filterMap
                                            (\y2 ->
                                                let
                                                    terrainUnit : Coord TerrainUnit
                                                    terrainUnit =
                                                        Coord.xy x2 y2

                                                    worldPosMin =
                                                        cellAndLocalCoordToWorld
                                                            ( coord
                                                            , Coord.scalar Terrain.terrainSize terrainUnit
                                                                |> Coord.changeUnit
                                                            )
                                                            |> Coord.toPoint2d

                                                    worldPosMax =
                                                        cellAndLocalCoordToWorld
                                                            ( coord
                                                            , Coord.plus (Coord.xy 1 1) terrainUnit
                                                                |> Coord.scalar Terrain.terrainSize
                                                                |> Coord.changeUnit
                                                            )
                                                            |> Coord.toPoint2d
                                                in
                                                case (Terrain.getTerrainValue terrainUnit coord).terrainType of
                                                    Water ->
                                                        { bounds = BoundingBox2d.from worldPosMin worldPosMax
                                                        , intersectionType = WaterIntersection
                                                        }
                                                            |> Just

                                                    Mountain ->
                                                        { bounds = BoundingBox2d.from worldPosMin worldPosMax
                                                        , intersectionType = WaterIntersection
                                                        }
                                                            |> Just

                                                    Ground ->
                                                        Nothing
                                            )
                                )

                    else
                        []
            in
            case getCell coord grid of
                Just cell ->
                    GridCell.flatten cell
                        |> List.concatMap
                            (\tile ->
                                cellAndLocalCoordToWorld ( coord, tile.position )
                                    |> Tile.worldMovementBounds expandBoundsBy tile.tile
                                    |> List.filterMap
                                        (\a ->
                                            if BoundingBox2d.intersects a bounds then
                                                Just { bounds = a, intersectionType = TileIntersection }

                                            else
                                                Nothing
                                        )
                            )
                        |> (\a -> a ++ water ++ list)

                Nothing ->
                    { bounds =
                        Bounds.from2Coords
                            (cellAndLocalCoordToWorld ( coord, Coord.xy 0 0 ))
                            (cellAndLocalCoordToWorld ( Coord.plus (Coord.xy 1 1) coord, Coord.xy 0 0 ))
                            |> Bounds.boundsToBounds2d
                    , intersectionType = UnloadedCellIntersection
                    }
                        :: water
                        ++ list
        )
        identity
        cellBounds
        []
