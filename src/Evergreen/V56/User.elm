module Evergreen.V56.User exposing (..)

import Evergreen.V56.Color
import Evergreen.V56.DisplayName


type alias FrontendUser =
    { name : Evergreen.V56.DisplayName.DisplayName
    , handColor : Evergreen.V56.Color.Colors
    }
