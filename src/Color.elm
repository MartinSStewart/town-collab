module Color exposing
    ( Color(..)
    , Colors
    , adminReportColor
    , black
    , errorColor
    , fillColor
    , fillColor2
    , fillColor3
    , fromHexCode
    , getBlue
    , getGreen
    , getRed
    , highlightColor
    , localReportColor
    , outlineColor
    , rgb255
    , toHexCode
    , toInt
    , toVec3
    , white
    )

import Bitwise
import Hex
import Math.Vector3 as Vec3 exposing (Vec3)


type alias Colors =
    { primaryColor : Color, secondaryColor : Color }


type Color
    = Color Int


rgb255 : Int -> Int -> Int -> Color
rgb255 red2 green2 blue2 =
    Bitwise.shiftLeftBy 16 (clamp 0 255 red2)
        + Bitwise.shiftLeftBy 8 (clamp 0 255 green2)
        + clamp 0 255 blue2
        |> Color


getRed : Color -> Int
getRed (Color color) =
    Bitwise.shiftRightZfBy 16 color |> Bitwise.and 255


getGreen : Color -> Int
getGreen (Color color) =
    Bitwise.shiftRightZfBy 8 color |> Bitwise.and 255


getBlue : Color -> Int
getBlue (Color color) =
    Bitwise.and 255 color


black : Color
black =
    rgb255 0 0 0


white : Color
white =
    rgb255 255 255 255


errorColor : Color
errorColor =
    rgb255 185 0 0


adminReportColor : Color
adminReportColor =
    rgb255 0 0 255


localReportColor : Color
localReportColor =
    rgb255 255 0 0


outlineColor : Color
outlineColor =
    rgb255 157 143 134


fillColor : Color
fillColor =
    rgb255 220 210 199


fillColor2 : Color
fillColor2 =
    rgb255 199 185 175


fillColor3 : Color
fillColor3 =
    rgb255 213 202 192


highlightColor : Color
highlightColor =
    rgb255 251 241 233


toInt : Color -> Int
toInt (Color color) =
    color


toVec3 : Color -> Vec3
toVec3 color =
    Vec3.vec3
        (getRed color |> toFloat |> (*) (1 / 255))
        (getGreen color |> toFloat |> (*) (1 / 255))
        (getBlue color |> toFloat |> (*) (1 / 255))


fromHexCode : String -> Maybe Color
fromHexCode text =
    case ( String.length text, Hex.fromString (String.toLower text) ) of
        ( 6, Ok value ) ->
            Color value |> Just

        _ ->
            Nothing


toHexCode : Color -> String
toHexCode (Color color) =
    Hex.toString color |> String.padLeft 6 '0'
