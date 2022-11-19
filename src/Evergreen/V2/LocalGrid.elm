module Evergreen.V2.LocalGrid exposing (..)

import Dict
import Evergreen.V2.Bounds
import Evergreen.V2.Coord
import Evergreen.V2.Grid
import Evergreen.V2.Id
import Evergreen.V2.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V2.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V2.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V2.Coord.RawCellCoord Int)
    , user : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    , viewBounds : Evergreen.V2.Bounds.Bounds Evergreen.V2.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V2.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
