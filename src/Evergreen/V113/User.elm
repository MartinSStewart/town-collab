module Evergreen.V113.User exposing (..)

import Evergreen.V113.Color
import Evergreen.V113.DisplayName
import Evergreen.V113.Id


type alias FrontendUser =
    { name : Evergreen.V113.DisplayName.DisplayName
    , handColor : Evergreen.V113.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        , invited : List InviteTree
        }
