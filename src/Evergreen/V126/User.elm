module Evergreen.V126.User exposing (..)

import Evergreen.V126.Color
import Evergreen.V126.DisplayName
import Evergreen.V126.Id


type alias FrontendUser =
    { name : Evergreen.V126.DisplayName.DisplayName
    , handColor : Evergreen.V126.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        , invited : List InviteTree
        }
