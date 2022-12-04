module Evergreen.V18.Bounds exposing (..)

import Evergreen.V18.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V18.Coord.Coord unit
        , max : Evergreen.V18.Coord.Coord unit
        }
