module Evergreen.V97.LocalGrid exposing (..)

import Evergreen.V97.Animal
import Evergreen.V97.Bounds
import Evergreen.V97.Change
import Evergreen.V97.Cursor
import Evergreen.V97.Grid
import Evergreen.V97.Id
import Evergreen.V97.IdDict
import Evergreen.V97.MailEditor
import Evergreen.V97.Train
import Evergreen.V97.Units
import Evergreen.V97.User


type alias LocalGrid_ =
    { grid : Evergreen.V97.Grid.Grid
    , userStatus : Evergreen.V97.Change.UserStatus
    , viewBounds : Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit)
    , animals : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.AnimalId Evergreen.V97.Animal.Animal
    , cursors : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Evergreen.V97.Cursor.Cursor
    , users : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Evergreen.V97.User.FrontendUser
    , inviteTree : Evergreen.V97.User.InviteTree
    , mail : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.MailId Evergreen.V97.MailEditor.FrontendMail
    , trains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , trainsDisabled : Evergreen.V97.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
