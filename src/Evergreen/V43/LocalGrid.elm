module Evergreen.V43.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V43.Bounds
import Evergreen.V43.Change
import Evergreen.V43.Color
import Evergreen.V43.Grid
import Evergreen.V43.Id
import Evergreen.V43.IdDict
import Evergreen.V43.Point2d
import Evergreen.V43.Units


type alias Cursor =
    { position : Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V43.Id.Id Evergreen.V43.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V43.Grid.Grid
    , userStatus : Evergreen.V43.Change.UserStatus
    , viewBounds : Evergreen.V43.Bounds.Bounds Evergreen.V43.Units.CellUnit
    , cows : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.CowId Evergreen.V43.Change.Cow
    , cursors : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.UserId Cursor
    , handColors : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.UserId Evergreen.V43.Color.Colors
    }


type LocalGrid
    = LocalGrid LocalGrid_
