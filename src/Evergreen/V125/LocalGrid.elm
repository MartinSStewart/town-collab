module Evergreen.V125.LocalGrid exposing (..)

import Evergreen.V125.Animal
import Evergreen.V125.Bounds
import Evergreen.V125.Change
import Evergreen.V125.Cursor
import Evergreen.V125.Grid
import Evergreen.V125.GridCell
import Evergreen.V125.Id
import Evergreen.V125.IdDict
import Evergreen.V125.MailEditor
import Evergreen.V125.Train
import Evergreen.V125.Units
import Evergreen.V125.User


type alias LocalGrid_ =
    { grid : Evergreen.V125.Grid.Grid Evergreen.V125.GridCell.FrontendHistory
    , userStatus : Evergreen.V125.Change.UserStatus
    , viewBounds : Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit)
    , animals : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.AnimalId Evergreen.V125.Animal.Animal
    , cursors : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Evergreen.V125.Cursor.Cursor
    , users : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Evergreen.V125.User.FrontendUser
    , inviteTree : Evergreen.V125.User.InviteTree
    , mail : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.MailId Evergreen.V125.MailEditor.FrontendMail
    , trains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , trainsDisabled : Evergreen.V125.Change.AreTrainsAndAnimalsDisabled
    }


type LocalGrid
    = LocalGrid LocalGrid_
