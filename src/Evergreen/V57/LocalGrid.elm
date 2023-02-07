module Evergreen.V57.LocalGrid exposing (..)

import Evergreen.V57.Bounds
import Evergreen.V57.Change
import Evergreen.V57.Cursor
import Evergreen.V57.Grid
import Evergreen.V57.Id
import Evergreen.V57.IdDict
import Evergreen.V57.MailEditor
import Evergreen.V57.Train
import Evergreen.V57.Units
import Evergreen.V57.User


type alias LocalGrid_ =
    { grid : Evergreen.V57.Grid.Grid
    , userStatus : Evergreen.V57.Change.UserStatus
    , viewBounds : Evergreen.V57.Bounds.Bounds Evergreen.V57.Units.CellUnit
    , cows : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.CowId Evergreen.V57.Change.Cow
    , cursors : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId Evergreen.V57.Cursor.Cursor
    , users : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId Evergreen.V57.User.FrontendUser
    , mail : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.MailId Evergreen.V57.MailEditor.FrontendMail
    , trains : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
