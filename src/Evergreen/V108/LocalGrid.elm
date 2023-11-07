module Evergreen.V108.LocalGrid exposing (..)

import Evergreen.V108.Animal
import Evergreen.V108.Bounds
import Evergreen.V108.Change
import Evergreen.V108.Cursor
import Evergreen.V108.Grid
import Evergreen.V108.GridCell
import Evergreen.V108.Id
import Evergreen.V108.IdDict
import Evergreen.V108.MailEditor
import Evergreen.V108.Train
import Evergreen.V108.Units
import Evergreen.V108.User


type alias LocalGrid_ =
    { grid : Evergreen.V108.Grid.Grid Evergreen.V108.GridCell.FrontendHistory
    , userStatus : Evergreen.V108.Change.UserStatus
    , viewBounds : Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit)
    , animals : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.AnimalId Evergreen.V108.Animal.Animal
    , cursors : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Evergreen.V108.Cursor.Cursor
    , users : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Evergreen.V108.User.FrontendUser
    , inviteTree : Evergreen.V108.User.InviteTree
    , mail : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.MailId Evergreen.V108.MailEditor.FrontendMail
    , trains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , trainsDisabled : Evergreen.V108.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
