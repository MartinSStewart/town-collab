module Grid exposing
    ( Grid(..)
    , GridChange
    , GridData
    , LocalGridChange
    , addChange
    , allCellsDict
    , backgroundMesh
    , canPlaceTile
    , cellAndLocalCoordToWorld
    , cellAndLocalPointToWorld
    , changeCount
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
    , localChangeToChange
    , localTileCoordPlusWorld
    , localTilePointPlusCellLocalCoord
    , localTilePointPlusWorld
    , localTilePointPlusWorldCoord
    , moveUndoPoint
    , region
    , removeUser
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
import Bounds exposing (Bounds)
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import DisplayName
import GridCell exposing (Cell, CellData)
import Id exposing (Id, UserId)
import IdDict exposing (IdDict)
import List.Extra as List
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite
import Terrain exposing (TerrainType(..), TerrainValue)
import Tile exposing (RailPathType(..), Tile(..), TileData)
import Units exposing (CellLocalUnit, CellUnit, TerrainUnit, TileLocalUnit, WorldUnit)
import User exposing (FrontendUser)
import Vector2d
import WebGL


type GridData
    = GridData (Dict ( Int, Int ) CellData)


dataToGrid : GridData -> Grid
dataToGrid (GridData gridData) =
    Dict.map (\coord cell -> GridCell.dataToCell (Coord.tuple coord) cell) gridData |> Grid


type Grid
    = Grid (Dict ( Int, Int ) Cell)


empty : Grid
empty =
    Grid Dict.empty


from : Dict ( Int, Int ) Cell -> Grid
from =
    Grid


fromData : Dict ( Int, Int ) CellData -> GridData
fromData =
    GridData


localTileCoordPlusWorld : Coord WorldUnit -> Coord TileLocalUnit -> Coord WorldUnit
localTileCoordPlusWorld world local =
    Coord.toTuple local |> Coord.tuple |> Coord.plus world


localTilePointPlusWorld : Coord WorldUnit -> Point2d TileLocalUnit TileLocalUnit -> Point2d WorldUnit WorldUnit
localTilePointPlusWorld world local =
    Point2d.translateBy (Point2d.unwrap local |> Vector2d.unsafe) (Coord.toPoint2d world)


localTilePointPlusCellLocalCoord :
    Coord CellLocalUnit
    -> Point2d TileLocalUnit TileLocalUnit
    -> Point2d CellLocalUnit CellLocalUnit
localTilePointPlusCellLocalCoord cellLocal local =
    Point2d.translateBy (Point2d.unwrap local |> Vector2d.unsafe) (Coord.toPoint2d cellLocal)


localTilePointPlusWorldCoord :
    Coord WorldUnit
    -> Point2d TileLocalUnit TileLocalUnit
    -> Point2d WorldUnit WorldUnit
localTilePointPlusWorldCoord cellLocal local =
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
    { position : Coord WorldUnit, change : Tile, userId : Id UserId, colors : Colors }


type alias LocalGridChange =
    { position : Coord WorldUnit, change : Tile, colors : Colors }


localChangeToChange : Id UserId -> LocalGridChange -> GridChange
localChangeToChange userId change_ =
    { position = change_.position
    , change = change_.change
    , userId = userId
    , colors = change_.colors
    }


moveUndoPoint : Id UserId -> Dict RawCellCoord Int -> Grid -> Grid
moveUndoPoint userId undoPoint (Grid grid) =
    Dict.foldl
        (\coord moveAmount newGrid ->
            Dict.update coord (Maybe.map (GridCell.moveUndoPoint userId moveAmount (Coord.tuple coord))) newGrid
        )
        grid
        undoPoint
        |> Grid


changeCount : Coord CellUnit -> Grid -> Int
changeCount ( Quantity x, Quantity y ) (Grid grid) =
    case Dict.get ( x, y ) grid of
        Just cell ->
            GridCell.changeCount cell

        Nothing ->
            0


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
                                in
                                Tile.hasCollision
                                    change.position
                                    change.change
                                    terrainPosition
                                    MowedGrass4
                         --{ size = Coord.xy Terrain.terrainSize Terrain.terrainSize
                         --, collisionMask = DefaultCollision
                         --}
                        )
            )
        |> not


addChange :
    GridChange
    -> Grid
    ->
        { grid : Grid
        , removed :
            List
                { tile : Tile
                , position : Coord WorldUnit
                , userId : Id UserId
                , colors : Colors
                }
        , newCells : List (Coord CellUnit)
        }
