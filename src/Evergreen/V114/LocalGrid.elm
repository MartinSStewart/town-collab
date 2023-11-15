module Evergreen.V114.LocalGrid exposing (..)

import Evergreen.V114.Animal
import Evergreen.V114.Bounds
import Evergreen.V114.Change
import Evergreen.V114.Cursor
import Evergreen.V114.Grid
import Evergreen.V114.GridCell
import Evergreen.V114.Id
import Evergreen.V114.IdDict
import Evergreen.V114.MailEditor
import Evergreen.V114.Train
import Evergreen.V114.Units
import Evergreen.V114.User


type alias LocalGrid_ =
    { grid : Evergreen.V114.Grid.Grid Evergreen.V114.GridCell.FrontendHistory
    , userStatus : Evergreen.V114.Change.UserStatus
    , viewBounds : Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit)
    , animals : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.AnimalId Evergreen.V114.Animal.Animal
    , cursors : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Evergreen.V114.Cursor.Cursor
    , users : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Evergreen.V114.User.FrontendUser
    , inviteTree : Evergreen.V114.User.InviteTree
    , mail : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.MailId Evergreen.V114.MailEditor.FrontendMail
    , trains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , trainsDisabled : Evergreen.V114.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
