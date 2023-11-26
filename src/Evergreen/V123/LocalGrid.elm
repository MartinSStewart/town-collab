module Evergreen.V123.LocalGrid exposing (..)

import Evergreen.V123.Animal
import Evergreen.V123.Bounds
import Evergreen.V123.Change
import Evergreen.V123.Cursor
import Evergreen.V123.Grid
import Evergreen.V123.GridCell
import Evergreen.V123.Id
import Evergreen.V123.IdDict
import Evergreen.V123.MailEditor
import Evergreen.V123.Train
import Evergreen.V123.Units
import Evergreen.V123.User


type alias LocalGrid_ =
    { grid : Evergreen.V123.Grid.Grid Evergreen.V123.GridCell.FrontendHistory
    , userStatus : Evergreen.V123.Change.UserStatus
    , viewBounds : Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit)
    , animals : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.AnimalId Evergreen.V123.Animal.Animal
    , cursors : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Evergreen.V123.Cursor.Cursor
    , users : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Evergreen.V123.User.FrontendUser
    , inviteTree : Evergreen.V123.User.InviteTree
    , mail : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.MailId Evergreen.V123.MailEditor.FrontendMail
    , trains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , trainsDisabled : Evergreen.V123.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
