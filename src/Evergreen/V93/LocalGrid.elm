module Evergreen.V93.LocalGrid exposing (..)

import Evergreen.V93.Animal
import Evergreen.V93.Bounds
import Evergreen.V93.Change
import Evergreen.V93.Cursor
import Evergreen.V93.Grid
import Evergreen.V93.Id
import Evergreen.V93.IdDict
import Evergreen.V93.MailEditor
import Evergreen.V93.Train
import Evergreen.V93.Units
import Evergreen.V93.User


type alias LocalGrid_ =
    { grid : Evergreen.V93.Grid.Grid
    , userStatus : Evergreen.V93.Change.UserStatus
    , viewBounds : Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit)
    , animals : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.AnimalId Evergreen.V93.Animal.Animal
    , cursors : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Evergreen.V93.Cursor.Cursor
    , users : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Evergreen.V93.User.FrontendUser
    , inviteTree : Evergreen.V93.User.InviteTree
    , mail : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.MailId Evergreen.V93.MailEditor.FrontendMail
    , trains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , trainsDisabled : Evergreen.V93.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
