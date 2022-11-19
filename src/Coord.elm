module Coord exposing
    ( Coord
    , RawCellCoord
    , absTuple
    , addTuple
    , addTuple_
    , area
    , divideTuple
    , floorPoint
    , maxTuple
    , minTuple
    , minusTuple
    , minusTuple_
    , multiplyTuple
    , origin
    , roundPoint
    , toPoint2d
    , toTuple
    , toVec2
    , toVector2d
    , toggleSet
    , translateMat4
    , tuple
    , xy
    )

import EverySet exposing (EverySet)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Vector2d exposing (Vector2d)


type alias RawCellCoord =
    ( Int, Int )


area : Coord unit -> Int
area coord =
    let
        ( x, y ) =
            toTuple coord
    in
    x * y


translateMat4 : Coord unit -> Mat4 -> Mat4
translateMat4 ( Quantity x, Quantity y ) =
    Mat4.translate3 (toFloat x) (toFloat y) 0


origin : Coord units
origin =
    tuple ( 0, 0 )


addTuple : Coord unit -> Coord unit -> Coord unit
addTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.plus x0 x1, Quantity.plus y0 y1 )


addTuple_ : ( Int, Int ) -> Coord unit -> Coord unit
addTuple_ ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.plus (Quantity x0) x1, Quantity.plus (Quantity y0) y1 )


minusTuple : Coord unit -> Coord unit -> Coord unit
minusTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.minus x0 x1, Quantity.minus y0 y1 )


minusTuple_ : ( Int, Int ) -> Coord unit -> Coord unit
minusTuple_ ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.minus (Quantity x0) x1, Quantity.minus (Quantity y0) y1 )


multiplyTuple : ( Int, Int ) -> Coord unit -> Coord unit
multiplyTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.multiplyBy x0 x1, Quantity.multiplyBy y0 y1 )


divideTuple : Coord unit -> Coord unit -> Coord unit
divideTuple ( Quantity x0, Quantity y0 ) ( Quantity x1, Quantity y1 ) =
    ( x1 // x0 |> Quantity, y1 // y0 |> Quantity )


minTuple : Coord unit -> Coord unit -> Coord unit
minTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.min x0 x1, Quantity.min y0 y1 )


maxTuple : Coord unit -> Coord unit -> Coord unit
maxTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.max x0 x1, Quantity.max y0 y1 )


absTuple : Coord unit -> Coord unit
absTuple ( x0, y0 ) =
    ( Quantity.abs x0, Quantity.abs y0 )


toVec2 : Coord units -> Vec2
toVec2 ( Quantity x, Quantity y ) =
    Math.Vector2.vec2 (toFloat x) (toFloat y)


toPoint2d : Coord units -> Point2d units coordinate
toPoint2d ( x, y ) =
    Point2d.xy (Quantity.toFloatQuantity x) (Quantity.toFloatQuantity y)


roundPoint : Point2d units coordinate -> Coord units
roundPoint point2d =
    let
        { x, y } =
            Point2d.unwrap point2d
    in
    tuple ( round x, round y )


floorPoint : Point2d units coordinate -> Coord units
floorPoint point2d =
    let
        { x, y } =
            Point2d.unwrap point2d
    in
    tuple ( floor x, floor y )


toVector2d : Coord units -> Vector2d units coordinate
toVector2d ( x, y ) =
    Vector2d.xy (Quantity.toFloatQuantity x) (Quantity.toFloatQuantity y)


toTuple : Coord units -> ( Int, Int )
toTuple ( Quantity x, Quantity y ) =
    ( x, y )


tuple : ( Int, Int ) -> Coord units
tuple ( x, y ) =
    ( Quantity x, Quantity y )


xy : Int -> Int -> Coord units
xy x y =
    ( Quantity x, Quantity y )


type alias Coord units =
    ( Quantity Int units, Quantity Int units )


toggleSet : a -> EverySet a -> EverySet a
toggleSet value set =
    if EverySet.member value set then
        EverySet.remove value set

    else
        EverySet.insert value set
