module Evergreen.V45.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V45.Bounds
import Evergreen.V45.Change
import Evergreen.V45.Color
import Evergreen.V45.Grid
import Evergreen.V45.Id
import Evergreen.V45.IdDict
import Evergreen.V45.Point2d
import Evergreen.V45.Units


type alias Cursor =
    { position : Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V45.Id.Id Evergreen.V45.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V45.Grid.Grid
    , userStatus : Evergreen.V45.Change.UserStatus
    , viewBounds : Evergreen.V45.Bounds.Bounds Evergreen.V45.Units.CellUnit
    , cows : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.CowId Evergreen.V45.Change.Cow
    , cursors : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.UserId Cursor
    , handColors : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.UserId Evergreen.V45.Color.Colors
    }


type LocalGrid
    = LocalGrid LocalGrid_
