module Sprite exposing
    ( asciiChars
    , charSize
    , charTexturePosition
    , getIndices
    , getQuadIndices
    , nineSlice
    , outlinedText
    , rectangle
    , shiverText
    , sprite
    , spriteWithColor
    , spriteWithTwoColors
    , spriteWithZ
    , text
    , textSize
    , toMesh
    )

import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Dict exposing (Dict)
import List.Nonempty exposing (Nonempty(..))
import Math.Vector2
import Math.Vector3 as Vec3
import Quantity exposing (Quantity(..))
import Random
import Shaders exposing (Vertex)
import WebGL


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
    }
    -> Colors
    -> List Vertex
nineSlice { topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight, cornerSize, position, size } colors =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple size

        ( cornerW, cornerH ) =
            Coord.toTuple cornerSize

        innerWidth =
            sizeX - cornerW * 2

        innerHeight =
            sizeY - cornerH * 2
    in
    spriteWithTwoColors
        colors
        position
        cornerSize
        topLeft
        (Coord.changeUnit cornerSize)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy cornerW 0) position)
            (Coord.xy innerWidth cornerH)
            top
            (Coord.xy 1 cornerH)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW + innerWidth) 0) position)
            cornerSize
            topRight
            (Coord.changeUnit cornerSize)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy 0 cornerH) position)
            (Coord.xy cornerW innerHeight)
            left
            (Coord.xy cornerW 1)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy cornerW cornerH) position)
            (Coord.xy innerWidth innerHeight)
            center
            (Coord.xy 1 1)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW + innerWidth) cornerH) position)
            (Coord.xy cornerW innerHeight)
            right
            (Coord.xy cornerW 1)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy 0 (cornerH + innerHeight)) position)
            cornerSize
            bottomLeft
            (Coord.changeUnit cornerSize)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy cornerW (cornerH + innerHeight)) position)
            (Coord.xy innerWidth cornerH)
            bottom
            (Coord.xy 1 cornerH)
        ++ spriteWithTwoColors
            colors
            (Coord.plus (Coord.xy (cornerW + innerWidth) (cornerH + innerHeight)) position)
            cornerSize
            bottomRight
            (Coord.changeUnit cornerSize)


rectangle : Color -> Coord unit -> Coord unit -> List Vertex
rectangle color topLeft size =
    spriteWithColor color topLeft size (Coord.xy 508 28) (Coord.xy 1 1)


sprite : Coord unit -> Coord unit -> Coord b -> Coord b -> List Vertex
sprite position size texturePosition textureSize =
    spriteWithZ Color.black Color.black position 0 size texturePosition textureSize


spriteWithColor : Color -> Coord unit -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithColor color position size texturePosition textureSize =
    spriteWithZ color color position 0 size texturePosition textureSize


spriteWithTwoColors : Colors -> Coord unit -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithTwoColors { primaryColor, secondaryColor } position size texturePosition textureSize =
    spriteWithZ primaryColor secondaryColor position 0 size texturePosition textureSize


spriteWithZ : Color -> Color -> Coord unit -> Float -> Coord unit -> Coord b -> Coord b -> List Vertex
spriteWithZ primaryColor secondaryColor ( Quantity x, Quantity y ) z ( Quantity width, Quantity height ) texturePosition textureSize =
    let
        ( tx, ty ) =
            Coord.toTuple texturePosition

        ( w, h ) =
            Coord.toTuple textureSize

        primaryColor2 =
            Color.toVec3 primaryColor

        secondaryColor2 =
            Color.toVec3 secondaryColor
    in
    [ { position = Vec3.vec3 (toFloat x) (toFloat y) z
      , texturePosition = Math.Vector2.vec2 (toFloat tx) (toFloat ty)
      , opacity = 1
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat y) z
      , texturePosition = Math.Vector2.vec2 (toFloat (tx + w)) (toFloat ty)
      , opacity = 1
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat (y + height)) z
      , texturePosition = Math.Vector2.vec2 (toFloat (tx + w)) (toFloat (ty + h))
      , opacity = 1
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    , { position = Vec3.vec3 (toFloat x) (toFloat (y + height)) z
      , texturePosition = Math.Vector2.vec2 (toFloat tx) (toFloat (ty + h))
      , opacity = 1
      , primaryColor = primaryColor2
      , secondaryColor = secondaryColor2
      }
    ]


getQuadIndices : List a -> List ( Int, Int, Int )
getQuadIndices list =
    List.range 0 (List.length list // 4 - 1) |> List.concatMap getIndices


getIndices : number -> List ( number, number, number )
getIndices indexOffset =
    [ ( 4 * indexOffset + 3, 4 * indexOffset + 1, 4 * indexOffset )
    , ( 4 * indexOffset + 2, 4 * indexOffset + 1, 4 * indexOffset + 3 )
    ]


toMesh : List a -> WebGL.Mesh a
toMesh vertices =
    Shaders.indexedTriangles vertices (getQuadIndices vertices)


asciiChars : Nonempty Char
asciiChars =
    (List.range 32 126 ++ List.range 161 172 ++ List.range 174 255)
        |> List.map Char.fromCode
        |> (++) [ '░', '▒', '▓', '█' ]
        |> (++) [ '│', '┤', '╡', '╢', '╖', '╕', '╣', '║', '╗', '╝', '╜', '╛', '┐', '└', '┴', '┬', '├', '─', '┼', '╞', '╟', '╚', '╔', '╩', '╦', '╠', '═', '╬', '╧', '╨', '╤', '╥', '╙', '╘', '╒', '╓', '╫', '╪', '┘', '┌' ]
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
    case Dict.get char charTexturePositionHelper of
        Just index ->
            Coord.xy
                (768 + modBy charsPerRow index * Coord.xRaw charSize)
                (index // charsPerRow |> (*) (Coord.yRaw charSize))

        Nothing ->
            Coord.xy 0 0


charTexturePositionHelper : Dict Char Int
charTexturePositionHelper =
    List.Nonempty.toList asciiChars
        |> List.indexedMap (\index char -> ( char, index ))
        |> Dict.fromList


text : Color -> Int -> String -> Coord unit -> List Vertex
text color charScale string position =
    let
        charSize_ =
            Coord.multiplyTuple ( charScale, charScale ) charSize
    in
    String.toList string
        |> List.foldl
            (\char state ->
                if char == '\n' then
                    { offsetX = 0
                    , offsetY = state.offsetY + Coord.yRaw charSize_
                    , vertices = state.vertices
                    }

                else
                    { offsetX = state.offsetX + Coord.xRaw charSize_
                    , offsetY = state.offsetY
                    , vertices =
                        spriteWithColor
                            color
                            (Coord.addTuple_ ( state.offsetX, state.offsetY ) position)
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
        |> Coord.multiply (Coord.xy charScale charScale)
