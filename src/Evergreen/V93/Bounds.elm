module Evergreen.V93.Bounds exposing (..)

import Evergreen.V93.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V93.Coord.Coord unit
        , max : Evergreen.V93.Coord.Coord unit
        }
