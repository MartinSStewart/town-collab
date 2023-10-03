module Evergreen.V91.User exposing (..)

import Evergreen.V91.Color
import Evergreen.V91.Cursor
import Evergreen.V91.DisplayName
import Evergreen.V91.Id


type alias FrontendUser =
    { name : Evergreen.V91.DisplayName.DisplayName
    , handColor : Evergreen.V91.Color.Colors
    , cursor : Maybe Evergreen.V91.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , invited : List InviteTree
        }
