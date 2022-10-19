module Evergreen.V1.GridCell exposing (..)

import Dict
import Evergreen.V1.Ascii
import Evergreen.V1.Coord
import Evergreen.V1.Units
import Evergreen.V1.User


type Cell
    = Cell
        { history :
            List
                { userId : Evergreen.V1.User.UserId
                , position : Evergreen.V1.Coord.Coord Evergreen.V1.Units.LocalUnit
                , value : Evergreen.V1.Ascii.Ascii
                }
        , undoPoint : Dict.Dict Evergreen.V1.User.RawUserId Int
        }
