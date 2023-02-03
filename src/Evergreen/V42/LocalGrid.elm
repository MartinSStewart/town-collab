module Evergreen.V42.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V42.Bounds
import Evergreen.V42.Change
import Evergreen.V42.Color
import Evergreen.V42.Grid
import Evergreen.V42.Id
import Evergreen.V42.IdDict
import Evergreen.V42.Point2d
import Evergreen.V42.Units


type alias Cursor =
    { position : Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V42.Id.Id Evergreen.V42.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V42.Grid.Grid
    , userStatus : Evergreen.V42.Change.UserStatus
    , viewBounds : Evergreen.V42.Bounds.Bounds Evergreen.V42.Units.CellUnit
    , cows : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.CowId Evergreen.V42.Change.Cow
    , cursors : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.UserId Cursor
    , handColors : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.UserId Evergreen.V42.Color.Colors
    }


type LocalGrid
    = LocalGrid LocalGrid_
