module Evergreen.V100.User exposing (..)

import Evergreen.V100.Color
import Evergreen.V100.DisplayName
import Evergreen.V100.Id


type alias FrontendUser =
    { name : Evergreen.V100.DisplayName.DisplayName
    , handColor : Evergreen.V100.Color.Colors
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , invited : List InviteTree
        }
