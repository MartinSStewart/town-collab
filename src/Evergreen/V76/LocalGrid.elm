module Evergreen.V76.LocalGrid exposing (..)

import Evergreen.V76.Animal
import Evergreen.V76.Bounds
import Evergreen.V76.Change
import Evergreen.V76.Cursor
import Evergreen.V76.Grid
import Evergreen.V76.Id
import Evergreen.V76.IdDict
import Evergreen.V76.MailEditor
import Evergreen.V76.Train
import Evergreen.V76.Units
import Evergreen.V76.User


type alias LocalGrid_ =
    { grid : Evergreen.V76.Grid.Grid
    , userStatus : Evergreen.V76.Change.UserStatus
    , viewBounds : Evergreen.V76.Bounds.Bounds Evergreen.V76.Units.CellUnit
    , animals : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.AnimalId Evergreen.V76.Animal.Animal
    , cursors : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Evergreen.V76.Cursor.Cursor
    , users : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Evergreen.V76.User.FrontendUser
    , inviteTree : Evergreen.V76.User.InviteTree
    , mail : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.MailId Evergreen.V76.MailEditor.FrontendMail
    , trains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , trainsDisabled : Evergreen.V76.Change.AreTrainsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
