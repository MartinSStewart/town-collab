module Evergreen.V95.LocalGrid exposing (..)

import Evergreen.V95.Animal
import Evergreen.V95.Bounds
import Evergreen.V95.Change
import Evergreen.V95.Cursor
import Evergreen.V95.Grid
import Evergreen.V95.Id
import Evergreen.V95.IdDict
import Evergreen.V95.MailEditor
import Evergreen.V95.Train
import Evergreen.V95.Units
import Evergreen.V95.User


type alias LocalGrid_ =
    { grid : Evergreen.V95.Grid.Grid
    , userStatus : Evergreen.V95.Change.UserStatus
    , viewBounds : Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit)
    , animals : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.AnimalId Evergreen.V95.Animal.Animal
    , cursors : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Evergreen.V95.Cursor.Cursor
    , users : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Evergreen.V95.User.FrontendUser
    , inviteTree : Evergreen.V95.User.InviteTree
    , mail : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.MailId Evergreen.V95.MailEditor.FrontendMail
    , trains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , trainsDisabled : Evergreen.V95.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
