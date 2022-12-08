module Evergreen.V25.LocalGrid exposing (..)

import Dict
import Evergreen.V25.Bounds
import Evergreen.V25.Coord
import Evergreen.V25.Grid
import Evergreen.V25.Id
import Evergreen.V25.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V25.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V25.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V25.Coord.RawCellCoord Int)
    , user : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , viewBounds : Evergreen.V25.Bounds.Bounds Evergreen.V25.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V25.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
