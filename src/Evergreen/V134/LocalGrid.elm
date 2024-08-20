module Evergreen.V134.LocalGrid exposing (..)

import Evergreen.V134.Animal
import Evergreen.V134.Bounds
import Evergreen.V134.Change
import Evergreen.V134.Cursor
import Evergreen.V134.Grid
import Evergreen.V134.GridCell
import Evergreen.V134.Id
import Evergreen.V134.MailEditor
import Evergreen.V134.Npc
import Evergreen.V134.Train
import Evergreen.V134.Units
import Evergreen.V134.User
import SeqDict


type alias LocalGrid =
    { grid : Evergreen.V134.Grid.Grid Evergreen.V134.GridCell.FrontendHistory
    , userStatus : Evergreen.V134.Change.UserStatus
    , viewBounds : Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit
    , previewBounds : Maybe (Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit)
    , animals : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId) Evergreen.V134.Animal.Animal
    , cursors : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Cursor.Cursor
    , users : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.FrontendUser
    , inviteTree : Evergreen.V134.User.InviteTree
    , mail : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.FrontendMail
    , trains : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Evergreen.V134.Train.Train
    , trainsDisabled : Evergreen.V134.Change.AreTrainsAndAnimalsDisabled
    , npcs : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId) Evergreen.V134.Npc.Npc
    }
