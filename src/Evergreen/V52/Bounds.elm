module Evergreen.V52.Bounds exposing (..)

import Evergreen.V52.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V52.Coord.Coord unit
        , max : Evergreen.V52.Coord.Coord unit
        }
