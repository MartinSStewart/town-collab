module Evergreen.V83.User exposing (..)

import Evergreen.V83.Color
import Evergreen.V83.Cursor
import Evergreen.V83.DisplayName
import Evergreen.V83.Id


type alias FrontendUser =
    { name : Evergreen.V83.DisplayName.DisplayName
    , handColor : Evergreen.V83.Color.Colors
    , cursor : Maybe Evergreen.V83.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , invited : List InviteTree
        }
