module Evergreen.V1.LocalGrid exposing (..)

import Dict
import Evergreen.V1.Bounds
import Evergreen.V1.Coord
import Evergreen.V1.Grid
import Evergreen.V1.Units
import Evergreen.V1.User
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V1.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V1.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V1.Coord.RawCellCoord Int)
    , user : Evergreen.V1.User.UserId
    , hiddenUsers : EverySet.EverySet Evergreen.V1.User.UserId
    , adminHiddenUsers : EverySet.EverySet Evergreen.V1.User.UserId
    , viewBounds : Evergreen.V1.Bounds.Bounds Evergreen.V1.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V1.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
