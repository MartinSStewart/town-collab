module Evergreen.V54.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V54.Bounds
import Evergreen.V54.Change
import Evergreen.V54.Grid
import Evergreen.V54.Id
import Evergreen.V54.IdDict
import Evergreen.V54.MailEditor
import Evergreen.V54.Point2d
import Evergreen.V54.Train
import Evergreen.V54.Units
import Evergreen.V54.User


type alias Cursor =
    { position : Evergreen.V54.Point2d.Point2d Evergreen.V54.Units.WorldUnit Evergreen.V54.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V54.Id.Id Evergreen.V54.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V54.Grid.Grid
    , userStatus : Evergreen.V54.Change.UserStatus
    , viewBounds : Evergreen.V54.Bounds.Bounds Evergreen.V54.Units.CellUnit
    , cows : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.CowId Evergreen.V54.Change.Cow
    , cursors : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.UserId Cursor
    , users : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.UserId Evergreen.V54.User.FrontendUser
    , mail : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.MailId Evergreen.V54.MailEditor.FrontendMail
    , trains : Evergreen.V54.IdDict.IdDict Evergreen.V54.Id.TrainId Evergreen.V54.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
