module Evergreen.V47.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V47.Bounds
import Evergreen.V47.Change
import Evergreen.V47.Grid
import Evergreen.V47.Id
import Evergreen.V47.IdDict
import Evergreen.V47.MailEditor
import Evergreen.V47.Point2d
import Evergreen.V47.Train
import Evergreen.V47.Units
import Evergreen.V47.User


type alias Cursor =
    { position : Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V47.Id.Id Evergreen.V47.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V47.Grid.Grid
    , userStatus : Evergreen.V47.Change.UserStatus
    , viewBounds : Evergreen.V47.Bounds.Bounds Evergreen.V47.Units.CellUnit
    , cows : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.CowId Evergreen.V47.Change.Cow
    , cursors : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId Cursor
    , users : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId Evergreen.V47.User.FrontendUser
    , mail : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.MailId Evergreen.V47.MailEditor.FrontendMail
    , trains : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
