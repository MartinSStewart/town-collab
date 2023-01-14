module Evergreen.V42.Bounds exposing (..)

import Evergreen.V42.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V42.Coord.Coord unit
        , max : Evergreen.V42.Coord.Coord unit
        }
