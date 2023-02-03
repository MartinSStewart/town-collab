module Evergreen.V47.User exposing (..)

import Evergreen.V47.Color
import Evergreen.V47.DisplayName


type alias FrontendUser =
    { name : Evergreen.V47.DisplayName.DisplayName
    , handColor : Evergreen.V47.Color.Colors
    }
