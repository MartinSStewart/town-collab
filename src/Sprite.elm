module Sprite exposing
    ( Vertex
    , asciiChars
    , charSize
    , charTexturePosition
    , charToInt
    , intToChar
    , nineSlice
    , opaque
    , outlinedText
    , rectangle
    , rectangleWithOpacity
    , shiverText
    , sprite
    , spriteWithColor
    , spriteWithTwoColors
    , spriteWithZ
    , spriteWithZAndOpacityAndUserId
    , text
    , textSize
    , textWithZAndOpacityAndUserId
    , textureWidth
    , toMesh
    , underlinedText
    )

import Array exposing (Array)
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Dict exposing (Dict)
import Effect.WebGL
import List.Nonempty exposing (Nonempty(..))
import Quantity exposing (Quantity(..))
import Random
import WebGL


type alias Vertex =
    { x : Float
    , y : Float
    , z : Float
    , texturePosition : Float
    , -- bits 0-3 is opacity
      -- bits 4-31 is userId
      opacityAndUserId : Float
    , primaryColor : Float
    , secondaryColor : Float
    }


nineSlice :
    { topLeft : Coord a
    , top : Coord a
    , topRight : Coord a
    , left : Coord a
    , center : Coord a
    , right : Coord a
    , bottomLeft : Coord a
    , bottom : Coord a
    , bottomRight : Coord a
    , cornerSize : Coord b
    , position : Coord b
    , size : Coord b
    , scale : Int
    }
    -> Colors
    -> List Vertex
nineSlice { topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight, cornerSize, position, size, scale } colors =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple size

        ( cornerW, cornerH ) =
            Coord.toTuple cornerSize

        innerWidth =
            sizeX - cornerW * 2 * scale

        innerHeight =
            sizeY - cornerH * 2 * scale
    in
    spriteWithTwoColors
        colors
        position
        (Coord.scalar scale cornerSize)
        topLeft
        (Coord.changeUnit cornerSize)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW * scale) 0) position)
            (Coord.xy innerWidth (cornerH * scale))
            top
            (Coord.xy 1 cornerH)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW * scale + innerWidth) 0) position)
            (Coord.scalar scale cornerSize)
            topRight
            (Coord.changeUnit cornerSize)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy 0 (cornerH * scale)) position)
            (Coord.xy (cornerW * scale) innerHeight)
            left
            (Coord.xy cornerW 1)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW * scale) (cornerH * scale)) position)
            (Coord.xy innerWidth innerHeight)
            center
            (Coord.xy 1 1)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy ((cornerW * scale) + innerWidth) (cornerH * scale)) position)
            (Coord.xy (cornerW * scale) innerHeight)
            right
            (Coord.xy cornerW 1)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy 0 ((cornerH * scale) + innerHeight)) position)
            (Coord.scalar scale cornerSize)
            bottomLeft
            (Coord.changeUnit cornerSize)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW * scale) ((cornerH * scale) + innerHeight)) position)
            (Coord.xy innerWidth (cornerH * scale))
            bottom
            (Coord.xy 1 cornerH)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy ((cornerW * scale) + innerWidth) ((cornerH * scale) + innerHeight)) position)
            (Coord.scalar scale cornerSize)
            bottomRight
            (Coord.changeUnit cornerSize)


rectangle : Color -> Coord unit -> Coord unit -> List Vertex
rectangle color topLeft size =
    spriteWithZ 1 color color topLeft 0 size (Coord.xy 508 28) (Coord.xy 1 1)


rectangleWithOpacity : Float -> Color -> Coord unit -> Coord unit -> List Vertex
rectangleWithOpacity opacity color topLeft size =
    spriteWithZ opacity color color topLeft 0 size (Coord.xy 508 28) (Coord.xy 1 1)


sprite : Coord unit -> Coord unit -> Coord b -> Coord b -> List Vertex
sprite position size texturePosition textureSize =
    spriteWithZ 1 Color.black Color.black position 0 size texturePosition textureSize


spriteWithColor : Color -> Coord unit -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithColor color position size texturePosition textureSize =
    spriteWithZ 1 color color position 0 size texturePosition textureSize


spriteWithTwoColors : Colors -> Coord unit -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithTwoColors { primaryColor, secondaryColor } position size texturePosition textureSize =
    spriteWithZ 1 primaryColor secondaryColor position 0 size texturePosition textureSize


textureWidth : number
textureWidth =
    2048


opaque : number
opaque =
    --0b1111
    15


