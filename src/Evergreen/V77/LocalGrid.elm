module Evergreen.V77.LocalGrid exposing (..)

import Evergreen.V77.Animal
import Evergreen.V77.Bounds
import Evergreen.V77.Change
import Evergreen.V77.Cursor
import Evergreen.V77.Grid
import Evergreen.V77.Id
import Evergreen.V77.IdDict
import Evergreen.V77.MailEditor
import Evergreen.V77.Train
import Evergreen.V77.Units
import Evergreen.V77.User


type alias LocalGrid_ =
    { grid : Evergreen.V77.Grid.Grid
    , userStatus : Evergreen.V77.Change.UserStatus
    , viewBounds : Evergreen.V77.Bounds.Bounds Evergreen.V77.Units.CellUnit
    , animals : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.AnimalId Evergreen.V77.Animal.Animal
    , cursors : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Evergreen.V77.Cursor.Cursor
    , users : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Evergreen.V77.User.FrontendUser
    , inviteTree : Evergreen.V77.User.InviteTree
    , mail : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.MailId Evergreen.V77.MailEditor.FrontendMail
    , trains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , trainsDisabled : Evergreen.V77.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
