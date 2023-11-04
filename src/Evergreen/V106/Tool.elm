module Evergreen.V106.Tool exposing (..)

import Effect.WebGL
import Evergreen.V106.Coord
import Evergreen.V106.Sprite
import Evergreen.V106.Tile
import Evergreen.V106.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V106.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V106.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V106.Units.WorldUnit
            }
        )
    | ReportTool
