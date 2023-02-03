module Evergreen.V49.User exposing (..)

import Evergreen.V49.Color
import Evergreen.V49.DisplayName


type alias FrontendUser =
    { name : Evergreen.V49.DisplayName.DisplayName
    , handColor : Evergreen.V49.Color.Colors
    }
