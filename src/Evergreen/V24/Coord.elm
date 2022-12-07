module Evergreen.V24.Coord exposing (..)

import Quantity


type alias Coord units =
    ( Quantity.Quantity Int units, Quantity.Quantity Int units )


type alias RawCellCoord =
    ( Int, Int )
