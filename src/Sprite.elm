module Sprite exposing (charSize, getIndices, getQuadIndices, spriteMesh, spriteMeshWithZ, textMesh, toMesh)

import Coord exposing (Coord)
import List.Extra as List
import Math.Vector3 as Vec3
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Tile
import WebGL


spriteMesh : ( Int, Int ) -> Coord unit -> ( Int, Int ) -> ( Int, Int ) -> List Vertex
spriteMesh position size texturePosition textureSize =
    spriteMeshWithZ position 0 size texturePosition textureSize


spriteMeshWithZ : ( Int, Int ) -> Float -> Coord unit -> ( Int, Int ) -> ( Int, Int ) -> List Vertex
spriteMeshWithZ ( x, y ) z ( Quantity width, Quantity height ) texturePosition textureSize =
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
    WebGL.indexedTriangles vertices (getQuadIndices vertices)


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


textMesh : Int -> String -> Coord unit -> List Vertex
textMesh charScale string position =
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
                        ++ spriteMesh
                            (Coord.addTuple_ ( state.offset, 0 ) position |> Coord.toTuple)
                            charSize_
                            (charTexturePosition char |> Coord.toTuple)
                            (Coord.toTuple charSize)
                }
            )
            { offset = 0, vertices = [] }
        |> .vertices
