module Evergreen.V116.User exposing (..)

import Evergreen.V116.Color
import Evergreen.V116.DisplayName
import Evergreen.V116.Id


type alias FrontendUser =
    { name : Evergreen.V116.DisplayName.DisplayName
    , handColor : Evergreen.V116.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , invited : List InviteTree
        }
