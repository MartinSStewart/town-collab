module Evergreen.V12.LocalGrid exposing (..)

import Dict
import Evergreen.V12.Bounds
import Evergreen.V12.Coord
import Evergreen.V12.Grid
import Evergreen.V12.Id
import Evergreen.V12.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V12.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V12.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V12.Coord.RawCellCoord Int)
    , user : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , viewBounds : Evergreen.V12.Bounds.Bounds Evergreen.V12.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V12.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
