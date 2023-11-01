module Evergreen.V95.User exposing (..)

import Evergreen.V95.Color
import Evergreen.V95.DisplayName
import Evergreen.V95.Id


type alias FrontendUser =
    { name : Evergreen.V95.DisplayName.DisplayName
    , handColor : Evergreen.V95.Color.Colors
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , invited : List InviteTree
        }
