module Evergreen.V43.Bounds exposing (..)

import Evergreen.V43.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V43.Coord.Coord unit
        , max : Evergreen.V43.Coord.Coord unit
        }
