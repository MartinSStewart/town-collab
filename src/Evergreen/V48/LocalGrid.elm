module Evergreen.V48.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V48.Bounds
import Evergreen.V48.Change
import Evergreen.V48.Grid
import Evergreen.V48.Id
import Evergreen.V48.IdDict
import Evergreen.V48.MailEditor
import Evergreen.V48.Point2d
import Evergreen.V48.Train
import Evergreen.V48.Units
import Evergreen.V48.User


type alias Cursor =
    { position : Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V48.Id.Id Evergreen.V48.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V48.Grid.Grid
    , userStatus : Evergreen.V48.Change.UserStatus
    , viewBounds : Evergreen.V48.Bounds.Bounds Evergreen.V48.Units.CellUnit
    , cows : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.CowId Evergreen.V48.Change.Cow
    , cursors : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId Cursor
    , users : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId Evergreen.V48.User.FrontendUser
    , mail : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.MailId Evergreen.V48.MailEditor.FrontendMail
    , trains : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
