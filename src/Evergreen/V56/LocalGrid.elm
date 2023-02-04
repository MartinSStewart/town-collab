module Evergreen.V56.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V56.Bounds
import Evergreen.V56.Change
import Evergreen.V56.Grid
import Evergreen.V56.Id
import Evergreen.V56.IdDict
import Evergreen.V56.MailEditor
import Evergreen.V56.Point2d
import Evergreen.V56.Train
import Evergreen.V56.Units
import Evergreen.V56.User


type alias Cursor =
    { position : Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V56.Id.Id Evergreen.V56.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V56.Grid.Grid
    , userStatus : Evergreen.V56.Change.UserStatus
    , viewBounds : Evergreen.V56.Bounds.Bounds Evergreen.V56.Units.CellUnit
    , cows : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.CowId Evergreen.V56.Change.Cow
    , cursors : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId Cursor
    , users : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId Evergreen.V56.User.FrontendUser
    , mail : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.MailId Evergreen.V56.MailEditor.FrontendMail
    , trains : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
