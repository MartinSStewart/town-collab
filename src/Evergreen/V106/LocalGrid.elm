module Evergreen.V106.LocalGrid exposing (..)

import Evergreen.V106.Animal
import Evergreen.V106.Bounds
import Evergreen.V106.Change
import Evergreen.V106.Cursor
import Evergreen.V106.Grid
import Evergreen.V106.GridCell
import Evergreen.V106.Id
import Evergreen.V106.IdDict
import Evergreen.V106.MailEditor
import Evergreen.V106.Train
import Evergreen.V106.Units
import Evergreen.V106.User


type alias LocalGrid_ =
    { grid : Evergreen.V106.Grid.Grid Evergreen.V106.GridCell.FrontendHistory
    , userStatus : Evergreen.V106.Change.UserStatus
    , viewBounds : Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit)
    , animals : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.AnimalId Evergreen.V106.Animal.Animal
    , cursors : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Evergreen.V106.Cursor.Cursor
    , users : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Evergreen.V106.User.FrontendUser
    , inviteTree : Evergreen.V106.User.InviteTree
    , mail : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.MailId Evergreen.V106.MailEditor.FrontendMail
    , trains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , trainsDisabled : Evergreen.V106.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
