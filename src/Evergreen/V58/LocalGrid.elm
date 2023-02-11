module Evergreen.V58.LocalGrid exposing (..)

import Evergreen.V58.Bounds
import Evergreen.V58.Change
import Evergreen.V58.Cursor
import Evergreen.V58.Grid
import Evergreen.V58.Id
import Evergreen.V58.IdDict
import Evergreen.V58.MailEditor
import Evergreen.V58.Train
import Evergreen.V58.Units
import Evergreen.V58.User


type alias LocalGrid_ =
    { grid : Evergreen.V58.Grid.Grid
    , userStatus : Evergreen.V58.Change.UserStatus
    , viewBounds : Evergreen.V58.Bounds.Bounds Evergreen.V58.Units.CellUnit
    , cows : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.CowId Evergreen.V58.Change.Cow
    , cursors : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId Evergreen.V58.Cursor.Cursor
    , users : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId Evergreen.V58.User.FrontendUser
    , mail : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.MailId Evergreen.V58.MailEditor.FrontendMail
    , trains : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
