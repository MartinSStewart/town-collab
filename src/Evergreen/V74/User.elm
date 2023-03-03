module Evergreen.V74.User exposing (..)

import Evergreen.V74.Color
import Evergreen.V74.Cursor
import Evergreen.V74.DisplayName
import Evergreen.V74.Id


type alias FrontendUser =
    { name : Evergreen.V74.DisplayName.DisplayName
    , handColor : Evergreen.V74.Color.Colors
    , cursor : Maybe Evergreen.V74.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , invited : List InviteTree
        }
