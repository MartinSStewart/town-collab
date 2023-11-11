module Evergreen.V111.LocalGrid exposing (..)

import Evergreen.V111.Animal
import Evergreen.V111.Bounds
import Evergreen.V111.Change
import Evergreen.V111.Cursor
import Evergreen.V111.Grid
import Evergreen.V111.GridCell
import Evergreen.V111.Id
import Evergreen.V111.IdDict
import Evergreen.V111.MailEditor
import Evergreen.V111.Train
import Evergreen.V111.Units
import Evergreen.V111.User


type alias LocalGrid_ =
    { grid : Evergreen.V111.Grid.Grid Evergreen.V111.GridCell.FrontendHistory
    , userStatus : Evergreen.V111.Change.UserStatus
    , viewBounds : Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit)
    , animals : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.AnimalId Evergreen.V111.Animal.Animal
    , cursors : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Evergreen.V111.Cursor.Cursor
    , users : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Evergreen.V111.User.FrontendUser
    , inviteTree : Evergreen.V111.User.InviteTree
    , mail : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.MailId Evergreen.V111.MailEditor.FrontendMail
    , trains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , trainsDisabled : Evergreen.V111.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
