module Evergreen.V111.User exposing (..)

import Evergreen.V111.Color
import Evergreen.V111.DisplayName
import Evergreen.V111.Id


type alias FrontendUser =
    { name : Evergreen.V111.DisplayName.DisplayName
    , handColor : Evergreen.V111.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        , invited : List InviteTree
        }
