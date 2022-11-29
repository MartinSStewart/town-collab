module Evergreen.V14.LocalGrid exposing (..)

import Dict
import Evergreen.V14.Bounds
import Evergreen.V14.Coord
import Evergreen.V14.Grid
import Evergreen.V14.Id
import Evergreen.V14.Units
import EverySet


type alias LocalGrid_ =
    { grid : Evergreen.V14.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V14.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V14.Coord.RawCellCoord Int)
    , user : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , viewBounds : Evergreen.V14.Bounds.Bounds Evergreen.V14.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V14.Coord.RawCellCoord Int
    }


type LocalGrid
    = LocalGrid LocalGrid_