addChange change grid =
    let
        ( cellPosition, localPosition ) =
            worldToCellAndLocalCoord change.position

        value : GridCell.Value
        value =
            { userId = change.userId
            , position = localPosition
            , value = change.change
            , colors = change.colors
            }

        neighborCells_ :
            List
                { neighborPos : Coord CellUnit
                , neighbor : { cell : Cell, removed : List GridCell.Value }
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
                                    GridCell.empty newCellPos
                            )
                                |> GridCell.addValue { value | position = newLocalPos }
                        , isNewCell = oldCell == Nothing
                        }
                    )

        ( cell, newCells ) =
            case getCell cellPosition grid of
                Just cell2 ->
                    ( cell2, [] )

                Nothing ->
                    ( GridCell.empty cellPosition, [ cellPosition ] )
    in
    GridCell.addValue value cell
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
                                        { tile = removed.value
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


getCell2 : Coord CellUnit -> Grid -> { cell : Cell, isNew : Bool, grid : Grid }
getCell2 coord (Grid grid) =
    case Dict.get (Coord.toTuple coord) grid of
        Just cell ->
            { cell = cell, isNew = False, grid = Grid grid }

        Nothing ->
            let
                newCell =
                    GridCell.empty coord
            in
            { cell = newCell, isNew = True, grid = Dict.insert (Coord.toTuple coord) newCell grid |> Grid }


maxTileSize : number
maxTileSize =
    6


allCellsDict : Grid -> Dict ( Int, Int ) Cell
allCellsDict (Grid grid) =
    grid


region : Bounds CellUnit -> Grid -> GridData
region bounds (Grid grid) =
    Dict.filter (\coord _ -> Bounds.contains (Coord.tuple coord) bounds) grid
        |> Dict.map (\_ cell -> GridCell.cellToData cell)
        |> GridData


getCell : Coord CellUnit -> Grid -> Maybe Cell
getCell ( Quantity x, Quantity y ) (Grid grid) =
    Dict.get ( x, y ) grid


setCell : Coord CellUnit -> Cell -> Grid -> Grid
setCell ( Quantity x, Quantity y ) value (Grid grid) =
    Dict.insert ( x, y ) value grid |> Grid


foregroundMesh2 :
    Bool
    -> Maybe { a | tile : Tile, position : Coord WorldUnit }
    -> Coord CellUnit
    -> Maybe (Id UserId)
    -> IdDict UserId FrontendUser
    -> AssocSet.Set (Coord CellLocalUnit)
    -> List GridCell.Value
    -> WebGL.Mesh Vertex
foregroundMesh2 showEmptyTiles maybeCurrentTile cellPosition maybeCurrentUserId users railSplitToggled tiles =
    List.concatMap
        (\{ position, userId, value, colors } ->
            if showEmptyTiles || value /= EmptyTile then
                let
                    position2 : Coord WorldUnit
                    position2 =
                        cellAndLocalCoordToWorld ( cellPosition, position )

                    data : TileData unit
                    data =
                        Tile.getData value

                    opacity : Float
                    opacity =
                        case maybeCurrentTile of
                            Just currentTile ->
                                if Tile.hasCollision currentTile.position currentTile.tile position2 value then
                                    0.5

                                else
                                    1

                            Nothing ->
                                1

                    opacityAndUserId =
                        Shaders.opacityAndUserId opacity userId
                in
                case data.railPath of
                    RailSplitPath pathData ->
                        if AssocSet.member position railSplitToggled then
                            tileMeshHelper2 opacityAndUserId colors (Coord.multiply Units.tileSize position2) 1 pathData.texturePosition data.size

                        else
                            tileMeshHelper2 opacityAndUserId colors (Coord.multiply Units.tileSize position2) 1 data.texturePosition data.size

                    _ ->
                        if value == PostOffice && Just userId /= maybeCurrentUserId then
                            let
                                text =
                                    Sprite.textWithZAndOpacityAndUserId
                                        opacityAndUserId
                                        colors.secondaryColor
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
                                        -0.5
                            in
                            text
                                ++ tileMeshHelper2
                                    opacityAndUserId
                                    colors
                                    (Coord.multiply Units.tileSize position2)
                                    1
                                    (Coord.xy 4 35 |> Coord.multiply Units.tileSize)
                                    data.size

                        else
                            tileMeshHelper2
                                opacityAndUserId
                                colors
                                (Coord.multiply Units.tileSize position2)
                                (case value of
                                    BigText _ ->
                                        2

                                    _ ->
                                        1
                                )
                                data.texturePosition
                                data.size

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
                                            draw 640 216

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
            Shaders.opaque
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


removeUser : Id UserId -> Grid -> Grid
removeUser userId grid =
    allCellsDict grid
        |> Dict.map (\coord cell -> GridCell.removeUser userId (Coord.tuple coord) cell)
        |> from


getTile : Coord WorldUnit -> Grid -> Maybe { userId : Id UserId, tile : Tile, position : Coord WorldUnit, colors : Colors }
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
                                (\{ value, position } ->
                                    Tile.hasCollisionWithCoord localPos2 position (Tile.getData value)
                                )
                            |> Maybe.map
                                (\tile ->
                                    { userId = tile.userId
                                    , tile = tile.value
                                    , position = cellAndLocalCoordToWorld ( cellPos2, tile.position )
                                    , colors = tile.colors
                                    }
                                )

                    Nothing ->
                        Nothing
            )
        |> List.head


toggleRailSplit : Coord WorldUnit -> Grid -> Grid
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


getPostOffice : Id UserId -> Grid -> Maybe (Coord WorldUnit)
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
