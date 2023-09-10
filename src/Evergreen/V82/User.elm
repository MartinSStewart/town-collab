module Evergreen.V82.User exposing (..)

import Evergreen.V82.Color
import Evergreen.V82.Cursor
import Evergreen.V82.DisplayName
import Evergreen.V82.Id


type alias FrontendUser =
    { name : Evergreen.V82.DisplayName.DisplayName
    , handColor : Evergreen.V82.Color.Colors
    , cursor : Maybe Evergreen.V82.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , invited : List InviteTree
        }
