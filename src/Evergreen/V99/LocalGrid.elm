module Evergreen.V99.LocalGrid exposing (..)

import Evergreen.V99.Animal
import Evergreen.V99.Bounds
import Evergreen.V99.Change
import Evergreen.V99.Cursor
import Evergreen.V99.Grid
import Evergreen.V99.Id
import Evergreen.V99.IdDict
import Evergreen.V99.MailEditor
import Evergreen.V99.Train
import Evergreen.V99.Units
import Evergreen.V99.User


type alias LocalGrid_ =
    { grid : Evergreen.V99.Grid.Grid
    , userStatus : Evergreen.V99.Change.UserStatus
    , viewBounds : Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit)
    , animals : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.AnimalId Evergreen.V99.Animal.Animal
    , cursors : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Evergreen.V99.Cursor.Cursor
    , users : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Evergreen.V99.User.FrontendUser
    , inviteTree : Evergreen.V99.User.InviteTree
    , mail : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.MailId Evergreen.V99.MailEditor.FrontendMail
    , trains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , trainsDisabled : Evergreen.V99.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
