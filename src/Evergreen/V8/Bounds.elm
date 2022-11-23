module Evergreen.V8.Bounds exposing (..)

import Evergreen.V8.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V8.Coord.Coord unit
        , max : Evergreen.V8.Coord.Coord unit
        }
