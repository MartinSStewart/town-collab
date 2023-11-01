module Evergreen.V97.User exposing (..)

import Evergreen.V97.Color
import Evergreen.V97.DisplayName
import Evergreen.V97.Id


type alias FrontendUser =
    { name : Evergreen.V97.DisplayName.DisplayName
    , handColor : Evergreen.V97.Color.Colors
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , invited : List InviteTree
        }
