module Evergreen.V84.User exposing (..)

import Evergreen.V84.Color
import Evergreen.V84.Cursor
import Evergreen.V84.DisplayName
import Evergreen.V84.Id


type alias FrontendUser =
    { name : Evergreen.V84.DisplayName.DisplayName
    , handColor : Evergreen.V84.Color.Colors
    , cursor : Maybe Evergreen.V84.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , invited : List InviteTree
        }
