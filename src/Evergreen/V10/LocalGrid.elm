module Evergreen.V10.LocalGrid exposing (..)

import Dict
import Evergreen.V10.Bounds
import Evergreen.V10.Coord
import Evergreen.V10.Grid
import Evergreen.V10.Id
import Evergreen.V10.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V10.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V10.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V10.Coord.RawCellCoord Int)
    , user : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    , viewBounds : Evergreen.V10.Bounds.Bounds Evergreen.V10.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V10.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
