module Evergreen.V81.User exposing (..)

import Evergreen.V81.Color
import Evergreen.V81.Cursor
import Evergreen.V81.DisplayName
import Evergreen.V81.Id


type alias FrontendUser =
    { name : Evergreen.V81.DisplayName.DisplayName
    , handColor : Evergreen.V81.Color.Colors
    , cursor : Maybe Evergreen.V81.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , invited : List InviteTree
        }
