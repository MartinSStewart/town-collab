module Evergreen.V76.User exposing (..)

import Evergreen.V76.Color
import Evergreen.V76.Cursor
import Evergreen.V76.DisplayName
import Evergreen.V76.Id


type alias FrontendUser =
    { name : Evergreen.V76.DisplayName.DisplayName
    , handColor : Evergreen.V76.Color.Colors
    , cursor : Maybe Evergreen.V76.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , invited : List InviteTree
        }
