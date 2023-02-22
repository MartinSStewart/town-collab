module Evergreen.V69.LocalGrid exposing (..)

import Evergreen.V69.Bounds
import Evergreen.V69.Change
import Evergreen.V69.Cursor
import Evergreen.V69.Grid
import Evergreen.V69.Id
import Evergreen.V69.IdDict
import Evergreen.V69.MailEditor
import Evergreen.V69.Train
import Evergreen.V69.Units
import Evergreen.V69.User


type alias LocalGrid_ =
    { grid : Evergreen.V69.Grid.Grid
    , userStatus : Evergreen.V69.Change.UserStatus
    , viewBounds : Evergreen.V69.Bounds.Bounds Evergreen.V69.Units.CellUnit
    , cows : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.CowId Evergreen.V69.Change.Cow
    , cursors : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Evergreen.V69.Cursor.Cursor
    , users : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Evergreen.V69.User.FrontendUser
    , inviteTree : Evergreen.V69.User.InviteTree
    , mail : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.MailId Evergreen.V69.MailEditor.FrontendMail
    , trains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
