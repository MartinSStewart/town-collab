module Grid exposing
    ( Grid(..)
    , GridChange
    , LocalGridChange
    , Vertex
    , addChange
    , allCells
    , allCellsDict
    , cellAndLocalCoordToAscii
    , cellAndLocalPointToWorld
    , changeCount
    , closeNeighborCells
    , empty
    , from
    , getCell
    , getIndices
    , getTile
    , localChangeToChange
    , localTileCoordPlusWorld
    , localTilePointPlusCellLocalCoord
    , localTilePointPlusWorld
    , mesh
    , moveUndoPoint
    , region
    , removeUser
    , tileMesh
    , tileZ
    , worldToCellAndLocalCoord
    , worldToCellAndLocalPoint
    )

import Basics.Extra
import Bounds exposing (Bounds)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import GridCell exposing (Cell)
import Id exposing (Id, UserId)
import List.Extra as List
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3 exposing (Vec3)
import Pixels
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Tile exposing (Tile)
import Units exposing (CellLocalUnit, CellUnit, TileLocalUnit, WorldUnit)
import Vector2d
import WebGL


type Grid
    = Grid (Dict ( Int, Int ) Cell)


empty : Grid
empty =
    Grid Dict.empty


from : Dict ( Int, Int ) Cell -> Grid
from =
    Grid


localTileCoordPlusWorld : Coord WorldUnit -> Coord TileLocalUnit -> Coord WorldUnit
localTileCoordPlusWorld world local =
    Coord.toTuple local |> Coord.fromTuple |> Coord.addTuple world


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
    ( Coord.fromTuple
        ( (x + (Units.cellSize * offset)) // Units.cellSize - offset
        , (y + (Units.cellSize * offset)) // Units.cellSize - offset
        )
    , Coord.fromTuple
        ( modBy Units.cellSize x
        , modBy Units.cellSize y
        )
    )


worldToCellAndLocalPoint : Point2d WorldUnit WorldUnit -> ( Coord CellUnit, Point2d CellLocalUnit CellLocalUnit )
worldToCellAndLocalPoint point =
    let
        offset =
            1000000

        { x, y } =
            Point2d.unwrap point
    in
    ( Coord.fromTuple
        ( (floor x + (Units.cellSize * offset)) // Units.cellSize - offset
        , (floor y + (Units.cellSize * offset)) // Units.cellSize - offset
        )
    , { x = Basics.Extra.fractionalModBy Units.cellSize x
      , y = Basics.Extra.fractionalModBy Units.cellSize y
      }
        |> Point2d.unsafe
    )


cellAndLocalCoordToAscii : ( Coord CellUnit, Coord CellLocalUnit ) -> Coord WorldUnit
cellAndLocalCoordToAscii ( cell, local ) =
    Coord.addTuple
        (Coord.multiplyTuple ( Units.cellSize, Units.cellSize ) cell)
        (Coord.toTuple local |> Coord.fromTuple)
        |> Coord.toTuple
        |> Coord.fromTuple


cellAndLocalPointToWorld : Coord CellUnit -> Point2d CellLocalUnit CellLocalUnit -> Point2d WorldUnit WorldUnit
cellAndLocalPointToWorld cell local =
    Coord.multiplyTuple ( Units.cellSize, Units.cellSize ) cell
        |> Coord.toPoint2d
        |> Point2d.translateBy (Vector2d.from Point2d.origin local |> Vector2d.unwrap |> Vector2d.unsafe)
        |> Point2d.unwrap
        |> Point2d.unsafe


type alias GridChange =
    { position : Coord WorldUnit, change : Tile, userId : Id UserId }


type alias LocalGridChange =
    { position : Coord WorldUnit, change : Tile }


localChangeToChange : Id UserId -> LocalGridChange -> GridChange
localChangeToChange userId change_ =
    { position = change_.position
    , change = change_.change
    , userId = userId
    }


