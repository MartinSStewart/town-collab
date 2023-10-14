module Evergreen.V93.User exposing (..)

import Evergreen.V93.Color
import Evergreen.V93.DisplayName
import Evergreen.V93.Id


type alias FrontendUser =
    { name : Evergreen.V93.DisplayName.DisplayName
    , handColor : Evergreen.V93.Color.Colors
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , invited : List InviteTree
        }
