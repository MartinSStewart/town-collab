module Evergreen.V108.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V108.Color
import Evergreen.V108.Coord
import Evergreen.V108.GridCell
import Evergreen.V108.Id
import Evergreen.V108.Tile
import Evergreen.V108.Units


type alias LocalGridChange =
    { position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , change : Evergreen.V108.Tile.Tile
    , colors : Evergreen.V108.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , change : Evergreen.V108.Tile.Tile
    , userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , colors : Evergreen.V108.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V108.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V108.GridCell.CellData)
