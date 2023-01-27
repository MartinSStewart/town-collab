module Evergreen.V46.Bounds exposing (..)

import Evergreen.V46.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V46.Coord.Coord unit
        , max : Evergreen.V46.Coord.Coord unit
        }
