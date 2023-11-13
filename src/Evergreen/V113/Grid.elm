module Evergreen.V113.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.GridCell
import Evergreen.V113.Id
import Evergreen.V113.Tile
import Evergreen.V113.Units


type alias LocalGridChange =
    { position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , change : Evergreen.V113.Tile.Tile
    , colors : Evergreen.V113.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , change : Evergreen.V113.Tile.Tile
    , userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , colors : Evergreen.V113.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V113.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V113.GridCell.CellData)
