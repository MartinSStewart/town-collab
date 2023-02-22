module Evergreen.V69.Bounds exposing (..)

import Evergreen.V69.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V69.Coord.Coord unit
        , max : Evergreen.V69.Coord.Coord unit
        }
