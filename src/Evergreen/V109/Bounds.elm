module Evergreen.V109.Bounds exposing (..)

import Evergreen.V109.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V109.Coord.Coord unit
        , max : Evergreen.V109.Coord.Coord unit
        }
