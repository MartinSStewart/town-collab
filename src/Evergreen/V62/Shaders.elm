module Evergreen.V62.Shaders exposing (..)

import Math.Vector2
import Math.Vector3


type alias Vertex =
    { position : Math.Vector3.Vec3
    , texturePosition : Float
    , opacity : Float
    , primaryColor : Float
    , secondaryColor : Float
    }


type alias DebrisVertex =
    { position : Math.Vector2.Vec2
    , texturePosition : Float
    , initialSpeed : Math.Vector2.Vec2
    , startTime : Float
    , primaryColor : Float
    , secondaryColor : Float
    }
