module Evergreen.V110.Bounds exposing (..)

import Evergreen.V110.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V110.Coord.Coord unit
        , max : Evergreen.V110.Coord.Coord unit
        }
