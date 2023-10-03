module Evergreen.V91.LocalGrid exposing (..)

import Evergreen.V91.Animal
import Evergreen.V91.Bounds
import Evergreen.V91.Change
import Evergreen.V91.Cursor
import Evergreen.V91.Grid
import Evergreen.V91.Id
import Evergreen.V91.IdDict
import Evergreen.V91.MailEditor
import Evergreen.V91.Train
import Evergreen.V91.Units
import Evergreen.V91.User


type alias LocalGrid_ =
    { grid : Evergreen.V91.Grid.Grid
    , userStatus : Evergreen.V91.Change.UserStatus
    , viewBounds : Evergreen.V91.Bounds.Bounds Evergreen.V91.Units.CellUnit
    , animals : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.AnimalId Evergreen.V91.Animal.Animal
    , cursors : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Evergreen.V91.Cursor.Cursor
    , users : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Evergreen.V91.User.FrontendUser
    , inviteTree : Evergreen.V91.User.InviteTree
    , mail : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.MailId Evergreen.V91.MailEditor.FrontendMail
    , trains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , trainsDisabled : Evergreen.V91.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
