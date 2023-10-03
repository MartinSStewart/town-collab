module Evergreen.V91.Bounds exposing (..)

import Evergreen.V91.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V91.Coord.Coord unit
        , max : Evergreen.V91.Coord.Coord unit
        }
