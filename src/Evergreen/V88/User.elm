module Evergreen.V88.User exposing (..)

import Evergreen.V88.Color
import Evergreen.V88.Cursor
import Evergreen.V88.DisplayName
import Evergreen.V88.Id


type alias FrontendUser =
    { name : Evergreen.V88.DisplayName.DisplayName
    , handColor : Evergreen.V88.Color.Colors
    , cursor : Maybe Evergreen.V88.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , invited : List InviteTree
        }
