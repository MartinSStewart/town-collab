module Evergreen.V54.User exposing (..)

import Evergreen.V54.Color
import Evergreen.V54.DisplayName


type alias FrontendUser =
    { name : Evergreen.V54.DisplayName.DisplayName
    , handColor : Evergreen.V54.Color.Colors
    }
