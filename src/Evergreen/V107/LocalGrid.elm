module Evergreen.V107.LocalGrid exposing (..)

import Evergreen.V107.Animal
import Evergreen.V107.Bounds
import Evergreen.V107.Change
import Evergreen.V107.Cursor
import Evergreen.V107.Grid
import Evergreen.V107.GridCell
import Evergreen.V107.Id
import Evergreen.V107.IdDict
import Evergreen.V107.MailEditor
import Evergreen.V107.Train
import Evergreen.V107.Units
import Evergreen.V107.User


type alias LocalGrid_ =
    { grid : Evergreen.V107.Grid.Grid Evergreen.V107.GridCell.FrontendHistory
    , userStatus : Evergreen.V107.Change.UserStatus
    , viewBounds : Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit)
    , animals : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.AnimalId Evergreen.V107.Animal.Animal
    , cursors : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Evergreen.V107.Cursor.Cursor
    , users : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Evergreen.V107.User.FrontendUser
    , inviteTree : Evergreen.V107.User.InviteTree
    , mail : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.MailId Evergreen.V107.MailEditor.FrontendMail
    , trains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , trainsDisabled : Evergreen.V107.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
