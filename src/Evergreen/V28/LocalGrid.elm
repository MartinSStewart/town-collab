module Evergreen.V28.LocalGrid exposing (..)

import Dict
import Evergreen.V28.Bounds
import Evergreen.V28.Coord
import Evergreen.V28.Grid
import Evergreen.V28.Id
import Evergreen.V28.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V28.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V28.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V28.Coord.RawCellCoord Int)
    , user : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    , viewBounds : Evergreen.V28.Bounds.Bounds Evergreen.V28.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V28.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
