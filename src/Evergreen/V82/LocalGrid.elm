module Evergreen.V82.LocalGrid exposing (..)

import Evergreen.V82.Animal
import Evergreen.V82.Bounds
import Evergreen.V82.Change
import Evergreen.V82.Cursor
import Evergreen.V82.Grid
import Evergreen.V82.Id
import Evergreen.V82.IdDict
import Evergreen.V82.MailEditor
import Evergreen.V82.Train
import Evergreen.V82.Units
import Evergreen.V82.User


type alias LocalGrid_ =
    { grid : Evergreen.V82.Grid.Grid
    , userStatus : Evergreen.V82.Change.UserStatus
    , viewBounds : Evergreen.V82.Bounds.Bounds Evergreen.V82.Units.CellUnit
    , animals : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.AnimalId Evergreen.V82.Animal.Animal
    , cursors : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Evergreen.V82.Cursor.Cursor
    , users : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Evergreen.V82.User.FrontendUser
    , inviteTree : Evergreen.V82.User.InviteTree
    , mail : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.MailId Evergreen.V82.MailEditor.FrontendMail
    , trains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , trainsDisabled : Evergreen.V82.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
