module Evergreen.V14.Shaders exposing (..)

import Math.Vector2
import Math.Vector3


type alias Vertex =
    { position : Math.Vector3.Vec3
    , texturePosition : Math.Vector2.Vec2
    , opacity : Float
    }


type alias DebrisVertex =
    { position : Math.Vector2.Vec2
    , texturePosition : Math.Vector2.Vec2
    , initialSpeed : Math.Vector2.Vec2
    , startTime : Float
    }
