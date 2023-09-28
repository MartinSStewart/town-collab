module Evergreen.V89.User exposing (..)

import Evergreen.V89.Color
import Evergreen.V89.Cursor
import Evergreen.V89.DisplayName
import Evergreen.V89.Id


type alias FrontendUser =
    { name : Evergreen.V89.DisplayName.DisplayName
    , handColor : Evergreen.V89.Color.Colors
    , cursor : Maybe Evergreen.V89.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        , invited : List InviteTree
        }
