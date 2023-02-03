module Evergreen.V44.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V44.Bounds
import Evergreen.V44.Change
import Evergreen.V44.Color
import Evergreen.V44.Grid
import Evergreen.V44.Id
import Evergreen.V44.IdDict
import Evergreen.V44.Point2d
import Evergreen.V44.Units


type alias Cursor =
    { position : Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V44.Id.Id Evergreen.V44.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V44.Grid.Grid
    , userStatus : Evergreen.V44.Change.UserStatus
    , viewBounds : Evergreen.V44.Bounds.Bounds Evergreen.V44.Units.CellUnit
    , cows : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.CowId Evergreen.V44.Change.Cow
    , cursors : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.UserId Cursor
    , handColors : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.UserId Evergreen.V44.Color.Colors
    }


type LocalGrid
    = LocalGrid LocalGrid_
