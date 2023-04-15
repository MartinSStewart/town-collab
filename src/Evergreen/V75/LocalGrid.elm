module Evergreen.V75.LocalGrid exposing (..)

import Evergreen.V75.Animal
import Evergreen.V75.Bounds
import Evergreen.V75.Change
import Evergreen.V75.Cursor
import Evergreen.V75.Grid
import Evergreen.V75.Id
import Evergreen.V75.IdDict
import Evergreen.V75.MailEditor
import Evergreen.V75.Train
import Evergreen.V75.Units
import Evergreen.V75.User


type alias LocalGrid_ =
    { grid : Evergreen.V75.Grid.Grid
    , userStatus : Evergreen.V75.Change.UserStatus
    , viewBounds : Evergreen.V75.Bounds.Bounds Evergreen.V75.Units.CellUnit
    , animals : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.AnimalId Evergreen.V75.Animal.Animal
    , cursors : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Evergreen.V75.Cursor.Cursor
    , users : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Evergreen.V75.User.FrontendUser
    , inviteTree : Evergreen.V75.User.InviteTree
    , mail : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.MailId Evergreen.V75.MailEditor.FrontendMail
    , trains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , trainsDisabled : Evergreen.V75.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
