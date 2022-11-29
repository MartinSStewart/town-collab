module Sprite exposing
    ( charSize
    , getIndices
    , getQuadIndices
    , nineSlice
    , shiverText
    , sprite
    , spriteWithZ
    , text
    , textSize
    , toMesh
    )

import Coord exposing (Coord)
import List.Extra as List
import Math.Vector3 as Vec3
import Quantity exposing (Quantity(..))
import Random
import Shaders exposing (Vertex)
import Tile
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
    , cornerSize : Coord a
    , position : Coord b
    , size : Coord b
    }
    -> List Vertex
nineSlice { topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight, cornerSize, position, size } =
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
    sprite (Coord.toTuple position) cornerSize (Coord.toTuple topLeft) (Coord.toTuple cornerSize)
        ++ sprite
            (Coord.plus (Coord.xy cornerW 0) position |> Coord.toTuple)
            (Coord.xy innerWidth cornerH)
            (Coord.toTuple top)
            ( 1, cornerH )
        ++ sprite
            (Coord.plus (Coord.xy (cornerW + innerWidth) 0) position |> Coord.toTuple)
            cornerSize
            (Coord.toTuple topRight)
            (Coord.toTuple cornerSize)
        ++ sprite
            (Coord.plus (Coord.xy 0 cornerH) position |> Coord.toTuple)
            (Coord.xy cornerW innerHeight)
            (Coord.toTuple left)
            ( cornerW, 1 )
        ++ sprite
            (Coord.plus (Coord.xy cornerW cornerH) position |> Coord.toTuple)
            (Coord.xy innerWidth innerHeight)
            (Coord.toTuple center)
            ( 1, 1 )
        ++ sprite
            (Coord.plus (Coord.xy (cornerW + innerWidth) cornerH) position |> Coord.toTuple)
            (Coord.xy cornerW innerHeight)
            (Coord.toTuple right)
            ( cornerW, 1 )
        ++ sprite
            (Coord.plus (Coord.xy 0 (cornerH + innerHeight)) position |> Coord.toTuple)
            cornerSize
            (Coord.toTuple bottomLeft)
            (Coord.toTuple cornerSize)
        ++ sprite
            (Coord.plus (Coord.xy cornerW (cornerH + innerHeight)) position |> Coord.toTuple)
            (Coord.xy innerWidth cornerH)
            (Coord.toTuple bottom)
            ( 1, cornerH )
        ++ sprite
            (Coord.plus (Coord.xy (cornerW + innerWidth) (cornerH + innerHeight)) position |> Coord.toTuple)
            cornerSize
            (Coord.toTuple bottomRight)
            (Coord.toTuple cornerSize)


sprite : ( Int, Int ) -> Coord unit -> ( Int, Int ) -> ( Int, Int ) -> List Vertex
sprite position size texturePosition textureSize =
    spriteWithZ position 0 size texturePosition textureSize


spriteWithZ : ( Int, Int ) -> Float -> Coord unit -> ( Int, Int ) -> ( Int, Int ) -> List Vertex
spriteWithZ ( x, y ) z ( Quantity width, Quantity height ) texturePosition textureSize =
    let
        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels texturePosition textureSize
    in
    [ { position = Vec3.vec3 (toFloat x) (toFloat y) z, texturePosition = topLeft, opacity = 1 }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat y) z, texturePosition = topRight, opacity = 1 }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat (y + height)) z, texturePosition = bottomRight, opacity = 1 }
    , { position = Vec3.vec3 (toFloat x) (toFloat (y + height)) z, texturePosition = bottomLeft, opacity = 1 }
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


asciiChars : List Char
asciiChars =
    (List.range 32 126 ++ List.range 161 172 ++ List.range 174 255)
        |> List.map Char.fromCode
        |> (++) [ '░', '▒', '▓', '█' ]
        |> (++) [ '│', '┤', '╡', '╢', '╖', '╕', '╣', '║', '╗', '╝', '╜', '╛', '┐', '└', '┴', '┬', '├', '─', '┼', '╞', '╟', '╚', '╔', '╩', '╦', '╠', '═', '╬', '╧', '╨', '╤', '╥', '╙', '╘', '╒', '╓', '╫', '╪', '┘', '┌' ]


charsPerRow : number
charsPerRow =
    25


charSize : Coord unit
charSize =
    Coord.xy 10 18


charTexturePosition : Char -> Coord unit
charTexturePosition char =
    case List.findIndex ((==) char) asciiChars of
        Just index ->
            Coord.xy
                (768 + modBy charsPerRow index * Coord.xRaw charSize)
                (index // charsPerRow |> (*) (Coord.yRaw charSize))

        Nothing ->
            Coord.xy 0 0


text : Int -> String -> Coord unit -> List Vertex
text charScale string position =
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
                        state.vertices
                            ++ sprite
                                (Coord.addTuple_ ( state.offsetX, state.offsetY ) position |> Coord.toTuple)
                                charSize_
                                (charTexturePosition char |> Coord.toTuple)
                                (Coord.toTuple charSize)
                    }
            )
            { offsetX = 0, offsetY = 0, vertices = [] }
        |> .vertices


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
                                |> Coord.toTuple
                            )
                            charSize_
                            (charTexturePosition char |> Coord.toTuple)
                            (Coord.toTuple charSize)
                }
            )
            { offset = 0, vertices = [] }
        |> .vertices


randomOffset : Random.Generator (Coord units)
randomOffset =
    Random.map2 Coord.xy (Random.int 0 1) (Random.int 0 1)


textSize : Int -> String -> Coord unit
textSize charScale string =
    Coord.xy (String.length string) 1 |> Coord.multiplyTuple (Coord.toTuple charSize)
