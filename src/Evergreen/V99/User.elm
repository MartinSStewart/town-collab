module Evergreen.V99.User exposing (..)

import Evergreen.V99.Color
import Evergreen.V99.DisplayName
import Evergreen.V99.Id


type alias FrontendUser =
    { name : Evergreen.V99.DisplayName.DisplayName
    , handColor : Evergreen.V99.Color.Colors
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , invited : List InviteTree
        }
