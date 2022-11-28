module Evergreen.V11.LocalGrid exposing (..)

import Dict
import Evergreen.V11.Bounds
import Evergreen.V11.Coord
import Evergreen.V11.Grid
import Evergreen.V11.Id
import Evergreen.V11.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V11.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V11.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V11.Coord.RawCellCoord Int)
    , user : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    , viewBounds : Evergreen.V11.Bounds.Bounds Evergreen.V11.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V11.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
