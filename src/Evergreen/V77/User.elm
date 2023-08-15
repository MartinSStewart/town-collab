module Evergreen.V77.User exposing (..)

import Evergreen.V77.Color
import Evergreen.V77.Cursor
import Evergreen.V77.DisplayName
import Evergreen.V77.Id


type alias FrontendUser =
    { name : Evergreen.V77.DisplayName.DisplayName
    , handColor : Evergreen.V77.Color.Colors
    , cursor : Maybe Evergreen.V77.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , invited : List InviteTree
        }
