module Evergreen.V116.LocalGrid exposing (..)

import Evergreen.V116.Animal
import Evergreen.V116.Bounds
import Evergreen.V116.Change
import Evergreen.V116.Cursor
import Evergreen.V116.Grid
import Evergreen.V116.GridCell
import Evergreen.V116.Id
import Evergreen.V116.IdDict
import Evergreen.V116.MailEditor
import Evergreen.V116.Train
import Evergreen.V116.Units
import Evergreen.V116.User


type alias LocalGrid_ =
    { grid : Evergreen.V116.Grid.Grid Evergreen.V116.GridCell.FrontendHistory
    , userStatus : Evergreen.V116.Change.UserStatus
    , viewBounds : Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit)
    , animals : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.AnimalId Evergreen.V116.Animal.Animal
    , cursors : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Evergreen.V116.Cursor.Cursor
    , users : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Evergreen.V116.User.FrontendUser
    , inviteTree : Evergreen.V116.User.InviteTree
    , mail : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.MailId Evergreen.V116.MailEditor.FrontendMail
    , trains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , trainsDisabled : Evergreen.V116.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
