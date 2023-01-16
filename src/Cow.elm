module Cow exposing (cowMesh, cowSizeWorld, defaultColors, insideCow, texturePosition, textureSize)

import BoundingBox2d
import Color exposing (Colors)
import Coord exposing (Coord)
import Effect.WebGL
import Math.Vector3 as Vec3
import Point2d exposing (Point2d)
import Shaders exposing (Vertex)
import Tile
import Units exposing (WorldUnit)
import Vector2d exposing (Vector2d)


textureSize : Coord units
textureSize =
    Coord.xy 20 14


cowSizeWorld : Vector2d WorldUnit WorldUnit
cowSizeWorld =
    Vector2d.unsafe
        { x = toFloat (Coord.xRaw textureSize) / toFloat (Coord.xRaw Units.tileSize)
        , y = toFloat (Coord.yRaw textureSize) / toFloat (Coord.yRaw Units.tileSize)
        }


cowPrimaryColor =
    Color.toVec3 defaultColors.primaryColor


cowSecondaryColor =
    Color.toVec3 defaultColors.secondaryColor


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
    let
        ( width, height ) =
            Coord.toTuple textureSize |> Tuple.mapBoth toFloat toFloat

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels texturePosition textureSize
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 (-width / 2) (-height / 2) 0
          , texturePosition = topLeft
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        , { position = Vec3.vec3 (width / 2) (-height / 2) 0
          , texturePosition = topRight
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        , { position = Vec3.vec3 (width / 2) (height / 2) 0
          , texturePosition = bottomRight
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        , { position = Vec3.vec3 (-width / 2) (height / 2) 0
          , texturePosition = bottomLeft
          , opacity = 1
          , primaryColor = cowPrimaryColor
          , secondaryColor = cowSecondaryColor
          }
        ]
