module Evergreen.V95.Tool exposing (..)

import Effect.WebGL
import Evergreen.V95.Coord
import Evergreen.V95.Sprite
import Evergreen.V95.Tile
import Evergreen.V95.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V95.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V95.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V95.Units.WorldUnit
            }
        )
    | ReportTool
