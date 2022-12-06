module Evergreen.V23.LocalGrid exposing (..)

import Dict
import Evergreen.V23.Bounds
import Evergreen.V23.Coord
import Evergreen.V23.Grid
import Evergreen.V23.Id
import Evergreen.V23.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V23.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V23.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V23.Coord.RawCellCoord Int)
    , user : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , viewBounds : Evergreen.V23.Bounds.Bounds Evergreen.V23.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V23.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
