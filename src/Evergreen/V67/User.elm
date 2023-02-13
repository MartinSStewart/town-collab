module Evergreen.V67.User exposing (..)

import Evergreen.V67.Color
import Evergreen.V67.Cursor
import Evergreen.V67.DisplayName
import Evergreen.V67.Id


type alias FrontendUser =
    { name : Evergreen.V67.DisplayName.DisplayName
    , handColor : Evergreen.V67.Color.Colors
    , cursor : Maybe Evergreen.V67.Cursor.Cursor
    }


type InviteTree
    = InviteTree
        { userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        , invited : List InviteTree
        }
