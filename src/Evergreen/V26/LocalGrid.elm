module Evergreen.V26.LocalGrid exposing (..)

import Dict
import Evergreen.V26.Bounds
import Evergreen.V26.Coord
import Evergreen.V26.Grid
import Evergreen.V26.Id
import Evergreen.V26.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V26.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V26.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V26.Coord.RawCellCoord Int)
    , user : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , viewBounds : Evergreen.V26.Bounds.Bounds Evergreen.V26.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V26.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
