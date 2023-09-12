module Evergreen.V84.LocalGrid exposing (..)

import Evergreen.V84.Animal
import Evergreen.V84.Bounds
import Evergreen.V84.Change
import Evergreen.V84.Cursor
import Evergreen.V84.Grid
import Evergreen.V84.Id
import Evergreen.V84.IdDict
import Evergreen.V84.MailEditor
import Evergreen.V84.Train
import Evergreen.V84.Units
import Evergreen.V84.User


type alias LocalGrid_ =
    { grid : Evergreen.V84.Grid.Grid
    , userStatus : Evergreen.V84.Change.UserStatus
    , viewBounds : Evergreen.V84.Bounds.Bounds Evergreen.V84.Units.CellUnit
    , animals : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.AnimalId Evergreen.V84.Animal.Animal
    , cursors : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Evergreen.V84.Cursor.Cursor
    , users : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Evergreen.V84.User.FrontendUser
    , inviteTree : Evergreen.V84.User.InviteTree
    , mail : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.MailId Evergreen.V84.MailEditor.FrontendMail
    , trains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , trainsDisabled : Evergreen.V84.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
