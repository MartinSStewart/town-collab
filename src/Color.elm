module Color exposing (Color, black, blue, green, red, rgb, toInt, toVec3, white)

import Bitwise
import Math.Vector3 as Vec3 exposing (Vec3)


type Color
    = Color Int


rgb : Int -> Int -> Int -> Color
rgb red2 green2 blue2 =
    Bitwise.shiftLeftBy 16 (clamp 0 255 red2)
        + Bitwise.shiftLeftBy 8 (clamp 0 255 green2)
        + clamp 0 255 blue2
        |> Color


red : Color -> Int
red (Color color) =
    Bitwise.shiftRightZfBy 16 color |> Bitwise.and 255


green : Color -> Int
green (Color color) =
    Bitwise.shiftRightZfBy 8 color |> Bitwise.and 255


blue : Color -> Int
blue (Color color) =
    Bitwise.and 255 color


black : Color
black =
    rgb 0 0 0


white : Color
white =
    rgb 255 255 255


toInt : Color -> Int
toInt (Color color) =
    color


toVec3 : Color -> Vec3
toVec3 color =
    Vec3.vec3
        (red color |> toFloat |> (*) (1 / 255))
        (green color |> toFloat |> (*) (1 / 255))
        (blue color |> toFloat |> (*) (1 / 255))
