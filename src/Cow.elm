module Cow exposing (cowMesh, cowSizeWorld, defaultColors, insideCow, texturePosition, textureSize)

import BoundingBox2d
import Color exposing (Colors)
import Coord exposing (Coord)
import Effect.WebGL
import Math.Vector3 as Vec3
import Point2d exposing (Point2d)
import Shaders exposing (Vertex)
import Sprite
import Tile
import Units exposing (WorldUnit)
import Vector2d exposing (Vector2d)


textureSize : Coord units
textureSize =
    Coord.xy 20 14


cowSizeWorld : Vector2d WorldUnit WorldUnit
cowSizeWorld =
    Vector2d.unsafe
        { x = toFloat (Coord.xRaw textureSize) / toFloat Units.tileWidth
        , y = toFloat (Coord.yRaw textureSize) / toFloat Units.tileHeight
        }


defaultColors : Colors
defaultColors =
    { primaryColor = Color.white, secondaryColor = Color.rgb255 30 30 30 }


insideCow : Point2d WorldUnit WorldUnit -> Point2d WorldUnit WorldUnit -> Bool
insideCow point cowPosition =
    BoundingBox2d.from
        (Point2d.translateBy (Vector2d.scaleBy 0.5 cowSizeWorld) cowPosition)
        (Point2d.translateBy (Vector2d.scaleBy -0.5 cowSizeWorld) cowPosition)
        |> BoundingBox2d.contains point


texturePosition : Coord units
texturePosition =
    Coord.xy 99 594


cowMesh : Effect.WebGL.Mesh Vertex
cowMesh =
    Sprite.spriteWithTwoColors
        defaultColors
        (Coord.divide (Coord.xy -2 -2) textureSize)
        textureSize
        texturePosition
        textureSize
        |> Sprite.toMesh
