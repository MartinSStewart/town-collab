module Evergreen.V48.User exposing (..)

import Evergreen.V48.Color
import Evergreen.V48.DisplayName


type alias FrontendUser =
    { name : Evergreen.V48.DisplayName.DisplayName
    , handColor : Evergreen.V48.Color.Colors
    }
