module Evergreen.V57.User exposing (..)

import Evergreen.V57.Color
import Evergreen.V57.Cursor
import Evergreen.V57.DisplayName


type alias FrontendUser =
    { name : Evergreen.V57.DisplayName.DisplayName
    , handColor : Evergreen.V57.Color.Colors
    , cursor : Maybe Evergreen.V57.Cursor.Cursor
    }
