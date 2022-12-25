module Evergreen.V30.LocalGrid exposing (..)

import Dict
import Evergreen.V30.Bounds
import Evergreen.V30.Change
import Evergreen.V30.Color
import Evergreen.V30.Coord
import Evergreen.V30.Grid
import Evergreen.V30.Id
import Evergreen.V30.IdDict
import Evergreen.V30.Point2d
import Evergreen.V30.Units
import EverySet
import Time


type alias Cursor = 
    { position : (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    , holdingCow : (Maybe 
    { cowId : (Evergreen.V30.Id.Id Evergreen.V30.Id.CowId)
    , pickupTime : Time.Posix
    })
    }


type alias LocalGrid_ = 
    { grid : Evergreen.V30.Grid.Grid
    , undoHistory : (List (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int))
    , redoHistory : (List (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int))
    , user : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , hiddenUsers : (EverySet.EverySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , adminHiddenUsers : (EverySet.EverySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , viewBounds : (Evergreen.V30.Bounds.Bounds Evergreen.V30.Units.CellUnit)
    , undoCurrent : (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int)
    , cows : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.CowId Evergreen.V30.Change.Cow)
    , cursors : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.UserId Cursor)
    , handColors : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.UserId Evergreen.V30.Color.Colors)
    }


type LocalGrid
    = LocalGrid LocalGrid_