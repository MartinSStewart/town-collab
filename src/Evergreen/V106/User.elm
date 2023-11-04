module Evergreen.V106.User exposing (..)

import Evergreen.V106.Color
import Evergreen.V106.DisplayName
import Evergreen.V106.Id


type alias FrontendUser =
    { name : Evergreen.V106.DisplayName.DisplayName
    , handColor : Evergreen.V106.Color.Colors
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , invited : List InviteTree
        }
