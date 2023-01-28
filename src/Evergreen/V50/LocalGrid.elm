module Evergreen.V50.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V50.Bounds
import Evergreen.V50.Change
import Evergreen.V50.Grid
import Evergreen.V50.Id
import Evergreen.V50.IdDict
import Evergreen.V50.MailEditor
import Evergreen.V50.Point2d
import Evergreen.V50.Train
import Evergreen.V50.Units
import Evergreen.V50.User


type alias Cursor =
    { position : Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V50.Id.Id Evergreen.V50.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V50.Grid.Grid
    , userStatus : Evergreen.V50.Change.UserStatus
    , viewBounds : Evergreen.V50.Bounds.Bounds Evergreen.V50.Units.CellUnit
    , cows : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.CowId Evergreen.V50.Change.Cow
    , cursors : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId Cursor
    , users : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId Evergreen.V50.User.FrontendUser
    , mail : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.MailId Evergreen.V50.MailEditor.FrontendMail
    , trains : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
