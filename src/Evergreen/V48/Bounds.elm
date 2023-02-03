module Evergreen.V48.Bounds exposing (..)

import Evergreen.V48.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V48.Coord.Coord unit
        , max : Evergreen.V48.Coord.Coord unit
        }
