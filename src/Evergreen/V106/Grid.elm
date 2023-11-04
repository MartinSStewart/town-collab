module Evergreen.V106.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V106.Color
import Evergreen.V106.Coord
import Evergreen.V106.GridCell
import Evergreen.V106.Id
import Evergreen.V106.Tile
import Evergreen.V106.Units


type alias LocalGridChange =
    { position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , change : Evergreen.V106.Tile.Tile
    , colors : Evergreen.V106.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , change : Evergreen.V106.Tile.Tile
    , userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
    , colors : Evergreen.V106.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V106.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V106.GridCell.CellData)
