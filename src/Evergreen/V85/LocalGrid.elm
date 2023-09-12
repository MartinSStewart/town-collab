module Evergreen.V85.LocalGrid exposing (..)

import Evergreen.V85.Animal
import Evergreen.V85.Bounds
import Evergreen.V85.Change
import Evergreen.V85.Cursor
import Evergreen.V85.Grid
import Evergreen.V85.Id
import Evergreen.V85.IdDict
import Evergreen.V85.MailEditor
import Evergreen.V85.Train
import Evergreen.V85.Units
import Evergreen.V85.User


type alias LocalGrid_ =
    { grid : Evergreen.V85.Grid.Grid
    , userStatus : Evergreen.V85.Change.UserStatus
    , viewBounds : Evergreen.V85.Bounds.Bounds Evergreen.V85.Units.CellUnit
    , animals : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.AnimalId Evergreen.V85.Animal.Animal
    , cursors : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Evergreen.V85.Cursor.Cursor
    , users : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Evergreen.V85.User.FrontendUser
    , inviteTree : Evergreen.V85.User.InviteTree
    , mail : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.MailId Evergreen.V85.MailEditor.FrontendMail
    , trains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , trainsDisabled : Evergreen.V85.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
