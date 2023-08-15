module Benchmark2 exposing (..)

import Benchmark
import Benchmark.Runner
import Toolbar
import Ui


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
