module Evergreen.V16.LocalGrid exposing (..)

import Dict
import Evergreen.V16.Bounds
import Evergreen.V16.Coord
import Evergreen.V16.Grid
import Evergreen.V16.Id
import Evergreen.V16.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V16.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V16.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V16.Coord.RawCellCoord Int)
    , user : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , viewBounds : Evergreen.V16.Bounds.Bounds Evergreen.V16.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V16.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
