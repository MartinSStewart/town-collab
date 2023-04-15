module Evergreen.V75.User exposing (..)

import Evergreen.V75.Color
import Evergreen.V75.Cursor
import Evergreen.V75.DisplayName
import Evergreen.V75.Id


type alias FrontendUser =
    { name : Evergreen.V75.DisplayName.DisplayName
    , handColor : Evergreen.V75.Color.Colors
    , cursor : Maybe Evergreen.V75.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , invited : List InviteTree
        }
