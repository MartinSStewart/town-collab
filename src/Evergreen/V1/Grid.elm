module Evergreen.V1.Grid exposing (..)

import Dict
import Evergreen.V1.Ascii
import Evergreen.V1.Coord
import Evergreen.V1.GridCell
import Evergreen.V1.Units
import Evergreen.V1.User
import Math.Vector2


type alias LocalGridChange =
    { position : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
    , change : Evergreen.V1.Ascii.Ascii
    }


type alias GridChange =
    { position : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
    , change : Evergreen.V1.Ascii.Ascii
    , userId : Evergreen.V1.User.UserId
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V1.GridCell.Cell)


type alias Vertex =
    { position : Math.Vector2.Vec2
    , texturePosition : Math.Vector2.Vec2
    }
