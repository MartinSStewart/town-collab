module Evergreen.V72.User exposing (..)

import Evergreen.V72.Color
import Evergreen.V72.Cursor
import Evergreen.V72.DisplayName
import Evergreen.V72.Id


type alias FrontendUser =
    { name : Evergreen.V72.DisplayName.DisplayName
    , handColor : Evergreen.V72.Color.Colors
    , cursor : Maybe Evergreen.V72.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , invited : List InviteTree
        }
