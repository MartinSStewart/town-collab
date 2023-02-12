module Evergreen.V62.LocalGrid exposing (..)

import Evergreen.V62.Bounds
import Evergreen.V62.Change
import Evergreen.V62.Cursor
import Evergreen.V62.Grid
import Evergreen.V62.Id
import Evergreen.V62.IdDict
import Evergreen.V62.MailEditor
import Evergreen.V62.Train
import Evergreen.V62.Units
import Evergreen.V62.User


type alias LocalGrid_ =
    { grid : Evergreen.V62.Grid.Grid
    , userStatus : Evergreen.V62.Change.UserStatus
    , viewBounds : Evergreen.V62.Bounds.Bounds Evergreen.V62.Units.CellUnit
    , cows : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.CowId Evergreen.V62.Change.Cow
    , cursors : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId Evergreen.V62.Cursor.Cursor
    , users : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId Evergreen.V62.User.FrontendUser
    , mail : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.MailId Evergreen.V62.MailEditor.FrontendMail
    , trains : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.Train
    }


type LocalGrid
    = LocalGrid LocalGrid_
