module Evergreen.V29.LocalGrid exposing (..)

import Dict
import Evergreen.V29.Bounds
import Evergreen.V29.Change
import Evergreen.V29.Coord
import Evergreen.V29.Grid
import Evergreen.V29.Id
import Evergreen.V29.IdDict
import Evergreen.V29.Point2d
import Evergreen.V29.Units
import EverySet
import Time


type alias Cursor =
    { position : Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V29.Id.Id Evergreen.V29.Id.CowId
            , pickupTime : Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V29.Grid.Grid
    , undoHistory : List (Dict.Dict Evergreen.V29.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V29.Coord.RawCellCoord Int)
    , user : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , hiddenUsers : EverySet.EverySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , viewBounds : Evergreen.V29.Bounds.Bounds Evergreen.V29.Units.CellUnit
    , undoCurrent : Dict.Dict Evergreen.V29.Coord.RawCellCoord Int
    , cows : Evergreen.V29.IdDict.IdDict Evergreen.V29.Id.CowId Evergreen.V29.Change.Cow
    , cursors : Evergreen.V29.IdDict.IdDict Evergreen.V29.Id.UserId Cursor
    }


type LocalGrid
    = LocalGrid LocalGrid_
