module Evergreen.V59.LocalGrid exposing (..)

import Evergreen.V59.Bounds
import Evergreen.V59.Change
import Evergreen.V59.Cursor
import Evergreen.V59.Grid
import Evergreen.V59.Id
import Evergreen.V59.IdDict
import Evergreen.V59.MailEditor
import Evergreen.V59.Train
import Evergreen.V59.Units
import Evergreen.V59.User


type alias LocalGrid_ =
    { grid : Evergreen.V59.Grid.Grid
    , userStatus : Evergreen.V59.Change.UserStatus
    , viewBounds : Evergreen.V59.Bounds.Bounds Evergreen.V59.Units.CellUnit
    , cows : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.CowId Evergreen.V59.Change.Cow
    , cursors : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId Evergreen.V59.Cursor.Cursor
    , users : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId Evergreen.V59.User.FrontendUser
    , mail : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.MailId Evergreen.V59.MailEditor.FrontendMail
    , trains : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
