module Evergreen.V59.User exposing (..)

import Evergreen.V59.Color
import Evergreen.V59.Cursor
import Evergreen.V59.DisplayName


type alias FrontendUser =
    { name : Evergreen.V59.DisplayName.DisplayName
    , handColor : Evergreen.V59.Color.Colors
    , cursor : Maybe Evergreen.V59.Cursor.Cursor
    }
