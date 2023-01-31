module Evergreen.V52.User exposing (..)

import Evergreen.V52.Color
import Evergreen.V52.DisplayName


type alias FrontendUser =
    { name : Evergreen.V52.DisplayName.DisplayName
    , handColor : Evergreen.V52.Color.Colors
    }
