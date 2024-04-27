module Evergreen.V126.Tool exposing (..)

import Effect.WebGL
import Evergreen.V126.Coord
import Evergreen.V126.Sprite
import Evergreen.V126.Tile
import Evergreen.V126.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V126.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V126.Units.WorldUnit
            }
        )
    | ReportTool
