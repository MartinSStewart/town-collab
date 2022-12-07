module Evergreen.V24.LocalGrid exposing (..)

import Dict
import Evergreen.V24.Bounds
import Evergreen.V24.Coord
import Evergreen.V24.Grid
import Evergreen.V24.Id
import Evergreen.V24.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V24.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V24.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V24.Coord.RawCellCoord Int)
    , user : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , viewBounds : Evergreen.V24.Bounds.Bounds Evergreen.V24.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V24.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
