module User exposing (FrontendUser)

import Color exposing (Colors)
import DisplayName exposing (DisplayName)


type alias FrontendUser =
    { name : DisplayName
    , handColor : Colors
    }
