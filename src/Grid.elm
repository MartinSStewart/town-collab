module Grid exposing
    ( Grid(..)
    , GridChange
    , LocalGridChange
    , addChange
    , allCells
    , allCellsDict
    , backgroundMesh
    , canAddChange
    , cellAndLocalCoordToWorld
    , cellAndLocalPointToWorld
    , changeCount
    , closeNeighborCells
    , empty
    , foregroundMesh
    , from
    , getCell
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
    , tileZ
    , worldToCellAndLocalCoord
    , worldToCellAndLocalPoint
    )

import Array2D exposing (Array2D)
import Basics.Extra
import Bounds exposing (Bounds)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import GridCell exposing (Cell)
import Id exposing (Id, UserId)
import List.Extra as List
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3 exposing (Vec3)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Random
import Shaders exposing (Vertex)
import Simplex
import Sprite
import Tile exposing (CollisionMask(..), Tile(..), TileData)
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
    Coord.toTuple local |> Coord.tuple |> Coord.addTuple world


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
    Coord.addTuple
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
                    Coord.tuple offset
                        |> Coord.multiplyTuple ( maxTileSize - 1, maxTileSize - 1 )
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
                    Coord.tuple offset |> Coord.addTuple cellPosition
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


canAddChange : { a | position : Coord WorldUnit, change : Tile } -> Bool
canAddChange change =
    let
        ( cellPosition, ( Quantity x, Quantity y ) ) =
            worldToCellAndLocalCoord change.position

        tileData : TileData
        tileData =
            Tile.getData change.change

        ( tileW, tileH ) =
            tileData.size
    in
    List.range 0 (1 + tileW // terrainSize)
        |> List.any
            (\x2 ->
                List.range 0 (1 + tileH // terrainSize)
                    |> List.any
                        (\y2 ->
                            let
                                x3 =
                                    x2 + (x // terrainSize)

                                y3 =
                                    y2 + (y // terrainSize)
                            in
                            if isGroundTerrain (Coord.xy x3 y3) cellPosition then
                                False

                            else
                                let
                                    terrainPosition : Coord WorldUnit
                                    terrainPosition =
                                        cellAndLocalCoordToWorld
                                            ( cellPosition
                                            , Coord.tuple ( x3 * terrainSize, y3 * terrainSize )
                                            )
                                in
                                Tile.hasCollision
                                    change.position
                                    tileData
                                    terrainPosition
                                    { size = ( terrainSize, terrainSize ), collisionMask = DefaultCollision }
                        )
            )
        |> not


terrainCoord : Int -> Int -> Coord TerrainUnit
terrainCoord x y =
    Coord.xy x y


terrainToLocalCoord : Coord TerrainUnit -> Coord CellLocalUnit
terrainToLocalCoord coord =
    Coord.multiplyTuple ( terrainSize, terrainSize ) coord |> Coord.toTuple |> Coord.tuple


treeSize =
    Tile.getData PineTree |> .size


randomTreePosition : Coord CellLocalUnit -> Random.Generator (Coord CellLocalUnit)
randomTreePosition offset =
    Random.map2 (\x y -> Coord.xy x y |> Coord.addTuple offset)
        (Random.int 0 (terrainSize - Tuple.first treeSize))
        (Random.int 0 (terrainSize - Tuple.second treeSize))


randomTrees : Float -> Coord CellLocalUnit -> Random.Generator (List (Coord CellLocalUnit))
randomTrees chance offset =
    let
        chance2 : Float
        chance2 =
            20 * chance ^ 3 |> min 3
    in
    Random.weighted
        ( 0.98, 0 )
        [ ( 0.02, 1 ) ]
        |> Random.andThen
            (\extraTree ->
                Random.list (round chance2 + extraTree) (randomTreePosition offset)
            )


addChange : GridChange -> Grid -> Grid
addChange change grid =
    let
        newCell (( Quantity cellX, Quantity cellY ) as newCellPosition) =
            List.range 0 (terrainDivisionsPerCell - 1)
                |> List.concatMap
                    (\x ->
                        List.range 0 (terrainDivisionsPerCell - 1)
                            |> List.map (\y -> terrainCoord x y)
                    )
                |> List.foldl
                    (\(( Quantity terrainX, Quantity terrainY ) as terrainCoord_) cell ->
                        let
                            position : Coord CellLocalUnit
                            position =
                                terrainToLocalCoord terrainCoord_

                            seed =
                                Random.initialSeed (cellX * 269 + cellY * 229 + terrainX * 67 + terrainY)

                            treeDensity : Float
                            treeDensity =
                                getTerrainValue terrainCoord_ newCellPosition
                        in
                        if treeDensity > 0 then
                            Random.step (randomTrees treeDensity position) seed
                                |> Tuple.first
                                |> List.foldl
                                    (\treePosition cell2 ->
                                        GridCell.addValue (Id.fromInt -1) treePosition PineTree cell2
                                    )
                                    cell

                        else
                            cell
                    )
                    GridCell.empty

        ( cellPosition, localPosition ) =
            worldToCellAndLocalCoord change.position

        neighborCells_ : List ( Coord CellUnit, Cell )
        neighborCells_ =
            closeNeighborCells cellPosition localPosition
                |> List.map
                    (\( newCellPos, newLocalPos ) ->
                        (case getCell newCellPos grid of
                            Just cell ->
                                cell

                            Nothing ->
                                newCell newCellPos
                        )
                            |> GridCell.addValue change.userId newLocalPos change.change
                            |> Tuple.pair newCellPos
                    )
    in
    (case getCell cellPosition grid of
        Just cell ->
            cell

        Nothing ->
            newCell cellPosition
    )
        |> GridCell.addValue change.userId localPosition change.change
        |> (\cell_ ->
                List.foldl
                    (\( neighborPos, neighbor ) grid2 ->
                        setCell neighborPos neighbor grid2
                    )
                    (setCell cellPosition cell_ grid)
                    neighborCells_
           )


maxTileSize : number
maxTileSize =
    6


allCells : Grid -> List ( Coord CellUnit, Cell )
allCells (Grid grid) =
    Dict.toList grid |> List.map (Tuple.mapFirst (\( x, y ) -> ( Units.cellUnit x, Units.cellUnit y )))


allCellsDict : Grid -> Dict ( Int, Int ) Cell
allCellsDict (Grid grid) =
    grid


region : Bounds CellUnit -> Grid -> Grid
region bounds (Grid grid) =
    Dict.filter (\coord _ -> Bounds.contains (Coord.tuple coord) bounds) grid |> Grid


getCell : Coord CellUnit -> Grid -> Maybe Cell
getCell ( Quantity x, Quantity y ) (Grid grid) =
    Dict.get ( x, y ) grid


setCell : Coord CellUnit -> Cell -> Grid -> Grid
setCell ( Quantity x, Quantity y ) value (Grid grid) =
    Dict.insert ( x, y ) value grid |> Grid


foregroundMesh :
    Maybe { a | tile : Tile, position : Coord WorldUnit }
    -> Coord CellUnit
    -> Id UserId
    -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> WebGL.Mesh Vertex
foregroundMesh maybeCurrentTile cellPosition currentUserId tiles =
    let
        list : List { position : Coord WorldUnit, userId : Id UserId, value : Tile }
        list =
            List.map
                (\{ userId, position, value } ->
                    { position = cellAndLocalCoordToWorld ( cellPosition, position )
                    , userId = userId
                    , value = value
                    }
                )
                tiles
    in
    List.map
        (\{ position, userId, value } ->
            let
                data : TileData
                data =
                    Tile.getData value

                opacity =
                    case maybeCurrentTile of
                        Just currentTile ->
                            if
                                Tile.hasCollision
                                    currentTile.position
                                    (Tile.getData currentTile.tile)
                                    position
                                    data
                            then
                                0.5

                            else
                                1

                        Nothing ->
                            1
            in
            tileMeshHelper opacity False position data.texturePosition data.size
                ++ (case data.texturePositionTopLayer of
                        Just topLayer ->
                            if value == PostOffice && userId /= currentUserId then
                                tileMeshHelper opacity True position ( 4, 35 ) data.size

                            else
                                tileMeshHelper opacity True position topLayer.texturePosition data.size

                        Nothing ->
                            []
                   )
        )
        list
        |> List.concat
        |> (\vertices -> WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices))


backgroundMesh : Coord CellUnit -> WebGL.Mesh Vertex
backgroundMesh cellPosition =
    grassMesh cellPosition
        |> (\vertices -> WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices))


terrainDivisionsPerCell : number
terrainDivisionsPerCell =
    4


terrainSize : Int
terrainSize =
    Units.cellSize // terrainDivisionsPerCell


createTerrainLookup : Coord CellUnit -> Array2D Bool
createTerrainLookup cellPosition =
    List.range -1 terrainDivisionsPerCell
        |> List.map
            (\x2 ->
                List.range -1 terrainDivisionsPerCell
                    |> List.map (\y2 -> getTerrainValue (Coord.xy x2 y2) cellPosition > 0)
            )
        |> Array2D.fromList


type TerrainUnit
    = TerrainUnit Never


getTerrainValue : Coord TerrainUnit -> Coord CellUnit -> Float
getTerrainValue ( Quantity x, Quantity y ) ( Quantity cellX, Quantity cellY ) =
    Simplex.fractal2d
        fractalConfig
        permutationTable
        (toFloat x / terrainDivisionsPerCell + toFloat cellX)
        (toFloat y / terrainDivisionsPerCell + toFloat cellY)


isGroundTerrain : Coord TerrainUnit -> Coord CellUnit -> Bool
isGroundTerrain ( Quantity x, Quantity y ) cellPosition =
    let
        getValue x2 y2 =
            getTerrainValue (Coord.xy (x + x2) (y + y2)) cellPosition > 0
    in
    case
        ( {- Top -} getValue 0 -1
        , ( getValue -1 0, getValue 0 0, getValue 1 0 ) {- Left, Center, Right -}
        , {- Bottom -} getValue 0 1
        )
    of
        --( True, ( True, _, True ), True ) ->
        --    True
        ( _, ( _, True, _ ), _ ) ->
            True

        ( _, ( _, False, _ ), _ ) ->
            False


getTerrainLookupValue : Coord TerrainUnit -> Array2D Bool -> Bool
getTerrainLookupValue ( Quantity x, Quantity y ) lookup =
    Array2D.get (x + 1) (y + 1) lookup |> Maybe.withDefault True


grassMesh : Coord CellUnit -> List Vertex
grassMesh cellPosition =
    let
        lookup : Array2D Bool
        lookup =
            createTerrainLookup cellPosition

        ( Quantity x, Quantity y ) =
            cellAndLocalCoordToWorld ( cellPosition, Coord.origin )
    in
    List.range 0 (terrainDivisionsPerCell - 1)
        |> List.concatMap
            (\x2 ->
                List.range 0 (terrainDivisionsPerCell - 1)
                    |> List.concatMap
                        (\y2 ->
                            let
                                getValue : Int -> Int -> Bool
                                getValue x3 y3 =
                                    getTerrainLookupValue (Coord.xy (x2 + x3) (y2 + y3)) lookup

                                draw : Int -> Int -> List Vertex
                                draw textureX textureY =
                                    Sprite.spriteMeshWithZ
                                        ( (x2 * terrainDivisionsPerCell + x) * Units.tileSize
                                        , (y2 * terrainDivisionsPerCell + y) * Units.tileSize
                                        )
                                        0.9
                                        (Coord.tuple ( 72, 72 ))
                                        ( textureX, textureY )
                                        ( 72, 72 )

                                corners =
                                    [ { side1 = getValue 0 -1
                                      , corner = getValue -1 -1
                                      , side2 = getValue -1 0
                                      , texturePos = ( 432, 504 )
                                      }
                                    , { side1 = getValue 0 -1
                                      , corner = getValue 1 -1
                                      , side2 = getValue 1 0
                                      , texturePos = ( 360, 504 )
                                      }
                                    , { side1 = getValue 0 1
                                      , corner = getValue 1 1
                                      , side2 = getValue 1 0
                                      , texturePos = ( 360, 432 )
                                      }
                                    , { side1 = getValue 0 1
                                      , corner = getValue -1 1
                                      , side2 = getValue -1 0
                                      , texturePos = ( 432, 432 )
                                      }
                                    ]
                                        |> List.concatMap
                                            (\{ side1, corner, side2, texturePos } ->
                                                if side1 == False && corner == True && side2 == False then
                                                    draw (Tuple.first texturePos) (Tuple.second texturePos)

                                                else
                                                    []
                                            )

                                tile =
                                    if getValue 0 0 then
                                        draw 198 216

                                    else
                                        case
                                            ( {- Top -} getValue 0 -1
                                            , ( getValue -1 0, getValue 1 0 ) {- Left, Right -}
                                            , {- Bottom -} getValue 0 1
                                            )
                                        of
                                            ( False, ( False, False ), False ) ->
                                                draw 432 288

                                            ( True, ( False, False ), False ) ->
                                                draw 432 216

                                            ( False, ( True, False ), False ) ->
                                                draw 360 288

                                            ( True, ( True, False ), False ) ->
                                                draw 360 216

                                            ( False, ( False, True ), False ) ->
                                                draw 504 288

                                            ( True, ( False, True ), False ) ->
                                                draw 504 216

                                            ( False, ( True, True ), False ) ->
                                                draw 504 504

                                            ( True, ( True, True ), False ) ->
                                                draw 504 432

                                            ( False, ( False, False ), True ) ->
                                                draw 432 360

                                            ( True, ( False, False ), True ) ->
                                                draw 432 648

                                            ( False, ( True, False ), True ) ->
                                                draw 360 360

                                            ( True, ( True, False ), True ) ->
                                                draw 360 648

                                            ( False, ( False, True ), True ) ->
                                                draw 504 360

                                            ( True, ( False, True ), True ) ->
                                                draw 504 648

                                            ( False, ( True, True ), True ) ->
                                                draw 504 576

                                            ( True, ( True, True ), True ) ->
                                                --draw 198 216
                                                draw 432 288
                            in
                            corners ++ tile
                        )
            )


fractalConfig : Simplex.FractalConfig
fractalConfig =
    { steps = 2
    , stepSize = 14
    , persistence = 2
    , scale = 5
    }


permutationTable : Simplex.PermutationTable
permutationTable =
    Simplex.permutationTableFromInt 123


tileMesh : ( Quantity Int WorldUnit, Quantity Int WorldUnit ) -> Tile -> WebGL.Mesh Vertex
tileMesh position tile =
    let
        data =
            Tile.getData tile
    in
    (if tile == EmptyTile then
        Sprite.spriteMesh (Coord.addTuple_ ( 6, -16 ) position |> Coord.toTuple) (Coord.tuple ( 30, 29 )) ( 324, 223 ) ( 30, 29 )

     else
        tileMeshHelper 1 False position data.texturePosition data.size
            ++ (case data.texturePositionTopLayer of
                    Just topLayer ->
                        tileMeshHelper 1 True position topLayer.texturePosition data.size

                    Nothing ->
                        []
               )
    )
        |> (\vertices -> WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices))


tileMeshHelper :
    Float
    -> Bool
    -> ( Quantity Int WorldUnit, Quantity Int WorldUnit )
    -> ( Int, Int )
    -> ( Int, Int )
    -> List Vertex
tileMeshHelper opacity isTopLayer position texturePosition size =
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
            , opacity = opacity
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
                                    , position = cellAndLocalCoordToWorld ( cellPos2, tile.position )
                                    }
                                )

                    Nothing ->
                        Nothing
            )
        |> List.head
