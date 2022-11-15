module View exposing (View, cellBounds, view)

import Coord exposing (Coord)
import Grid
import Point2d
import Units


type View
    = View
        { viewPoint : Coord Units.WorldUnit
        , viewSize : Coord Units.WorldUnit
        }


view : { viewPoint : Coord Units.WorldUnit, viewSize : Coord Units.WorldUnit } -> View
view view_ =
    let
        viewPoint_ =
            Coord.minTuple ( Units.tileUnit 100, Units.tileUnit 100 ) view_.viewPoint
                |> Coord.maxTuple ( Units.tileUnit -100, Units.tileUnit -100 )

        maxSize =
            Point2d.xy (Units.worldUnit 4000) (Units.worldUnit 2200) |> Units.worldToTile
    in
    View
        { viewPoint = viewPoint_
        , viewSize = Coord.absTuple view_.viewSize |> Coord.minTuple maxSize
        }


cellBounds : View -> { min : Coord Units.CellUnit, max : Coord Units.CellUnit }
cellBounds (View view_) =
    let
        ( sx, sy ) =
            Coord.toTuple view_.viewSize

        ( x, y ) =
            Coord.toTuple view_.viewPoint
    in
    { min =
        ( toFloat x - toFloat sx / 2 |> floor, toFloat y - toFloat sy / 2 |> floor )
            |> Coord.tuple
            |> Grid.worldToCellAndLocalCoord
            |> Tuple.first
    , max =
        ( toFloat x - toFloat sx / 2 |> ceiling, toFloat y - toFloat sy / 2 |> ceiling )
            |> Coord.tuple
            |> Grid.worldToCellAndLocalCoord
            |> Tuple.first
    }
