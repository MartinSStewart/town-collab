module Ascii exposing (Ascii(..), asciiChars, asciis, charsPerRow, default, fromChar, fromInt, image, intensity, size, textureData, textureHeight, texturePosition, texturePositionInt, textureWidth, toChar, toInt)

import Array exposing (Array)
import Base64
import Bounds exposing (Bounds)
import Dict exposing (Dict)
import Helper exposing (Coord)
import Image exposing (Image)
import List.Extra as List
import List.Nonempty exposing (Nonempty)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


asciiChars : List Char
asciiChars =
    (List.range 32 126 ++ List.range 161 172 ++ List.range 174 255)
        |> List.map Char.fromCode
        |> (++) [ '░', '▒', '▓', '█' ]
        |> (++) [ '│', '┤', '╡', '╢', '╖', '╕', '╣', '║', '╗', '╝', '╜', '╛', '┐', '└', '┴', '┬', '├', '─', '┼', '╞', '╟', '╚', '╔', '╩', '╦', '╠', '═', '╬', '╧', '╨', '╤', '╥', '╙', '╘', '╒', '╓', '╫', '╪', '┘', '┌' ]


asciis : Nonempty Ascii
asciis =
    List.filterMap fromChar asciiChars
        |> List.Nonempty.fromList
        |> Maybe.withDefault (List.Nonempty.fromElement default)


charToAscii : Dict Char Ascii
charToAscii =
    asciiChars |> List.indexedMap (\index char -> ( char, Ascii index )) |> Dict.fromList


asciiToChar : Dict Int Char
asciiToChar =
    asciiChars |> List.indexedMap (\index char -> ( index, char )) |> Dict.fromList


fromChar : Char -> Maybe Ascii
fromChar char =
    Dict.get char charToAscii


toChar : Ascii -> Char
toChar (Ascii ascii_) =
    Dict.get ascii_ asciiToChar |> Maybe.withDefault ' '


asciiCharCount : Int
asciiCharCount =
    List.length asciiChars


size : ( Quantity number Pixels, Quantity number Pixels )
size =
    ( Pixels.pixels 10, Pixels.pixels 18 )


default : Ascii
default =
    asciiChars |> List.findIndex ((==) ' ') |> Maybe.withDefault 0 |> Ascii


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
    = Ascii Int


toInt : Ascii -> Int
toInt (Ascii ascii) =
    ascii


fromInt : Int -> Maybe Ascii
fromInt value =
    if value >= 0 && value < asciiCharCount then
        Ascii value |> Just

    else
        Nothing


