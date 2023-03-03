module Evergreen.V74.Bounds exposing (..)

import Evergreen.V74.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V74.Coord.Coord unit
        , max : Evergreen.V74.Coord.Coord unit
        }
