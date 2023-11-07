module Evergreen.V108.User exposing (..)

import Evergreen.V108.Color
import Evergreen.V108.DisplayName
import Evergreen.V108.Id


type alias FrontendUser =
    { name : Evergreen.V108.DisplayName.DisplayName
    , handColor : Evergreen.V108.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , invited : List InviteTree
        }
