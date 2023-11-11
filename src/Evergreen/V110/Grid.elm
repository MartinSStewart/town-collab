module Evergreen.V110.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V110.Color
import Evergreen.V110.Coord
import Evergreen.V110.GridCell
import Evergreen.V110.Id
import Evergreen.V110.Tile
import Evergreen.V110.Units


type alias LocalGridChange =
    { position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
    , change : Evergreen.V110.Tile.Tile
    , colors : Evergreen.V110.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
    , change : Evergreen.V110.Tile.Tile
    , userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , colors : Evergreen.V110.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V110.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V110.GridCell.CellData)
