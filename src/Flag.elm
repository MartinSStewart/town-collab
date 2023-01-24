module Flag exposing
    ( flagMesh
    , postOfficeReceivedMailFlagOffset
    , postOfficeSendingMailFlagOffset
    , postOfficeSendingMailFlagOffset2
    , receivingMailFlagColor
    , receivingMailFlagMeshes
    , sendingMailFlagColor
    , sendingMailFlagMeshes
    )

import Array exposing (Array)
import Color exposing (Color)
import Coord exposing (Coord)
import Effect.WebGL
import Math.Vector3 as Vec3
import Pixels exposing (Pixels)
import Shaders exposing (Vertex)
import Tile
import Units exposing (WorldUnit)
import Vector2d exposing (Vector2d)


postOfficeSendingMailFlagOffset : Vector2d WorldUnit WorldUnit
postOfficeSendingMailFlagOffset =
    Vector2d.unsafe { x = 3.5, y = 2 + 1 / 18 }


postOfficeSendingMailFlagOffset2 : Coord Pixels
postOfficeSendingMailFlagOffset2 =
    Coord.xy 70 37


postOfficeReceivedMailFlagOffset : Vector2d WorldUnit WorldUnit
postOfficeReceivedMailFlagOffset =
    Vector2d.unsafe { x = 3.5, y = 1 + 13 / 18 }


sendingMailFlagMeshes : Array (Effect.WebGL.Mesh Vertex)
sendingMailFlagMeshes =
    List.range 0 2
        |> List.map (flagMesh Coord.origin 1 sendingMailFlagColor >> Shaders.triangleFan)
        |> Array.fromList


flagMesh : Coord unit -> Int -> Color -> Int -> List Vertex
flagMesh position scale color frame =
    let
        width =
            11

        height =
            6

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels (Coord.xy 80 (594 + frame * 6)) (Coord.xy width 6)

        colorVec =
            Color.toVec3 color

        ( x, y ) =
            Coord.toTuple position

        x2 =
            toFloat x

        y2 =
            toFloat y

        scale2 =
            toFloat scale
    in
    [ { position = Vec3.vec3 x2 y2 0
      , texturePosition = topLeft
      , opacity = 1
      , primaryColor = colorVec
      , secondaryColor = Vec3.vec3 0 0 0
      }
    , { position = Vec3.vec3 (x2 + width * scale2) y2 0
      , texturePosition = topRight
      , opacity = 1
      , primaryColor = colorVec
      , secondaryColor = Vec3.vec3 0 0 0
      }
    , { position = Vec3.vec3 (x2 + width * scale2) (y2 + height * scale2) 0
      , texturePosition = bottomRight
      , opacity = 1
      , primaryColor = colorVec
      , secondaryColor = Vec3.vec3 0 0 0
      }
    , { position = Vec3.vec3 x2 (y2 + height * scale2) 0
      , texturePosition = bottomLeft
      , opacity = 1
      , primaryColor = colorVec
      , secondaryColor = Vec3.vec3 0 0 0
      }
    ]


sendingMailFlagColor : Color
sendingMailFlagColor =
    Color.rgb255 255 161 0


receivingMailFlagColor : Color
receivingMailFlagColor =
    Color.rgb255 255 0 0


receivingMailFlagMeshes : Array (Effect.WebGL.Mesh Vertex)
receivingMailFlagMeshes =
    List.range 0 2
        |> List.map (flagMesh Coord.origin 1 receivingMailFlagColor >> Shaders.triangleFan)
        |> Array.fromList
