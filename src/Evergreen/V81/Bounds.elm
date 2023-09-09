module Evergreen.V81.Bounds exposing (..)

import Evergreen.V81.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V81.Coord.Coord unit
        , max : Evergreen.V81.Coord.Coord unit
        }
