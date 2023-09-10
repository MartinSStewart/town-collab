module Benchmark2 exposing (main)

import Benchmark
import Benchmark.Runner
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
