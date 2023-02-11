module Evergreen.V60.Bounds exposing (..)

import Evergreen.V60.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V60.Coord.Coord unit
        , max : Evergreen.V60.Coord.Coord unit
        }
