module Evergreen.V134.Shaders exposing (..)

import Math.Vector2


type alias DebrisVertex =
    { position : Math.Vector2.Vec2
    , texturePosition : Float
    , initialSpeed : Math.Vector2.Vec2
    , startTime : Float
    , primaryColor : Float
    , secondaryColor : Float
    }
