module Evergreen.V6.LocalGrid exposing (..)

import Dict
import Evergreen.V6.Bounds
import Evergreen.V6.Coord
import Evergreen.V6.Grid
import Evergreen.V6.Id
import Evergreen.V6.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V6.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V6.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V6.Coord.RawCellCoord Int)
    , user : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , viewBounds : Evergreen.V6.Bounds.Bounds Evergreen.V6.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V6.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
