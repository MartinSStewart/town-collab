module Evergreen.V125.Bounds exposing (..)

import Evergreen.V125.Coord


type Bounds unit
    = Bounds
        { min : Evergreen.V125.Coord.Coord unit
        , max : Evergreen.V125.Coord.Coord unit
        }
