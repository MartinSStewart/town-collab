module Terrain exposing
    ( TerrainType(..)
    , TerrainValue
    , createTerrainLookup
    , getTerrainValue
    , localCoordToTerrain
    , permutationTable
    , randomScenery
    , terrainCoord
    , terrainDivisionsPerCell
    , terrainSize
    , terrainToLocalCoord
    )

import Array2D exposing (Array2D)
import Coord exposing (Coord)
import Quantity exposing (Quantity(..))
import Random
import Simplex
import Tile exposing (Tile(..))
import Units exposing (CellLocalUnit, CellUnit, TerrainUnit)


terrainCoord : Int -> Int -> Coord TerrainUnit
terrainCoord x y =
    Coord.xy x y


terrainToLocalCoord : Coord TerrainUnit -> Coord CellLocalUnit
terrainToLocalCoord coord =
    Coord.multiplyTuple ( terrainSize, terrainSize ) coord |> Coord.changeUnit


localCoordToTerrain : Coord CellLocalUnit -> Coord TerrainUnit
localCoordToTerrain coord =
    Coord.divide (Coord.xy terrainSize terrainSize) coord |> Coord.changeUnit


treeSize : Coord unit
treeSize =
    Tile.getData PineTree1 |> .size


randomSceneryItem : Bool -> Coord CellLocalUnit -> Random.Generator ( Tile, Coord CellLocalUnit )
randomSceneryItem bigTrees offset =
    if bigTrees then
        Random.map3
            (\x y tile ->
                let
                    size =
                        Tile.getData tile |> .size

                    x2 =
                        modBy terrainSize x - Coord.xRaw size // 2

                    y2 =
                        modBy terrainSize y - (Coord.yRaw size - 1)
                in
                ( tile, Coord.xy x2 y2 |> Coord.plus offset )
            )
            (Random.int 0 1000)
            (Random.int 0 1000)
            (Random.weighted
                ( 0.0025, PineTree1 )
                [ ( 0.0025, PineTree2 )
                , ( 0.87, BigPineTree )
                , ( 0.0025, Mushroom1 )
                , ( 0.0025, Mushroom2 )
                , ( 0.0025, BerryBush1 )
                , ( 0.0025, BerryBush2 )
                , ( 0.0025, RockDown )
                , ( 0.0025, RockLeft )
                , ( 0.0025, RockUp )
                , ( 0.0025, RockRight )
                ]
            )

    else
        Random.map3 (\x y tile -> ( tile, Coord.xy x y |> Coord.plus offset ))
            (Random.int 0 (terrainSize - Coord.xRaw treeSize))
            (Random.int -1 (terrainSize - Coord.yRaw treeSize))
            (Random.weighted
                ( 0.49, PineTree1 )
                [ ( 0.49, PineTree2 )
                , ( 0.0025, BerryBush1 )
                , ( 0.0025, BerryBush2 )
                , ( 0.0025, RockDown )
                , ( 0.0025, RockLeft )
                , ( 0.0025, RockUp )
                , ( 0.0025, RockRight )
                ]
            )


randomScenery : Float -> Coord CellLocalUnit -> Random.Generator (List ( Tile, Coord CellLocalUnit ))
randomScenery chance offset =
    let
        chance2 : Float
        chance2 =
            20 * chance ^ 3 |> min 3
    in
    Random.weighted
        ( 0.98, 0 )
        [ ( 0.02, 1 ) ]
        |> Random.andThen
            (\extraItem ->
                Random.list (round chance2 + extraItem) (randomSceneryItem (chance2 > 1) offset)
            )


terrainDivisionsPerCell : number
terrainDivisionsPerCell =
    4


terrainSize : Int
terrainSize =
    Units.cellSize // terrainDivisionsPerCell


createTerrainLookup : Coord CellUnit -> Array2D TerrainValue
createTerrainLookup cellPosition =
    List.range -1 terrainDivisionsPerCell
        |> List.map
            (\x2 ->
                List.range -1 terrainDivisionsPerCell
                    |> List.map (\y2 -> getTerrainValue (Coord.xy x2 y2) cellPosition)
            )
        |> Array2D.fromList


type alias TerrainValue =
    { value : Float, terrainType : TerrainType }


type TerrainType
    = Water
    | Ground
    | Mountain


getTerrainValue : Coord TerrainUnit -> Coord CellUnit -> TerrainValue
getTerrainValue ( Quantity x, Quantity y ) ( Quantity cellX, Quantity cellY ) =
    let
        persistence =
            2

        persistence2 =
            1 + persistence

        scale =
            5

        scale2 =
            14 * scale

        x2 =
            toFloat x / terrainDivisionsPerCell + toFloat cellX

        y2 =
            toFloat y / terrainDivisionsPerCell + toFloat cellY

        highFrequency =
            Simplex.noise2d permutationTable (x2 / scale) (y2 / scale)

        lowFrequency =
            Simplex.noise2d permutationTable (x2 / scale2) (y2 / scale2)

        value2 =
            (-highFrequency + (5.0 * lowFrequency)) / 6.0

        noise1 =
            highFrequency + (persistence * lowFrequency)

        value =
            noise1 / persistence2
    in
    { value = value
    , terrainType =
        if value > 0 then
            if value2 > 0.45 && value2 < 0.47 then
                Mountain

            else
                Ground

        else
            Water
    }


permutationTable : Simplex.PermutationTable
permutationTable =
    Simplex.permutationTableFromInt 123
