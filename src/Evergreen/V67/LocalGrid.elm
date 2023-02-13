module Evergreen.V67.LocalGrid exposing (..)

import Evergreen.V67.Bounds
import Evergreen.V67.Change
import Evergreen.V67.Cursor
import Evergreen.V67.Grid
import Evergreen.V67.Id
import Evergreen.V67.IdDict
import Evergreen.V67.MailEditor
import Evergreen.V67.Train
import Evergreen.V67.Units
import Evergreen.V67.User


type alias LocalGrid_ =
    { grid : Evergreen.V67.Grid.Grid
    , userStatus : Evergreen.V67.Change.UserStatus
    , viewBounds : Evergreen.V67.Bounds.Bounds Evergreen.V67.Units.CellUnit
    , cows : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.CowId Evergreen.V67.Change.Cow
    , cursors : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Evergreen.V67.Cursor.Cursor
    , users : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Evergreen.V67.User.FrontendUser
    , inviteTree : Evergreen.V67.User.InviteTree
    , mail : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.MailId Evergreen.V67.MailEditor.FrontendMail
    , trains : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
