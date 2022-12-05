module Evergreen.V20.LocalGrid exposing (..)

import Dict
import Evergreen.V20.Bounds
import Evergreen.V20.Coord
import Evergreen.V20.Grid
import Evergreen.V20.Id
import Evergreen.V20.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V20.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V20.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V20.Coord.RawCellCoord Int)
    , user : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    , viewBounds : Evergreen.V20.Bounds.Bounds Evergreen.V20.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V20.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
