module Evergreen.V47.Bounds exposing (..)

import Evergreen.V47.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V47.Coord.Coord unit
        , max : Evergreen.V47.Coord.Coord unit
        }
