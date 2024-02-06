module Evergreen.V124.LocalGrid exposing (..)

import Evergreen.V124.Animal
import Evergreen.V124.Bounds
import Evergreen.V124.Change
import Evergreen.V124.Cursor
import Evergreen.V124.Grid
import Evergreen.V124.GridCell
import Evergreen.V124.Id
import Evergreen.V124.IdDict
import Evergreen.V124.MailEditor
import Evergreen.V124.Train
import Evergreen.V124.Units
import Evergreen.V124.User


type alias LocalGrid_ =
    { grid : Evergreen.V124.Grid.Grid Evergreen.V124.GridCell.FrontendHistory
    , userStatus : Evergreen.V124.Change.UserStatus
    , viewBounds : Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit)
    , animals : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.AnimalId Evergreen.V124.Animal.Animal
    , cursors : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Evergreen.V124.Cursor.Cursor
    , users : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Evergreen.V124.User.FrontendUser
    , inviteTree : Evergreen.V124.User.InviteTree
    , mail : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.MailId Evergreen.V124.MailEditor.FrontendMail
    , trains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , trainsDisabled : Evergreen.V124.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
