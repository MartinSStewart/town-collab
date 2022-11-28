module Evergreen.V11.Bounds exposing (..)

import Evergreen.V11.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V11.Coord.Coord unit
        , max : Evergreen.V11.Coord.Coord unit
        }
