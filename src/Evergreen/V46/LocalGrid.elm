module Evergreen.V46.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V46.Bounds
import Evergreen.V46.Change
import Evergreen.V46.Grid
import Evergreen.V46.Id
import Evergreen.V46.IdDict
import Evergreen.V46.MailEditor
import Evergreen.V46.Point2d
import Evergreen.V46.Train
import Evergreen.V46.Units
import Evergreen.V46.User


type alias Cursor =
    { position : Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V46.Id.Id Evergreen.V46.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V46.Grid.Grid
    , userStatus : Evergreen.V46.Change.UserStatus
    , viewBounds : Evergreen.V46.Bounds.Bounds Evergreen.V46.Units.CellUnit
    , cows : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.CowId Evergreen.V46.Change.Cow
    , cursors : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId Cursor
    , users : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId Evergreen.V46.User.FrontendUser
    , mail : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.MailId Evergreen.V46.MailEditor.FrontendMail
    , trains : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
