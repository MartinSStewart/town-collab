module Evergreen.V107.Bounds exposing (..)

import Evergreen.V107.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V107.Coord.Coord unit
        , max : Evergreen.V107.Coord.Coord unit
        }
