module Evergreen.V100.LocalGrid exposing (..)

import Evergreen.V100.Animal
import Evergreen.V100.Bounds
import Evergreen.V100.Change
import Evergreen.V100.Cursor
import Evergreen.V100.Grid
import Evergreen.V100.Id
import Evergreen.V100.IdDict
import Evergreen.V100.MailEditor
import Evergreen.V100.Train
import Evergreen.V100.Units
import Evergreen.V100.User


type alias LocalGrid_ =
    { grid : Evergreen.V100.Grid.Grid
    , userStatus : Evergreen.V100.Change.UserStatus
    , viewBounds : Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit)
    , animals : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.AnimalId Evergreen.V100.Animal.Animal
    , cursors : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Evergreen.V100.Cursor.Cursor
    , users : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Evergreen.V100.User.FrontendUser
    , inviteTree : Evergreen.V100.User.InviteTree
    , mail : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.MailId Evergreen.V100.MailEditor.FrontendMail
    , trains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , trainsDisabled : Evergreen.V100.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
