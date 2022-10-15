module Ascii exposing
    ( Ascii(..)
    , charsPerRow
    , fromChar
    , image
    , size
    , textureData
    , textureHeight
    , texturePosition
    , texturePositionInt
    , textureWidth
    )

import Array exposing (Array)
import Base64
import Bounds exposing (Bounds)
import Dict exposing (Dict)
import Helper exposing (Coord)
import Image exposing (Image)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


charToAscii : Dict Char Ascii
charToAscii =
    Dict.fromList
        [ ( 'h', House )
        , ( 'r', RailHorizontal )
        , ( 'R', RailVertical )
        ]


fromChar : Char -> Maybe Ascii
fromChar char =
    Dict.get char charToAscii


size : ( Quantity number Pixels, Quantity number Pixels )
size =
    ( Pixels.pixels 18, Pixels.pixels 18 )


charsPerRow : number
charsPerRow =
    25


textureData : String
textureData =
    "data:image/png;base64,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"


image : Array (Array Image.Pixel)
image =
    String.dropLeft (String.length "data:image/png;base64,") textureData
        |> Base64.toBytes
        |> Maybe.andThen Image.decode
        |> Maybe.withDefault (Image.fromList2d [])
        |> Image.toArray2d
        |> Array.map
            (Array.map
                (\pixel ->
                    if pixel + 1 == 0 then
                        255

                    else
                        -1
                )
            )


textureWidth : Quantity number Pixels
textureWidth =
    Pixels.pixels 256


textureHeight : Quantity number Pixels
textureHeight =
    Pixels.pixels 512


type Ascii
    = House
    | RailHorizontal
    | RailVertical


texturePosition : Ascii -> { topLeft : Vec2, bottomRight : Vec2 }
texturePosition ascii =
    let
        ( Quantity.Quantity tileW, Quantity.Quantity tileH ) =
            size

        ( ( x, y ), ( w, h ) ) =
            data ascii
    in
    { topLeft = Math.Vector2.vec2 (x * tileW) (y * tileH)
    , bottomRight = Math.Vector2.vec2 ((x + w) * tileW) ((y + h) * tileH)
    }


data ascii =
    case ascii of
        House ->
            ( ( 0, 1 ), ( 3, 2 ) )

        RailHorizontal ->
            ( ( 0, 0 ), ( 1, 1 ) )

        RailVertical ->
            ( ( 1, 0 ), ( 1, 1 ) )


texturePositionInt : Ascii -> Bounds Pixels
texturePositionInt ascii =
    let
        ( Quantity.Quantity tileW, Quantity.Quantity tileH ) =
            size

        ( ( x, y ), ( w, h ) ) =
            data ascii
    in
    Bounds.bounds
        (Helper.fromRawCoord
            ( x * tileW
            , y * tileH
            )
        )
        (Helper.fromRawCoord
            ( (x + w) * tileW
            , (y + h) * tileH
            )
        )
