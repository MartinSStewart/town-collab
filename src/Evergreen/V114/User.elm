module Evergreen.V114.User exposing (..)

import Evergreen.V114.Color
import Evergreen.V114.DisplayName
import Evergreen.V114.Id


type alias FrontendUser =
    { name : Evergreen.V114.DisplayName.DisplayName
    , handColor : Evergreen.V114.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        , invited : List InviteTree
        }
