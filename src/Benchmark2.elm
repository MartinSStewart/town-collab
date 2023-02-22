module Benchmark2 exposing (..)

import Array
import AssocSet
import Benchmark
import Benchmark.Reporting
import Benchmark.Runner
import Color exposing (Color(..))
import Coord
import Dict
import Grid
import GridCell
import Id
import IdDict
import Quantity exposing (Quantity(..))
import Tile exposing (TileGroup(..))
import Toolbar
import Types exposing (ToolButton(..), UiHover(..))
import Ui exposing (BorderAndFill(..), Element(..))


main =
    Benchmark.compare
        "Grid.foregroundMesh"
        "V1"
        (\() ->
            Ui.visuallyEqual a b
        )
        "V2"
        (\() ->
            a == b
        )
        |> Benchmark.Runner.program


uiA =
    Toolbar.view


uiB =
    Toolbar.view
