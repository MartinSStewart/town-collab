module Evergreen.V123.Tool exposing (..)

import Effect.WebGL
import Evergreen.V123.Coord
import Evergreen.V123.Sprite
import Evergreen.V123.Tile
import Evergreen.V123.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V123.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V123.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V123.Units.WorldUnit
            }
        )
    | ReportTool
