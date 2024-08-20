module Evergreen.V134.User exposing (..)

import Evergreen.V134.Color
import Evergreen.V134.DisplayName
import Evergreen.V134.Id


type alias FrontendUser =
    { name : Evergreen.V134.DisplayName.DisplayName
    , handColor : Evergreen.V134.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , invited : List InviteTree
        }
