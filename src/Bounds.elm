module Bounds exposing
    ( Bounds(..)
    , aggregate
    , bounds
    , boundsToBounds2d
    , contains
    , containsBounds
    , coordRangeFold
    , from2Coords
    , fromCoordAndSize
    , fromCoords
    , maximum
    , minimum
    )

import BoundingBox2d exposing (BoundingBox2d)
import Coord exposing (Coord)
import List.Nonempty exposing (Nonempty(..))
import NonemptyExtra as Nonempty
import Quantity exposing (Quantity(..))


type Bounds unit
    = Bounds { min : Coord unit, max : Coord unit }


minimum : Bounds unit -> Coord unit
minimum (Bounds bounds_) =
    bounds_.min


maximum : Bounds unit -> Coord unit
maximum (Bounds bounds_) =
    bounds_.max


bounds : Coord unit -> Coord unit -> Bounds unit
bounds min_ max_ =
    Bounds
        { min = Coord.minimum min_ max_
        , max = Coord.maxTuple min_ max_
        }


aggregate : Nonempty (Bounds unit) -> Bounds unit
aggregate bounds_ =
    Bounds
        { min = List.Nonempty.foldl1 Coord.minimum (List.Nonempty.map minimum bounds_)
        , max = List.Nonempty.foldl1 Coord.maximum (List.Nonempty.map maximum bounds_)
        }


fromCoords : Nonempty (Coord unit) -> Bounds unit
fromCoords coords =
    let
        xValues =
            List.Nonempty.map Tuple.first coords

        yValues =
            List.Nonempty.map Tuple.second coords
    in
    Bounds
        { min = ( Nonempty.minimumBy Quantity.unwrap xValues, Nonempty.minimumBy Quantity.unwrap yValues )
        , max = ( Nonempty.maximumBy Quantity.unwrap xValues, Nonempty.maximumBy Quantity.unwrap yValues )
        }


from2Coords : Coord unit -> Coord unit -> Bounds unit
from2Coords first second =
    fromCoords (Nonempty first [ second ])


fromCoordAndSize : Coord unit -> Coord unit -> Bounds unit
fromCoordAndSize coord size_ =
    fromCoords (Nonempty coord [ Coord.plus coord size_ ])


contains : Coord unit -> Bounds unit -> Bool
contains ( Quantity x, Quantity y ) (Bounds bounds_) =
    let
        ( Quantity minX, Quantity minY ) =
            bounds_.min

        ( Quantity maxX, Quantity maxY ) =
            bounds_.max
    in
    minX <= x && x <= maxX && minY <= y && y <= maxY


containsBounds : Bounds unit -> Bounds unit -> Bool
containsBounds (Bounds otherBounds) (Bounds bounds_) =
    let
        ( Quantity minX, Quantity minY ) =
            bounds_.min

        ( Quantity maxX, Quantity maxY ) =
            bounds_.max

        ( Quantity otherMinX, Quantity otherMinY ) =
            otherBounds.min

        ( Quantity otherMaxX, Quantity otherMaxY ) =
            otherBounds.max
    in
    (minX <= otherMinX && otherMinX <= maxX && minY <= otherMinY && otherMinY <= maxY)
        && (minX <= otherMaxX && otherMaxX <= maxX && minY <= otherMaxY && otherMaxY <= maxY)


boundsToBounds2d : Bounds units -> BoundingBox2d units coordinate
boundsToBounds2d (Bounds bounds_) =
    BoundingBox2d.from (Coord.toPoint2d bounds_.min) (Coord.toPoint2d bounds_.max)


coordRangeFold : (Coord units -> a -> a) -> (a -> a) -> Bounds units -> a -> a
coordRangeFold foldFunc rowChangeFunc (Bounds bounds_) initialValue =
    let
        ( x0, y0 ) =
            Coord.toTuple bounds_.min

        ( x1, y1 ) =
            Coord.toTuple bounds_.max
    in
    coordRangeFoldHelper foldFunc rowChangeFunc x0 x1 y0 y1 x0 y0 initialValue


coordRangeFoldHelper : (Coord units -> a -> a) -> (a -> a) -> Int -> Int -> Int -> Int -> Int -> a -> a
coordRangeFoldHelper foldFunc rowChangeFunc minX maxX maxY x y value =
    if y > maxY then
        value

    else
        coordRangeFoldHelper foldFunc
            rowChangeFunc
            minX
            maxX
            maxY
            (if x >= maxX then
                minX

             else
                x + 1
            )
            (if x >= maxX then
                y + 1

             else
                y
            )
            (foldFunc ( Quantity x, Quantity y ) value
                |> (if x >= maxX && y < maxY then
                        rowChangeFunc

                    else
                        identity
                   )
            )
