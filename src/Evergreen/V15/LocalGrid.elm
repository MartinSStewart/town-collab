module Evergreen.V15.LocalGrid exposing (..)

import Dict
import Evergreen.V15.Bounds
import Evergreen.V15.Coord
import Evergreen.V15.Grid
import Evergreen.V15.Id
import Evergreen.V15.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V15.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V15.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V15.Coord.RawCellCoord Int)
    , user : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , viewBounds : Evergreen.V15.Bounds.Bounds Evergreen.V15.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V15.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
