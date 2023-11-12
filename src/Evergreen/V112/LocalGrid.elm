module Evergreen.V112.LocalGrid exposing (..)

import Evergreen.V112.Animal
import Evergreen.V112.Bounds
import Evergreen.V112.Change
import Evergreen.V112.Cursor
import Evergreen.V112.Grid
import Evergreen.V112.GridCell
import Evergreen.V112.Id
import Evergreen.V112.IdDict
import Evergreen.V112.MailEditor
import Evergreen.V112.Train
import Evergreen.V112.Units
import Evergreen.V112.User


type alias LocalGrid_ =
    { grid : Evergreen.V112.Grid.Grid Evergreen.V112.GridCell.FrontendHistory
    , userStatus : Evergreen.V112.Change.UserStatus
    , viewBounds : Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit)
    , animals : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.AnimalId Evergreen.V112.Animal.Animal
    , cursors : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Evergreen.V112.Cursor.Cursor
    , users : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Evergreen.V112.User.FrontendUser
    , inviteTree : Evergreen.V112.User.InviteTree
    , mail : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.MailId Evergreen.V112.MailEditor.FrontendMail
    , trains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , trainsDisabled : Evergreen.V112.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
