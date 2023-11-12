module Coord exposing
    ( Coord
    , RawCellCoord
    , addTuple_
    , changeUnit
    , clamp
    , divide
    , floorPoint
    , maxComponent
    , maxTuple
    , maximum
    , minimum
    , minus
    , multiply
    , multiplyTuple
    , multiplyTuple_
    , origin
    , plus
    , roundPoint
    , roundVector
    , scalar
    , toPoint2d
    , toTuple
    , toVec2
    , toVector2d
    , translateMat4
    , tuple
    , xOnly
    , xRaw
    , xy
    , yOnly
    , yRaw
    )

import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Vector2d exposing (Vector2d)


type alias RawCellCoord =
    ( Int, Int )


translateMat4 : Coord unit -> Mat4 -> Mat4
translateMat4 ( Quantity x_, Quantity y_ ) =
    Mat4.translate3 (toFloat x_) (toFloat y_) 0


origin : Coord units
origin =
    tuple ( 0, 0 )


plus : Coord unit -> Coord unit -> Coord unit
plus ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.plus x0 x1, Quantity.plus y0 y1 )


changeUnit : Coord a -> Coord b
changeUnit ( Quantity x_, Quantity y_ ) =
    ( Quantity x_, Quantity y_ )


addTuple_ : ( Int, Int ) -> Coord unit -> Coord unit
addTuple_ ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.plus (Quantity x0) x1, Quantity.plus (Quantity y0) y1 )


minus : Coord unit -> Coord unit -> Coord unit
minus ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.minus x0 x1, Quantity.minus y0 y1 )


multiplyTuple : ( Int, Int ) -> Coord unit -> Coord unit
multiplyTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.multiplyBy x0 x1, Quantity.multiplyBy y0 y1 )


multiplyTuple_ : ( Float, Float ) -> Coord unit -> Coord unit
multiplyTuple_ ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.toFloatQuantity x1 |> Quantity.multiplyBy x0 |> Quantity.round
    , Quantity.toFloatQuantity y1 |> Quantity.multiplyBy y0 |> Quantity.round
    )


multiply : Coord unit -> Coord unit -> Coord unit
multiply ( Quantity x0, Quantity y0 ) ( x1, y1 ) =
    ( Quantity.multiplyBy x0 x1, Quantity.multiplyBy y0 y1 )


scalar : Int -> Coord unit -> Coord unit
scalar a ( x1, y1 ) =
    ( Quantity.multiplyBy a x1, Quantity.multiplyBy a y1 )


divide : Coord unit -> Coord unit -> Coord unit
divide ( Quantity x0, Quantity y0 ) ( Quantity x1, Quantity y1 ) =
    ( x1 // x0 |> Quantity, y1 // y0 |> Quantity )


minimum : Coord unit -> Coord unit -> Coord unit
minimum ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.min x0 x1, Quantity.min y0 y1 )


maximum : Coord unit -> Coord unit -> Coord unit
maximum ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.max x0 x1, Quantity.max y0 y1 )


clamp : Coord unit -> Coord unit -> Coord unit -> Coord unit
clamp ( minX, minY ) ( maxX, maxY ) ( x0, y0 ) =
    ( Quantity.clamp minX maxX x0, Quantity.clamp minY maxY y0 )


maxTuple : Coord unit -> Coord unit -> Coord unit
maxTuple ( x0, y0 ) ( x1, y1 ) =
    ( Quantity.max x0 x1, Quantity.max y0 y1 )


toVec2 : Coord units -> Vec2
toVec2 ( Quantity x_, Quantity y_ ) =
    Math.Vector2.vec2 (toFloat x_) (toFloat y_)


toPoint2d : Coord units -> Point2d units coordinate
toPoint2d ( x_, y_ ) =
    Point2d.xy (Quantity.toFloatQuantity x_) (Quantity.toFloatQuantity y_)


roundPoint : Point2d units coordinate -> Coord units
roundPoint point2d =
    let
        point =
            Point2d.unwrap point2d
    in
    tuple ( round point.x, round point.y )


roundVector : Vector2d units coordinate -> Coord units
roundVector point2d =
    let
        point =
            Vector2d.unwrap point2d
    in
    tuple ( round point.x, round point.y )


floorPoint : Point2d units coordinate -> Coord units
floorPoint point2d =
    let
        point =
            Point2d.unwrap point2d
    in
    tuple ( floor point.x, floor point.y )


toVector2d : Coord units -> Vector2d units coordinate
toVector2d ( x_, y_ ) =
    Vector2d.xy (Quantity.toFloatQuantity x_) (Quantity.toFloatQuantity y_)


toTuple : Coord units -> ( Int, Int )
toTuple ( Quantity x_, Quantity y_ ) =
    ( x_, y_ )


tuple : ( Int, Int ) -> Coord units
tuple ( x_, y_ ) =
    ( Quantity x_, Quantity y_ )


xy : Int -> Int -> Coord units
xy x_ y_ =
    ( Quantity x_, Quantity y_ )


xRaw : Coord units -> Int
xRaw ( Quantity x_, _ ) =
    x_


yRaw : Coord units -> Int
yRaw ( _, Quantity y_ ) =
    y_


type alias Coord units =
    ( Quantity Int units, Quantity Int units )


xOnly : Coord a -> Coord a
xOnly ( Quantity x_, _ ) =
    ( Quantity x_, Quantity 0 )


yOnly : Coord a -> Coord a
yOnly ( _, Quantity y_ ) =
    ( Quantity 0, Quantity y_ )


maxComponent : Coord a -> Quantity Int a
maxComponent ( x2, y2 ) =
    Quantity.max x2 y2
