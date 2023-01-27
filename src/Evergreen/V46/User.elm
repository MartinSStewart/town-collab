module Evergreen.V46.User exposing (..)

import Evergreen.V46.Color
import Evergreen.V46.DisplayName


type alias FrontendUser =
    { name : Evergreen.V46.DisplayName.DisplayName
    , handColor : Evergreen.V46.Color.Colors
    }
