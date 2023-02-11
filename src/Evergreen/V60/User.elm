module Evergreen.V60.User exposing (..)

import Evergreen.V60.Color
import Evergreen.V60.Cursor
import Evergreen.V60.DisplayName


type alias FrontendUser =
    { name : Evergreen.V60.DisplayName.DisplayName
    , handColor : Evergreen.V60.Color.Colors
    , cursor : Maybe Evergreen.V60.Cursor.Cursor
    }