texturePosition : Ascii -> { topLeft : Vec2, bottomRight : Vec2 }
texturePosition (Ascii ascii_) =
    let
        ( Quantity.Quantity w, Quantity.Quantity h ) =
            size
    in
    { topLeft =
        Math.Vector2.vec2
            (modBy charsPerRow ascii_ |> (*) w |> toFloat |> (\a -> a / Pixels.inPixels textureWidth))
            (ascii_ // charsPerRow |> (*) h |> toFloat |> (\a -> a / Pixels.inPixels textureHeight))
    , bottomRight =
        Math.Vector2.vec2
            (modBy charsPerRow ascii_ |> (+) 1 |> (*) w |> toFloat |> (\a -> a / Pixels.inPixels textureWidth))
            (ascii_ // charsPerRow |> (+) 1 |> (*) h |> toFloat |> (\a -> a / Pixels.inPixels textureHeight))
    }


texturePositionInt : Ascii -> Bounds Pixels
texturePositionInt (Ascii ascii_) =
    let
        ( Quantity.Quantity w, Quantity.Quantity h ) =
            size
    in
    Bounds.bounds
        (Helper.fromRawCoord
            ( w * modBy charsPerRow ascii_
            , h * (ascii_ // charsPerRow)
            )
        )
        (Helper.fromRawCoord
            ( w * (modBy charsPerRow ascii_ + 1)
            , h * ((ascii_ // charsPerRow) + 1)
            )
        )


{-| Generated with <http://localhost:8000/tools/AsciiItensity.elm>
-}
intensity : Ascii -> Int
intensity ascii =
    case ascii of
        Ascii 232 ->
            26

        Ascii 231 ->
            31

        Ascii 230 ->
            27

        Ascii 229 ->
            24

        Ascii 228 ->
            25

        Ascii 227 ->
            23

        Ascii 226 ->
            23

        Ascii 225 ->
            24

        Ascii 224 ->
            9

        Ascii 223 ->
            18

        Ascii 222 ->
            22

        Ascii 221 ->
            21

        Ascii 220 ->
            19

        Ascii 219 ->
            19

        Ascii 218 ->
            28

        Ascii 217 ->
            30

        Ascii 216 ->
            17

        Ascii 215 ->
            20

        Ascii 214 ->
            18

        Ascii 213 ->
            18

        Ascii 212 ->
            23

        Ascii 211 ->
            26

        Ascii 210 ->
            24

        Ascii 209 ->
            24

        Ascii 208 ->
            25

        Ascii 207 ->
            34

        Ascii 206 ->
            35

        Ascii 205 ->
            26

        Ascii 204 ->
            30

        Ascii 203 ->
            29

        Ascii 202 ->
            27

        Ascii 201 ->
            27

        Ascii 200 ->
            25

        Ascii 199 ->
            26

        Ascii 198 ->
            24

        Ascii 197 ->
            27

        Ascii 196 ->
            29

        Ascii 195 ->
            27

        Ascii 194 ->
            27

        Ascii 193 ->
            30

        Ascii 192 ->
            12

        Ascii 191 ->
            24

        Ascii 190 ->
            28

        Ascii 189 ->
            27

        Ascii 188 ->
            25

        Ascii 187 ->
            25

        Ascii 186 ->
            38

        Ascii 185 ->
            32

        Ascii 184 ->
            23

        Ascii 183 ->
            26

        Ascii 182 ->
            24

        Ascii 181 ->
            24

        Ascii 180 ->
            32

        Ascii 179 ->
            35

        Ascii 178 ->
            33

        Ascii 177 ->
            33

        Ascii 176 ->
            28

        Ascii 175 ->
            38

        Ascii 174 ->
            35

        Ascii 173 ->
            30

        Ascii 172 ->
            34

        Ascii 171 ->
            33

        Ascii 170 ->
            31

        Ascii 169 ->
            31

        Ascii 168 ->
            16

        Ascii 167 ->
            33

        Ascii 166 ->
            30

        Ascii 165 ->
            35

        Ascii 164 ->
            16

        Ascii 163 ->
            12

        Ascii 162 ->
            11

        Ascii 161 ->
            7

        Ascii 160 ->
            4

        Ascii 159 ->
            37

        Ascii 158 ->
            24

        Ascii 157 ->
            3

        Ascii 156 ->
            12

        Ascii 155 ->
            11

        Ascii 154 ->
            22

        Ascii 153 ->
            8

        Ascii 152 ->
            10

        Ascii 151 ->
            46

        Ascii 150 ->
            18

        Ascii 149 ->
            16

        Ascii 148 ->
            15

        Ascii 147 ->
            38

        Ascii 146 ->
            8

        Ascii 145 ->
            38

        Ascii 144 ->
            10

        Ascii 143 ->
            33

        Ascii 142 ->
            12

        Ascii 141 ->
            21

        Ascii 140 ->
            17

        Ascii 139 ->
            12

        Ascii 138 ->
            7

        Ascii 137 ->
            11

        Ascii 136 ->
            12

        Ascii 135 ->
            11

        Ascii 134 ->
            21

        Ascii 133 ->
            24

        Ascii 132 ->
            24

        Ascii 131 ->
            25

        Ascii 130 ->
            19

        Ascii 129 ->
            20

        Ascii 128 ->
            19

        Ascii 127 ->
            24

        Ascii 126 ->
            17

        Ascii 125 ->
            26

        Ascii 124 ->
            26

        Ascii 123 ->
            16

        Ascii 122 ->
            22

        Ascii 121 ->
            28

        Ascii 120 ->
            20

        Ascii 119 ->
            25

        Ascii 118 ->
            20

        Ascii 117 ->
            17

        Ascii 116 ->
            25

        Ascii 115 ->
            28

        Ascii 114 ->
            24

        Ascii 113 ->
            21

        Ascii 112 ->
            25

        Ascii 111 ->
            18

        Ascii 110 ->
            25

        Ascii 109 ->
            24

        Ascii 108 ->
            3

        Ascii 107 ->
            10

        Ascii 106 ->
            9

        Ascii 105 ->
            16

        Ascii 104 ->
            12

        Ascii 103 ->
            16

        Ascii 102 ->
            22

        Ascii 101 ->
            21

        Ascii 100 ->
            26

        Ascii 99 ->
            34

        Ascii 98 ->
            23

        Ascii 97 ->
            25

        Ascii 96 ->
            25

        Ascii 95 ->
            24

        Ascii 94 ->
            28

        Ascii 93 ->
            28

        Ascii 92 ->
            26

        Ascii 91 ->
            22

        Ascii 90 ->
            32

        Ascii 89 ->
            37

        Ascii 88 ->
            25

        Ascii 87 ->
            28

        Ascii 86 ->
            20

        Ascii 85 ->
            21

        Ascii 84 ->
            30

        Ascii 83 ->
            26

        Ascii 82 ->
            26

        Ascii 81 ->
            30

        Ascii 80 ->
            26

        Ascii 79 ->
            21

        Ascii 78 ->
            29

        Ascii 77 ->
            27

        Ascii 76 ->
            32

        Ascii 75 ->
            15

        Ascii 74 ->
            14

        Ascii 73 ->
            16

        Ascii 72 ->
            14

        Ascii 71 ->
            10

        Ascii 70 ->
            8

        Ascii 69 ->
            23

        Ascii 68 ->
            26

        Ascii 67 ->
            17

        Ascii 66 ->
            26

        Ascii 65 ->
            23

        Ascii 64 ->
            23

        Ascii 63 ->
            22

        Ascii 62 ->
            24

        Ascii 61 ->
            19

        Ascii 60 ->
            24

        Ascii 59 ->
            12

        Ascii 58 ->
            4

        Ascii 57 ->
            7

        Ascii 56 ->
            7

        Ascii 55 ->
            15

        Ascii 54 ->
            14

        Ascii 53 ->
            12

        Ascii 52 ->
            12

        Ascii 51 ->
            9

        Ascii 50 ->
            20

        Ascii 49 ->
            22

        Ascii 48 ->
            25

        Ascii 47 ->
            36

        Ascii 46 ->
            12

        Ascii 45 ->
            13

        Ascii 44 ->
            0

        Ascii 43 ->
            180

        Ascii 42 ->
            153

        Ascii 41 ->
            99

        Ascii 40 ->
            54

        Ascii 39 ->
            14

        Ascii 38 ->
            14

        Ascii 37 ->
            37

        Ascii 36 ->
            46

        Ascii 35 ->
            24

        Ascii 34 ->
            20

        Ascii 33 ->
            21

        Ascii 32 ->
            25

        Ascii 31 ->
            26

        Ascii 30 ->
            28

        Ascii 29 ->
            30

        Ascii 28 ->
            29

        Ascii 27 ->
            50

        Ascii 26 ->
            22

        Ascii 25 ->
            45

        Ascii 24 ->
            33

        Ascii 23 ->
            37

        Ascii 22 ->
            30

        Ascii 21 ->
            30

        Ascii 20 ->
            40

        Ascii 19 ->
            28

        Ascii 18 ->
            37

        Ascii 17 ->
            17

        Ascii 16 ->
            29

        Ascii 15 ->
            21

        Ascii 14 ->
            20

        Ascii 13 ->
            17

        Ascii 12 ->
            14

        Ascii 11 ->
            22

        Ascii 10 ->
            26

        Ascii 9 ->
            29

        Ascii 8 ->
            29

        Ascii 7 ->
            40

        Ascii 6 ->
            41

        Ascii 5 ->
            20

        Ascii 4 ->
            26

        Ascii 3 ->
            41

        Ascii 2 ->
            29

        Ascii 1 ->
            24

        Ascii 0 ->
            21

        _ ->
            0
