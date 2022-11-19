module Terrain exposing (..)

import Array2D exposing (Array2D)
import Coord exposing (Coord)
import Quantity exposing (Quantity(..))
import Random
import Shaders exposing (Vertex)
import Simplex
import Sprite
import Tile exposing (Tile(..))
import Units exposing (CellLocalUnit, CellUnit)


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


getTerrainLookupValue : Coord TerrainUnit -> Array2D Bool -> Bool
getTerrainLookupValue ( Quantity x, Quantity y ) lookup =
    Array2D.get (x + 1) (y + 1) lookup |> Maybe.withDefault True
