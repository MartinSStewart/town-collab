module Evergreen.V88.LocalGrid exposing (..)

import Evergreen.V88.Animal
import Evergreen.V88.Bounds
import Evergreen.V88.Change
import Evergreen.V88.Cursor
import Evergreen.V88.Grid
import Evergreen.V88.Id
import Evergreen.V88.IdDict
import Evergreen.V88.MailEditor
import Evergreen.V88.Train
import Evergreen.V88.Units
import Evergreen.V88.User


type alias LocalGrid_ =
    { grid : Evergreen.V88.Grid.Grid
    , userStatus : Evergreen.V88.Change.UserStatus
    , viewBounds : Evergreen.V88.Bounds.Bounds Evergreen.V88.Units.CellUnit
    , animals : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.AnimalId Evergreen.V88.Animal.Animal
    , cursors : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Evergreen.V88.Cursor.Cursor
    , users : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Evergreen.V88.User.FrontendUser
    , inviteTree : Evergreen.V88.User.InviteTree
    , mail : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.MailId Evergreen.V88.MailEditor.FrontendMail
    , trains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , trainsDisabled : Evergreen.V88.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
