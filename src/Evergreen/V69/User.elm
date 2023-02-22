module Evergreen.V69.User exposing (..)

import Evergreen.V69.Color
import Evergreen.V69.Cursor
import Evergreen.V69.DisplayName
import Evergreen.V69.Id


type alias FrontendUser =
    { name : Evergreen.V69.DisplayName.DisplayName
    , handColor : Evergreen.V69.Color.Colors
    , cursor : Maybe Evergreen.V69.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , invited : List InviteTree
        }
