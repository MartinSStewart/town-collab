module Evergreen.V113.LocalGrid exposing (..)

import Evergreen.V113.Animal
import Evergreen.V113.Bounds
import Evergreen.V113.Change
import Evergreen.V113.Cursor
import Evergreen.V113.Grid
import Evergreen.V113.GridCell
import Evergreen.V113.Id
import Evergreen.V113.IdDict
import Evergreen.V113.MailEditor
import Evergreen.V113.Train
import Evergreen.V113.Units
import Evergreen.V113.User


type alias LocalGrid_ =
    { grid : Evergreen.V113.Grid.Grid Evergreen.V113.GridCell.FrontendHistory
    , userStatus : Evergreen.V113.Change.UserStatus
    , viewBounds : Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit)
    , animals : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.AnimalId Evergreen.V113.Animal.Animal
    , cursors : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Evergreen.V113.Cursor.Cursor
    , users : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Evergreen.V113.User.FrontendUser
    , inviteTree : Evergreen.V113.User.InviteTree
    , mail : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.MailId Evergreen.V113.MailEditor.FrontendMail
    , trains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , trainsDisabled : Evergreen.V113.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
