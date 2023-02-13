module Benchmark2 exposing (..)

import Array
import AssocSet
import Benchmark
import Benchmark.Runner
import Color
import Coord
import Dict
import Grid
import GridCell
import Id
import IdDict
import Tile exposing (Tile(..))


main =
    Benchmark.compare
        "Grid.foregroundMesh"
        "V1"
        (\() ->
            Grid.foregroundMesh
                Nothing
                Coord.origin
                Nothing
                IdDict.empty
                AssocSet.empty
                cellValues
        )
        "V2"
        (\() ->
            Grid.foregroundMesh2
                Nothing
                Coord.origin
                Nothing
                IdDict.empty
                AssocSet.empty
                cellValues
        )
        |> Benchmark.Runner.program


cellValues =
    List.range 0 99
        |> List.map
            (\index ->
                { userId = Id.fromInt 0
                , position = Coord.xy (modBy 16 index) (index // 16)
                , value = Sidewalk
                , colors = { primaryColor = Color.black, secondaryColor = Color.white }
                }
            )
