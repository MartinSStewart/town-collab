module Evergreen.V123.User exposing (..)

import Evergreen.V123.Color
import Evergreen.V123.DisplayName
import Evergreen.V123.Id


type alias FrontendUser =
    { name : Evergreen.V123.DisplayName.DisplayName
    , handColor : Evergreen.V123.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        , invited : List InviteTree
        }
