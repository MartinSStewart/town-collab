module Evergreen.V109.LocalGrid exposing (..)

import Evergreen.V109.Animal
import Evergreen.V109.Bounds
import Evergreen.V109.Change
import Evergreen.V109.Cursor
import Evergreen.V109.Grid
import Evergreen.V109.GridCell
import Evergreen.V109.Id
import Evergreen.V109.IdDict
import Evergreen.V109.MailEditor
import Evergreen.V109.Train
import Evergreen.V109.Units
import Evergreen.V109.User


type alias LocalGrid_ =
    { grid : Evergreen.V109.Grid.Grid Evergreen.V109.GridCell.FrontendHistory
    , userStatus : Evergreen.V109.Change.UserStatus
    , viewBounds : Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit)
    , animals : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.AnimalId Evergreen.V109.Animal.Animal
    , cursors : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Evergreen.V109.Cursor.Cursor
    , users : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Evergreen.V109.User.FrontendUser
    , inviteTree : Evergreen.V109.User.InviteTree
    , mail : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.MailId Evergreen.V109.MailEditor.FrontendMail
    , trains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , trainsDisabled : Evergreen.V109.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
