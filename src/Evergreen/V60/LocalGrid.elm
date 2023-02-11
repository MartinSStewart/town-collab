module Evergreen.V60.LocalGrid exposing (..)

import Evergreen.V60.Bounds
import Evergreen.V60.Change
import Evergreen.V60.Cursor
import Evergreen.V60.Grid
import Evergreen.V60.Id
import Evergreen.V60.IdDict
import Evergreen.V60.MailEditor
import Evergreen.V60.Train
import Evergreen.V60.Units
import Evergreen.V60.User


type alias LocalGrid_ =
    { grid : Evergreen.V60.Grid.Grid
    , userStatus : Evergreen.V60.Change.UserStatus
    , viewBounds : Evergreen.V60.Bounds.Bounds Evergreen.V60.Units.CellUnit
    , cows : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.CowId Evergreen.V60.Change.Cow
    , cursors : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId Evergreen.V60.Cursor.Cursor
    , users : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId Evergreen.V60.User.FrontendUser
    , mail : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.MailId Evergreen.V60.MailEditor.FrontendMail
    , trains : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
