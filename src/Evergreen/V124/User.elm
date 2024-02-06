module Evergreen.V124.User exposing (..)

import Evergreen.V124.Color
import Evergreen.V124.DisplayName
import Evergreen.V124.Id


type alias FrontendUser =
    { name : Evergreen.V124.DisplayName.DisplayName
    , handColor : Evergreen.V124.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , invited : List InviteTree
        }
