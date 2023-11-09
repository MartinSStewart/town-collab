module Evergreen.V109.User exposing (..)

import Evergreen.V109.Color
import Evergreen.V109.DisplayName
import Evergreen.V109.Id


type alias FrontendUser =
    { name : Evergreen.V109.DisplayName.DisplayName
    , handColor : Evergreen.V109.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , invited : List InviteTree
        }
