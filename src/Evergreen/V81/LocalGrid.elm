module Evergreen.V81.LocalGrid exposing (..)

import Evergreen.V81.Animal
import Evergreen.V81.Bounds
import Evergreen.V81.Change
import Evergreen.V81.Cursor
import Evergreen.V81.Grid
import Evergreen.V81.Id
import Evergreen.V81.IdDict
import Evergreen.V81.MailEditor
import Evergreen.V81.Train
import Evergreen.V81.Units
import Evergreen.V81.User


type alias LocalGrid_ =
    { grid : Evergreen.V81.Grid.Grid
    , userStatus : Evergreen.V81.Change.UserStatus
    , viewBounds : Evergreen.V81.Bounds.Bounds Evergreen.V81.Units.CellUnit
    , animals : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.AnimalId Evergreen.V81.Animal.Animal
    , cursors : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Evergreen.V81.Cursor.Cursor
    , users : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Evergreen.V81.User.FrontendUser
    , inviteTree : Evergreen.V81.User.InviteTree
    , mail : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.MailId Evergreen.V81.MailEditor.FrontendMail
    , trains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , trainsDisabled : Evergreen.V81.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
