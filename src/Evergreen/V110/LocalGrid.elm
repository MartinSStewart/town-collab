module Evergreen.V110.LocalGrid exposing (..)

import Evergreen.V110.Animal
import Evergreen.V110.Bounds
import Evergreen.V110.Change
import Evergreen.V110.Cursor
import Evergreen.V110.Grid
import Evergreen.V110.GridCell
import Evergreen.V110.Id
import Evergreen.V110.IdDict
import Evergreen.V110.MailEditor
import Evergreen.V110.Train
import Evergreen.V110.Units
import Evergreen.V110.User


type alias LocalGrid_ =
    { grid : Evergreen.V110.Grid.Grid Evergreen.V110.GridCell.FrontendHistory
    , userStatus : Evergreen.V110.Change.UserStatus
    , viewBounds : Evergreen.V110.Bounds.Bounds Evergreen.V110.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V110.Bounds.Bounds Evergreen.V110.Units.CellUnit)
    , animals : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.AnimalId Evergreen.V110.Animal.Animal
    , cursors : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.UserId Evergreen.V110.Cursor.Cursor
    , users : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.UserId Evergreen.V110.User.FrontendUser
    , inviteTree : Evergreen.V110.User.InviteTree
    , mail : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.MailId Evergreen.V110.MailEditor.FrontendMail
    , trains : Evergreen.V110.IdDict.IdDict Evergreen.V110.Id.TrainId Evergreen.V110.Train.Train
    , trainsDisabled : Evergreen.V110.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
