module Evergreen.V23.Bounds exposing (..)

import Evergreen.V23.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V23.Coord.Coord unit
        , max : Evergreen.V23.Coord.Coord unit
        }
