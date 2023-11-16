module Evergreen.V115.User exposing (..)

import Evergreen.V115.Color
import Evergreen.V115.DisplayName
import Evergreen.V115.Id


type alias FrontendUser =
    { name : Evergreen.V115.DisplayName.DisplayName
    , handColor : Evergreen.V115.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , invited : List InviteTree
        }
