module User exposing (FrontendUser)

import Color exposing (Colors)
import Cursor exposing (Cursor)
import DisplayName exposing (DisplayName)


type alias FrontendUser =
    { name : DisplayName
    , handColor : Colors
    , cursor : Maybe Cursor
    }
