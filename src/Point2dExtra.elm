module Point2dExtra exposing (componentMax, componentMin)

import Point2d exposing (Point2d)
import Quantity


componentMin : Point2d units a -> Point2d units a -> Point2d units a
componentMin a b =
    Point2d.xy
        (Quantity.min (Point2d.xCoordinate a) (Point2d.xCoordinate b))
        (Quantity.min (Point2d.yCoordinate a) (Point2d.yCoordinate b))


componentMax : Point2d units a -> Point2d units a -> Point2d units a
componentMax a b =
    Point2d.xy
        (Quantity.max (Point2d.xCoordinate a) (Point2d.xCoordinate b))
        (Quantity.max (Point2d.yCoordinate a) (Point2d.yCoordinate b))
