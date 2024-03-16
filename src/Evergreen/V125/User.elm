module Evergreen.V125.User exposing (..)

import Evergreen.V125.Color
import Evergreen.V125.DisplayName
import Evergreen.V125.Id


type alias FrontendUser =
    { name : Evergreen.V125.DisplayName.DisplayName
    , handColor : Evergreen.V125.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , invited : List InviteTree
        }
