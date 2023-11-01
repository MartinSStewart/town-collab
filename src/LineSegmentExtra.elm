module LineSegmentExtra exposing (extendLineEnd)

import Point2d exposing (Point2d)
import Quantity exposing (Quantity)


extendLineEnd : Point2d u c -> Point2d u c -> Quantity Float u -> Point2d u c
extendLineEnd start end extendBy =
    let
        distance : Quantity Float u
        distance =
            Point2d.distanceFrom start end
    in
    Point2d.interpolateFrom
        start
        end
        (Quantity.ratio (distance |> Quantity.plus extendBy) distance |> max 0)
