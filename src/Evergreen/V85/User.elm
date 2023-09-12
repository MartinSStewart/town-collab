module Evergreen.V85.User exposing (..)

import Evergreen.V85.Color
import Evergreen.V85.Cursor
import Evergreen.V85.DisplayName
import Evergreen.V85.Id


type alias FrontendUser =
    { name : Evergreen.V85.DisplayName.DisplayName
    , handColor : Evergreen.V85.Color.Colors
    , cursor : Maybe Evergreen.V85.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , invited : List InviteTree
        }
