module Evergreen.V83.LocalGrid exposing (..)

import Evergreen.V83.Animal
import Evergreen.V83.Bounds
import Evergreen.V83.Change
import Evergreen.V83.Cursor
import Evergreen.V83.Grid
import Evergreen.V83.Id
import Evergreen.V83.IdDict
import Evergreen.V83.MailEditor
import Evergreen.V83.Train
import Evergreen.V83.Units
import Evergreen.V83.User


type alias LocalGrid_ =
    { grid : Evergreen.V83.Grid.Grid
    , userStatus : Evergreen.V83.Change.UserStatus
    , viewBounds : Evergreen.V83.Bounds.Bounds Evergreen.V83.Units.CellUnit
    , animals : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.AnimalId Evergreen.V83.Animal.Animal
    , cursors : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Evergreen.V83.Cursor.Cursor
    , users : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Evergreen.V83.User.FrontendUser
    , inviteTree : Evergreen.V83.User.InviteTree
    , mail : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.MailId Evergreen.V83.MailEditor.FrontendMail
    , trains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , trainsDisabled : Evergreen.V83.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
