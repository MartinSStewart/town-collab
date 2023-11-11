module Evergreen.V110.User exposing (..)

import Evergreen.V110.Color
import Evergreen.V110.DisplayName
import Evergreen.V110.Id


type alias FrontendUser =
    { name : Evergreen.V110.DisplayName.DisplayName
    , handColor : Evergreen.V110.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
        , invited : List InviteTree
        }
