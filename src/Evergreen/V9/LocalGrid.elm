module Evergreen.V9.LocalGrid exposing (..)

import Dict
import Evergreen.V9.Bounds
import Evergreen.V9.Coord
import Evergreen.V9.Grid
import Evergreen.V9.Id
import Evergreen.V9.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V9.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V9.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V9.Coord.RawCellCoord Int)
    , user : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , viewBounds : Evergreen.V9.Bounds.Bounds Evergreen.V9.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V9.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
