module Evergreen.V107.User exposing (..)

import Evergreen.V107.Color
import Evergreen.V107.DisplayName
import Evergreen.V107.Id


type alias FrontendUser =
    { name : Evergreen.V107.DisplayName.DisplayName
    , handColor : Evergreen.V107.Color.Colors
    , isBot : Bool
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , invited : List InviteTree
        }
