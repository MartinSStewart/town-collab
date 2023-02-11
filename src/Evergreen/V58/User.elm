module Evergreen.V58.User exposing (..)

import Evergreen.V58.Color
import Evergreen.V58.Cursor
import Evergreen.V58.DisplayName


type alias FrontendUser =
    { name : Evergreen.V58.DisplayName.DisplayName
    , handColor : Evergreen.V58.Color.Colors
    , cursor : Maybe Evergreen.V58.Cursor.Cursor
    }
