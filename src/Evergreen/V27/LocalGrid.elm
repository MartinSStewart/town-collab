module Evergreen.V27.LocalGrid exposing (..)

import Dict
import Evergreen.V27.Bounds
import Evergreen.V27.Coord
import Evergreen.V27.Grid
import Evergreen.V27.Id
import Evergreen.V27.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V27.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V27.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V27.Coord.RawCellCoord Int)
    , user : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , viewBounds : Evergreen.V27.Bounds.Bounds Evergreen.V27.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V27.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