spriteWithZ : Float -> Color -> Color -> Coord unit -> Float -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithZ opacity primaryColor secondaryColor ( Quantity x, Quantity y ) z ( Quantity width, Quantity height ) texturePosition textureSize =
    let
        ( tx, ty ) =
            Coord.toTuple texturePosition

        ( w, h ) =
            Coord.toTuple textureSize

        primaryColor2 =
            Color.unwrap primaryColor |> toFloat

        secondaryColor2 =
            Color.unwrap secondaryColor |> toFloat

        opacity2 =
            opacity * opaque |> round |> toFloat
    in
    [ { x = toFloat x
      , y = toFloat y
      , z = z
      , texturePosition = toFloat tx + textureWidth * toFloat ty
      , opacityAndUserId = opacity2
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { x = toFloat (x + width)
      , y = toFloat y
      , z = z
      , texturePosition = toFloat (tx + w) + textureWidth * toFloat ty
      , opacityAndUserId = opacity2
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { x = toFloat (x + width)
      , y = toFloat (y + height)
      , z = z
      , texturePosition = toFloat (tx + w) + textureWidth * toFloat (ty + h)
      , opacityAndUserId = opacity2
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { x = toFloat x
      , y = toFloat (y + height)
      , z = z
      , texturePosition = toFloat tx + textureWidth * toFloat (ty + h)
      , opacityAndUserId = opacity2
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    ]


spriteWithZAndOpacityAndUserId : Float -> Color -> Color -> Coord unit -> Float -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithZAndOpacityAndUserId opacityAndUserId primaryColor secondaryColor ( Quantity x, Quantity y ) z ( Quantity width, Quantity height ) texturePosition textureSize =
    let
        ( tx, ty ) =
            Coord.toTuple texturePosition

        ( w, h ) =
            Coord.toTuple textureSize

        primaryColor2 =
            Color.unwrap primaryColor |> toFloat

        secondaryColor2 =
            Color.unwrap secondaryColor |> toFloat
    in
    [ { x = toFloat x
      , y = toFloat y
      , z = z
      , texturePosition = toFloat tx + textureWidth * toFloat ty
      , opacityAndUserId = opacityAndUserId
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { x = toFloat (x + width)
      , y = toFloat y
      , z = z
      , texturePosition = toFloat (tx + w) + textureWidth * toFloat ty
      , opacityAndUserId = opacityAndUserId
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { x = toFloat (x + width)
      , y = toFloat (y + height)
      , z = z
      , texturePosition = toFloat (tx + w) + textureWidth * toFloat (ty + h)
      , opacityAndUserId = opacityAndUserId
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { x = toFloat x
      , y = toFloat (y + height)
      , z = z
      , texturePosition = toFloat tx + textureWidth * toFloat (ty + h)
      , opacityAndUserId = opacityAndUserId
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    ]


toMesh : List a -> WebGL.Mesh a
toMesh vertices =
    Effect.WebGL.indexedTriangles vertices (getQuadIndices vertices 0 [] |> List.reverse)


getQuadIndices : List a -> Int -> List ( Int, Int, Int ) -> List ( Int, Int, Int )
getQuadIndices list indexOffset newList =
    case list of
        _ :: _ :: _ :: _ :: rest ->
            getQuadIndices
                rest
                (indexOffset + 1)
                (( 4 * indexOffset + 3, 4 * indexOffset + 1, 4 * indexOffset )
                    :: ( 4 * indexOffset + 2, 4 * indexOffset + 1, 4 * indexOffset + 3 )
                    :: newList
                )

        _ ->
            newList


asciiChars : Nonempty Char
asciiChars =
    (List.range 32 126 ++ List.range 161 172 ++ List.range 174 255)
        |> List.map Char.fromCode
        |> (\a -> [ '░', '▒', '▓', '█' ] ++ a)
        |> (\a -> [ '│', '┤', '╡', '╢', '╖', '╕', '╣', '║', '╗', '╝', '╜', '╛', '┐', '└', '┴', '┬', '├', '─', '┼', '╞', '╟', '╚', '╔', '╩', '╦', '╠', '═', '╬', '╧', '╨', '╤', '╥', '╙', '╘', '╒', '╓', '╫', '╪', '┘', '┌' ] ++ a)
        |> List.Nonempty.fromList
        |> Maybe.withDefault (Nonempty 'a' [])


charsPerRow : number
charsPerRow =
    25


charSize : Coord unit
charSize =
    Coord.xy 10 18


charTexturePosition : Char -> Coord unit
charTexturePosition char =
    case Dict.get char charToInt of
        Just index ->
            Coord.xy
                (768 + modBy charsPerRow index * Coord.xRaw charSize)
                (index // charsPerRow |> (*) (Coord.yRaw charSize))

        Nothing ->
            Coord.xy 0 0


underlinedCharTexturePosition : Char -> Coord unit
underlinedCharTexturePosition char =
    case Dict.get char charToInt of
        Just index ->
            Coord.xy
                (768 + modBy charsPerRow index * Coord.xRaw charSize)
                (180 + (index // charsPerRow) * Coord.yRaw charSize)

        Nothing ->
            Coord.xy 0 0


charToInt : Dict Char Int
charToInt =
    List.Nonempty.toList asciiChars
        |> List.indexedMap (\index char -> ( char, index ))
        |> Dict.fromList


intToChar : Array Char
intToChar =
    List.Nonempty.toList asciiChars |> Array.fromList


text : Color -> Int -> String -> Coord unit -> List Vertex
text color charScale string position =
    let
        charSize2 : Coord unit
        charSize2 =
            Coord.multiplyTuple ( charScale, charScale ) charSize
    in
    String.toList string
        |> List.foldl
            (\char state ->
                if char == '\n' then
                    { offsetX = 0
                    , offsetY = state.offsetY + Coord.yRaw charSize2
                    , vertices = state.vertices
                    }

                else
                    { offsetX = state.offsetX + Coord.xRaw charSize2
                    , offsetY = state.offsetY
                    , vertices =
                        spriteWithColor
                            color
                            (Coord.addTuple_ ( state.offsetX, state.offsetY ) position)
                            charSize2
                            (charTexturePosition char)
                            charSize
                            ++ state.vertices
                    }
            )
            { offsetX = 0, offsetY = 0, vertices = [] }
        |> .vertices


underlinedText : Color -> Int -> String -> Coord unit -> List Vertex
underlinedText color charScale string position =
    let
        charSize2 : Coord unit
        charSize2 =
            Coord.multiplyTuple ( charScale, charScale ) charSize
    in
    String.toList string
        |> List.foldl
            (\char state ->
                if char == '\n' then
                    { offsetX = 0
                    , offsetY = state.offsetY + Coord.yRaw charSize2
                    , vertices = state.vertices
                    }

                else
                    { offsetX = state.offsetX + Coord.xRaw charSize2
                    , offsetY = state.offsetY
                    , vertices =
                        spriteWithColor
                            color
                            (Coord.addTuple_ ( state.offsetX, state.offsetY ) position)
                            charSize2
                            (underlinedCharTexturePosition char)
                            charSize
                            ++ state.vertices
                    }
            )
            { offsetX = 0, offsetY = 0, vertices = [] }
        |> .vertices


textWithZAndOpacityAndUserId : Float -> Color -> Int -> String -> Int -> Coord unit -> Float -> List Vertex
textWithZAndOpacityAndUserId opacityAndUserId color charScale string lineSpacing position z =
    let
        charSize_ =
            Coord.multiplyTuple ( charScale, charScale ) charSize
    in
    String.toList string
        |> List.foldl
            (\char state ->
                if char == '\n' then
                    { offsetX = 0
                    , offsetY = state.offsetY + Coord.yRaw charSize_ + lineSpacing
                    , vertices = state.vertices
                    }

                else
                    { offsetX = state.offsetX + Coord.xRaw charSize_
                    , offsetY = state.offsetY
                    , vertices =
                        spriteWithZAndOpacityAndUserId
                            opacityAndUserId
                            color
                            color
                            (Coord.addTuple_ ( state.offsetX, state.offsetY ) position)
                            z
                            charSize_
                            (charTexturePosition char)
                            charSize
                            ++ state.vertices
                    }
            )
            { offsetX = 0, offsetY = 0, vertices = [] }
        |> .vertices


outlinedText : Color -> Color -> Int -> String -> Coord unit -> List Vertex
outlinedText outlineColor color charScale string position =
    text outlineColor charScale string (Coord.plus (Coord.xy 0 charScale) position)
        ++ text outlineColor charScale string (Coord.plus (Coord.xy charScale 0) position)
        ++ text outlineColor charScale string (Coord.plus (Coord.xy 0 -charScale) position)
        ++ text outlineColor charScale string (Coord.plus (Coord.xy -charScale 0) position)
        ++ text color charScale string position


shiverText : Int -> Int -> String -> Coord unit -> List Vertex
shiverText frame charScale string position =
    let
        charSize_ =
            Coord.multiplyTuple ( charScale, charScale ) charSize
    in
    String.toList string
        |> List.foldl
            (\char state ->
                { offset = state.offset + Coord.xRaw charSize_
                , vertices =
                    state.vertices
                        ++ sprite
                            (Coord.addTuple_ ( state.offset, 0 ) position
                                |> Coord.plus
                                    (Random.step randomOffset (Random.initialSeed (state.offset + frame * 127))
                                        |> Tuple.first
                                    )
                            )
                            charSize_
                            (charTexturePosition char)
                            charSize
                }
            )
            { offset = 0, vertices = [] }
        |> .vertices


randomOffset : Random.Generator (Coord units)
randomOffset =
    Random.map2 Coord.xy (Random.int 0 1) (Random.int 0 1)


textSize : Int -> String -> Coord unit
textSize charScale string =
    let
        list =
            String.split "\n" string
                |> List.map
                    (\text2 ->
                        Coord.xy (String.length text2) 1
                    )
    in
    Coord.xy
        (List.map Coord.xRaw list |> List.maximum |> Maybe.withDefault 0)
        (List.map Coord.yRaw list |> List.sum |> max 1)
        |> Coord.multiply charSize
        |> Coord.scalar charScale
