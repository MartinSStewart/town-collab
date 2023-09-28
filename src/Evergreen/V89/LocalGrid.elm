module Evergreen.V89.LocalGrid exposing (..)

import Evergreen.V89.Animal
import Evergreen.V89.Bounds
import Evergreen.V89.Change
import Evergreen.V89.Cursor
import Evergreen.V89.Grid
import Evergreen.V89.Id
import Evergreen.V89.IdDict
import Evergreen.V89.MailEditor
import Evergreen.V89.Train
import Evergreen.V89.Units
import Evergreen.V89.User


type alias LocalGrid_ =
    { grid : Evergreen.V89.Grid.Grid
    , userStatus : Evergreen.V89.Change.UserStatus
    , viewBounds : Evergreen.V89.Bounds.Bounds Evergreen.V89.Units.CellUnit
    , animals : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.AnimalId Evergreen.V89.Animal.Animal
    , cursors : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Evergreen.V89.Cursor.Cursor
    , users : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Evergreen.V89.User.FrontendUser
    , inviteTree : Evergreen.V89.User.InviteTree
    , mail : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.MailId Evergreen.V89.MailEditor.FrontendMail
    , trains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , trainsDisabled : Evergreen.V89.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
