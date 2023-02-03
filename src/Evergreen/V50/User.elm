module Evergreen.V50.User exposing (..)

import Evergreen.V50.Color
import Evergreen.V50.DisplayName


type alias FrontendUser =
    { name : Evergreen.V50.DisplayName.DisplayName
    , handColor : Evergreen.V50.Color.Colors
    }
