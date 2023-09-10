module Evergreen.V82.Shaders exposing (..)

import Math.Vector2


type alias Vertex =
    { x : Float
    , y : Float
    , z : Float
    , texturePosition : Float
    , opacityAndUserId : Float
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
