module Evergreen.V112.User exposing (..)

import Evergreen.V112.Color
import Evergreen.V112.DisplayName
import Evergreen.V112.Id


type alias FrontendUser =
    { name : Evergreen.V112.DisplayName.DisplayName
    , handColor : Evergreen.V112.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , invited : List InviteTree
        }