moveUndoPoint : Id UserId -> Dict RawCellCoord Int -> Grid -> Grid
moveUndoPoint userId undoPoint (Grid grid) =
    Dict.foldl
        (\coord moveAmount newGrid ->
            Dict.update coord (Maybe.map (GridCell.moveUndoPoint userId moveAmount)) newGrid
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
                    Coord.fromTuple offset
                        |> Coord.multiplyTuple ( maxSize, maxSize )
                        |> Coord.addTuple localPosition

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
                    Coord.fromTuple offset |> Coord.addTuple cellPosition
            in
            if ( a, b ) == offset then
                ( newCellPos
                , Coord.fromTuple
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


addChange : GridChange -> Grid -> Grid
addChange change grid =
    let
        ( cellPosition, localPosition ) =
            worldToCellAndLocalCoord change.position

        neighborCells_ : List ( Coord CellUnit, Cell )
        neighborCells_ =
            closeNeighborCells cellPosition localPosition
                |> List.map
                    (\( newCellPos, newLocalPos ) ->
                        getCell newCellPos grid
                            |> Maybe.withDefault GridCell.empty
                            |> GridCell.addValue change.userId newLocalPos change.change
                            |> Tuple.pair newCellPos
                    )
    in
    getCell cellPosition grid
        |> Maybe.withDefault GridCell.empty
        |> GridCell.addValue change.userId localPosition change.change
        |> (\cell_ ->
                List.foldl
                    (\( neighborPos, neighbor ) grid2 ->
                        setCell neighborPos neighbor grid2
                    )
                    (setCell cellPosition cell_ grid)
                    neighborCells_
           )


maxSize =
    6


allCells : Grid -> List ( Coord CellUnit, Cell )
allCells (Grid grid) =
    Dict.toList grid |> List.map (Tuple.mapFirst (\( x, y ) -> ( Units.cellUnit x, Units.cellUnit y )))


allCellsDict : Grid -> Dict ( Int, Int ) Cell
allCellsDict (Grid grid) =
    grid


region : Bounds CellUnit -> Grid -> Grid
region bounds (Grid grid) =
    Dict.filter (\coord _ -> Bounds.contains (Coord.fromTuple coord) bounds) grid |> Grid


getCell : Coord CellUnit -> Grid -> Maybe Cell
getCell ( Quantity x, Quantity y ) (Grid grid) =
    Dict.get ( x, y ) grid


setCell : Coord CellUnit -> Cell -> Grid -> Grid
setCell ( Quantity x, Quantity y ) value (Grid grid) =
    Dict.insert ( x, y ) value grid |> Grid


type alias Vertex =
    { position : Vec3, texturePosition : Vec2 }


mesh : Coord CellUnit -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile } -> WebGL.Mesh Vertex
mesh cellPosition tiles =
    let
        list : List { position : Coord WorldUnit, userId : Id UserId, value : Tile }
        list =
            List.map
                (\{ userId, position, value } ->
                    { position = cellAndLocalCoordToAscii ( cellPosition, position )
                    , userId = userId
                    , value = value
                    }
                )
                tiles

        indices : List ( Int, Int, Int )
        indices =
            List.range 0
                ((List.map
                    (\item ->
                        case Tile.getData item.value |> .texturePositionTopLayer of
                            Just _ ->
                                2

                            Nothing ->
                                1
                    )
                    list
                    |> List.sum
                 )
                    - 1
                )
                |> List.concatMap getIndices
    in
    List.map
        (\{ position, value } ->
            let
                data =
                    Tile.getData value
            in
            tileMeshHelper False position data.texturePosition data.size
                ++ (case data.texturePositionTopLayer of
                        Just topLayer ->
                            tileMeshHelper True position topLayer.texturePosition data.size

                        Nothing ->
                            []
                   )
        )
        list
        |> List.concat
        |> (\vertices -> WebGL.indexedTriangles vertices indices)


tileMesh : ( Quantity Int WorldUnit, Quantity Int WorldUnit ) -> Tile -> WebGL.Mesh Vertex
tileMesh position tile =
    let
        indices =
            List.range 0
                (case Tile.getData tile |> .texturePositionTopLayer of
                    Just _ ->
                        1

                    Nothing ->
                        0
                )
                |> List.concatMap getIndices

        data =
            Tile.getData tile
    in
    tileMeshHelper False position data.texturePosition data.size
        ++ (case data.texturePositionTopLayer of
                Just topLayer ->
                    tileMeshHelper True position topLayer.texturePosition data.size

                Nothing ->
                    []
           )
        |> (\vertices -> WebGL.indexedTriangles vertices indices)


tileMeshHelper :
    Bool
    -> ( Quantity Int WorldUnit, Quantity Int WorldUnit )
    -> ( Int, Int )
    -> ( Int, Int )
    -> List Vertex
tileMeshHelper isTopLayer position texturePosition size =
    let
        { topLeft, topRight, bottomLeft, bottomRight } =
            Tile.texturePosition_ texturePosition size

        topLeftRecord =
            Vec2.toRecord topLeft

        ( Quantity x, Quantity y ) =
            position

        height =
            Tuple.second size
    in
    List.map
        (\uv ->
            let
                uvRecord =
                    Vec2.toRecord uv
            in
            { position =
                Vec3.vec3
                    (uvRecord.x - topLeftRecord.x + toFloat x * Units.tileSize)
                    (uvRecord.y - topLeftRecord.y + toFloat y * Units.tileSize)
                    (tileZ isTopLayer (toFloat y) height)
            , texturePosition = uv
            }
        )
        [ topLeft
        , topRight
        , bottomRight
        , bottomLeft
        ]


tileZ : Bool -> Float -> Int -> Float
tileZ isTopLayer y height =
    (if isTopLayer then
        -0.5

     else
        0
    )
        + (y + toFloat height)
        / -1000


getIndices : number -> List ( number, number, number )
getIndices indexOffset =
    [ ( 4 * indexOffset + 3, 4 * indexOffset + 1, 4 * indexOffset )
    , ( 4 * indexOffset + 2, 4 * indexOffset + 1, 4 * indexOffset + 3 )
    ]


removeUser : Id UserId -> Grid -> Grid
removeUser userId grid =
    allCellsDict grid
        |> Dict.map (\_ cell -> GridCell.removeUser userId cell)
        |> from


getTile : Coord WorldUnit -> Grid -> Maybe { userId : Id UserId, value : Tile, position : Coord WorldUnit }
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
                                    , value = tile.value
                                    , position = cellAndLocalCoordToAscii ( cellPos2, tile.position )
                                    }
                                )

                    Nothing ->
                        Nothing
            )
        |> List.head
