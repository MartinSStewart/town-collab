module BoundingBox2dExtra exposing (lineIntersection)

import BoundingBox2d exposing (BoundingBox2d)
import LineSegment2d exposing (LineSegment2d)
import Point2d exposing (Point2d)


lineIntersection : LineSegment2d u c -> BoundingBox2d u c -> List (Point2d u c)
lineIntersection line bounds =
    let
        { minX, minY, maxX, maxY } =
            BoundingBox2d.extrema bounds

        point0 =
            Point2d.xy minX minY

        point1 =
            Point2d.xy maxX minY

        point2 =
            Point2d.xy maxX maxY

        point3 =
            Point2d.xy minX maxY
    in
    List.filterMap
        identity
        [ LineSegment2d.intersectionPoint line (LineSegment2d.from point0 point1)
        , LineSegment2d.intersectionPoint line (LineSegment2d.from point1 point2)
        , LineSegment2d.intersectionPoint line (LineSegment2d.from point2 point3)
        , LineSegment2d.intersectionPoint line (LineSegment2d.from point3 point0)
        ]
