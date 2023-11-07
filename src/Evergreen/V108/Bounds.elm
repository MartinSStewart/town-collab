module Evergreen.V108.Bounds exposing (..)

import Evergreen.V108.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V108.Coord.Coord unit
        , max : Evergreen.V108.Coord.Coord unit
        }
