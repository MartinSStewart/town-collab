module Evergreen.V126.LocalGrid exposing (..)

import Evergreen.V126.Animal
import Evergreen.V126.Bounds
import Evergreen.V126.Change
import Evergreen.V126.Cursor
import Evergreen.V126.Grid
import Evergreen.V126.GridCell
import Evergreen.V126.Id
import Evergreen.V126.IdDict
import Evergreen.V126.MailEditor
import Evergreen.V126.Npc
import Evergreen.V126.Train
import Evergreen.V126.Units
import Evergreen.V126.User


type alias LocalGrid =
    { grid : Evergreen.V126.Grid.Grid Evergreen.V126.GridCell.FrontendHistory
    , userStatus : Evergreen.V126.Change.UserStatus
    , viewBounds : Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit)
    , animals : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.AnimalId Evergreen.V126.Animal.Animal
    , cursors : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Evergreen.V126.Cursor.Cursor
    , users : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Evergreen.V126.User.FrontendUser
    , inviteTree : Evergreen.V126.User.InviteTree
    , mail : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.MailId Evergreen.V126.MailEditor.FrontendMail
    , trains : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.TrainId Evergreen.V126.Train.Train
    , trainsDisabled : Evergreen.V126.Change.AreTrainsAndAnimalsDisabled
    , npcs : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.NpcId Evergreen.V126.Npc.Npc
    }
