module Evergreen.V72.LocalGrid exposing (..)

import Evergreen.V72.Bounds
import Evergreen.V72.Change
import Evergreen.V72.Cursor
import Evergreen.V72.Grid
import Evergreen.V72.Id
import Evergreen.V72.IdDict
import Evergreen.V72.MailEditor
import Evergreen.V72.Train
import Evergreen.V72.Units
import Evergreen.V72.User


type alias LocalGrid_ =
    { grid : Evergreen.V72.Grid.Grid
    , userStatus : Evergreen.V72.Change.UserStatus
    , viewBounds : Evergreen.V72.Bounds.Bounds Evergreen.V72.Units.CellUnit
    , cows : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.CowId Evergreen.V72.Change.Cow
    , cursors : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Evergreen.V72.Cursor.Cursor
    , users : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Evergreen.V72.User.FrontendUser
    , inviteTree : Evergreen.V72.User.InviteTree
    , mail : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.MailId Evergreen.V72.MailEditor.FrontendMail
    , trains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , trainsDisabled : Evergreen.V72.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
