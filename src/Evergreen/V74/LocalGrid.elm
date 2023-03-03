module Evergreen.V74.LocalGrid exposing (..)

import Evergreen.V74.Animal
import Evergreen.V74.Bounds
import Evergreen.V74.Change
import Evergreen.V74.Cursor
import Evergreen.V74.Grid
import Evergreen.V74.Id
import Evergreen.V74.IdDict
import Evergreen.V74.MailEditor
import Evergreen.V74.Train
import Evergreen.V74.Units
import Evergreen.V74.User


type alias LocalGrid_ =
    { grid : Evergreen.V74.Grid.Grid
    , userStatus : Evergreen.V74.Change.UserStatus
    , viewBounds : Evergreen.V74.Bounds.Bounds Evergreen.V74.Units.CellUnit
    , animals : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.AnimalId Evergreen.V74.Animal.Animal
    , cursors : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Evergreen.V74.Cursor.Cursor
    , users : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Evergreen.V74.User.FrontendUser
    , inviteTree : Evergreen.V74.User.InviteTree
    , mail : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.MailId Evergreen.V74.MailEditor.FrontendMail
    , trains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , trainsDisabled : Evergreen.V74.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
