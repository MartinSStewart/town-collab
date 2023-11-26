module Evergreen.V123.Bounds exposing (..)

import Evergreen.V123.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V123.Coord.Coord unit
        , max : Evergreen.V123.Coord.Coord unit
        }
