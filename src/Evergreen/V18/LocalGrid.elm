module Evergreen.V18.LocalGrid exposing (..)

import Dict
import Evergreen.V18.Bounds
import Evergreen.V18.Coord
import Evergreen.V18.Grid
import Evergreen.V18.Id
import Evergreen.V18.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V18.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V18.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V18.Coord.RawCellCoord Int)
    , user : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    , viewBounds : Evergreen.V18.Bounds.Bounds Evergreen.V18.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V18.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
