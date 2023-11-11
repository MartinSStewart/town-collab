module Evergreen.V111.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.GridCell
import Evergreen.V111.Id
import Evergreen.V111.Tile
import Evergreen.V111.Units


type alias LocalGridChange =
    { position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , change : Evergreen.V111.Tile.Tile
    , colors : Evergreen.V111.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , change : Evergreen.V111.Tile.Tile
    , userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , colors : Evergreen.V111.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V111.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V111.GridCell.CellData)
