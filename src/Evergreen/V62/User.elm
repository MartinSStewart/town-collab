module Evergreen.V62.User exposing (..)

import Evergreen.V62.Color
import Evergreen.V62.Cursor
import Evergreen.V62.DisplayName


type alias FrontendUser =
    { name : Evergreen.V62.DisplayName.DisplayName
    , handColor : Evergreen.V62.Color.Colors
    , cursor : Maybe Evergreen.V62.Cursor.Cursor
    }
