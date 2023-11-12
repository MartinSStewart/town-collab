module Evergreen.V112.Bounds exposing (..)

import Evergreen.V112.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V112.Coord.Coord unit
        , max : Evergreen.V112.Coord.Coord unit
        }
