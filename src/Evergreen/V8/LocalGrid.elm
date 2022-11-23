module Evergreen.V8.LocalGrid exposing (..)

import Dict
import Evergreen.V8.Bounds
import Evergreen.V8.Coord
import Evergreen.V8.Grid
import Evergreen.V8.Id
import Evergreen.V8.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V8.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V8.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V8.Coord.RawCellCoord Int)
    , user : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , viewBounds : Evergreen.V8.Bounds.Bounds Evergreen.V8.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V8.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
