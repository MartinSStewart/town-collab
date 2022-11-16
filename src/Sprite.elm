module Sprite exposing (getIndices, getQuadIndices, spriteMesh, spriteMeshWithZ)

import Coord exposing (Coord)
import Math.Vector3 as Vec3
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Tile


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
