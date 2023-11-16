module Evergreen.V115.LocalGrid exposing (..)

import Evergreen.V115.Animal
import Evergreen.V115.Bounds
import Evergreen.V115.Change
import Evergreen.V115.Cursor
import Evergreen.V115.Grid
import Evergreen.V115.GridCell
import Evergreen.V115.Id
import Evergreen.V115.IdDict
import Evergreen.V115.MailEditor
import Evergreen.V115.Train
import Evergreen.V115.Units
import Evergreen.V115.User


type alias LocalGrid_ =
    { grid : Evergreen.V115.Grid.Grid Evergreen.V115.GridCell.FrontendHistory
    , userStatus : Evergreen.V115.Change.UserStatus
    , viewBounds : Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit)
    , animals : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.AnimalId Evergreen.V115.Animal.Animal
    , cursors : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Evergreen.V115.Cursor.Cursor
    , users : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Evergreen.V115.User.FrontendUser
    , inviteTree : Evergreen.V115.User.InviteTree
    , mail : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.MailId Evergreen.V115.MailEditor.FrontendMail
    , trains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , trainsDisabled : Evergreen.V115.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
