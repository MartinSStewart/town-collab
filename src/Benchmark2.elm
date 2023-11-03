module Benchmark2 exposing (main)

import Benchmark
import Benchmark.Runner
import Color
import Coord
import Effect.Time
import Grid exposing (Grid)
import Id
import Point2d
import Tile exposing (Tile(..))
import Ui
import Units
import Vector2d


grid : Grid
grid =
    Grid.empty
        |> Grid.addChange
            { position = Coord.xy 73 -117
            , change = EmptyTile
            , userId = Id.fromInt 1
            , colors = { primaryColor = Color.black, secondaryColor = Color.black }
            , time = Effect.Time.millisToPosix 0
            }
        |> .grid


a =
    (Grid.rayIntersection
        True
        Vector2d.zero
        (Point2d.fromTuple Units.tileUnit ( 72, -118 ))
        (Point2d.fromTuple Units.tileUnit ( 77, -113 ))
        grid
        == Grid.rayIntersection2
            True
            Vector2d.zero
            (Point2d.fromTuple Units.tileUnit ( 72, -118 ))
            (Point2d.fromTuple Units.tileUnit ( 77, -113 ))
            grid
    )
        |> Debug.log "result"


main =
    let
        b =
            a
    in
    Benchmark.compare
        "Grid.rayIntersection"
        "V1"
        (\() ->
            Grid.rayIntersection
                True
                Vector2d.zero
                (Point2d.fromTuple Units.tileUnit ( 72, -118 ))
                (Point2d.fromTuple Units.tileUnit ( 77, -113 ))
                grid
        )
        "V2"
        (\() ->
            Grid.rayIntersection2
                True
                Vector2d.zero
                (Point2d.fromTuple Units.tileUnit ( 72, -118 ))
                (Point2d.fromTuple Units.tileUnit ( 77, -113 ))
                grid
        )
        |> Benchmark.Runner.program
