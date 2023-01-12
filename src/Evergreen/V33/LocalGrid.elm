module Evergreen.V33.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V33.Bounds
import Evergreen.V33.Change
import Evergreen.V33.Color
import Evergreen.V33.Grid
import Evergreen.V33.Id
import Evergreen.V33.IdDict
import Evergreen.V33.Point2d
import Evergreen.V33.Units


type alias Cursor =
    { position : Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V33.Id.Id Evergreen.V33.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V33.Grid.Grid
    , userStatus : Evergreen.V33.Change.UserStatus
    , viewBounds : Evergreen.V33.Bounds.Bounds Evergreen.V33.Units.CellUnit
    , cows : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.CowId Evergreen.V33.Change.Cow
    , cursors : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.UserId Cursor
    , handColors : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.UserId Evergreen.V33.Color.Colors
    }


type LocalGrid
    = LocalGrid LocalGrid_
