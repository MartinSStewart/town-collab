module Evergreen.V56.Bounds exposing (..)

import Evergreen.V56.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V56.Coord.Coord unit
        , max : Evergreen.V56.Coord.Coord unit
        }
