module Evergreen.V52.LocalGrid exposing (..)

import Effect.Time
import Evergreen.V52.Bounds
import Evergreen.V52.Change
import Evergreen.V52.Grid
import Evergreen.V52.Id
import Evergreen.V52.IdDict
import Evergreen.V52.MailEditor
import Evergreen.V52.Point2d
import Evergreen.V52.Train
import Evergreen.V52.Units
import Evergreen.V52.User


type alias Cursor =
    { position : Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V52.Id.Id Evergreen.V52.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    }


type alias LocalGrid_ =
    { grid : Evergreen.V52.Grid.Grid
    , userStatus : Evergreen.V52.Change.UserStatus
    , viewBounds : Evergreen.V52.Bounds.Bounds Evergreen.V52.Units.CellUnit
    , cows : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.CowId Evergreen.V52.Change.Cow
    , cursors : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId Cursor
    , users : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId Evergreen.V52.User.FrontendUser
    , mail : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.MailId Evergreen.V52.MailEditor.FrontendMail
    , trains : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
