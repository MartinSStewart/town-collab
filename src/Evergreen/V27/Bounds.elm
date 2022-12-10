module Evergreen.V27.Bounds exposing (..)

import Evergreen.V27.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V27.Coord.Coord unit
        , max : Evergreen.V27.Coord.Coord unit
        }
