module Evergreen.V49.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V49.Bounds
import Evergreen.V49.Change
import Evergreen.V49.Grid
import Evergreen.V49.Id
import Evergreen.V49.IdDict
import Evergreen.V49.MailEditor
import Evergreen.V49.Point2d
import Evergreen.V49.Train
import Evergreen.V49.Units
import Evergreen.V49.User


type alias Cursor =
    { position : Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V49.Id.Id Evergreen.V49.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V49.Grid.Grid
    , userStatus : Evergreen.V49.Change.UserStatus
    , viewBounds : Evergreen.V49.Bounds.Bounds Evergreen.V49.Units.CellUnit
    , cows : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.CowId Evergreen.V49.Change.Cow
    , cursors : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId Cursor
    , users : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId Evergreen.V49.User.FrontendUser
    , mail : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.MailId Evergreen.V49.MailEditor.FrontendMail
    , trains : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
