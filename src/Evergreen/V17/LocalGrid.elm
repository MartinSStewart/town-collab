module Evergreen.V17.LocalGrid exposing (..)

import Dict
import Evergreen.V17.Bounds
import Evergreen.V17.Coord
import Evergreen.V17.Grid
import Evergreen.V17.Id
import Evergreen.V17.Units
import EverySet


type alias LocalGrid_ = 
    { grid : Evergreen.V17.Grid.Grid
    , undoHistory : (List (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int))
    , redoHistory : (List (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int))
    , user : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , hiddenUsers : (EverySet.EverySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , adminHiddenUsers : (EverySet.EverySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , viewBounds : (Evergreen.V17.Bounds.Bounds Evergreen.V17.Units.CellUnit)
    , undoCurrent : (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int)
    }


type LocalGrid
    = LocalGrid LocalGrid_