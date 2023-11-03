module Evergreen.V100.Tool exposing (..)

import Effect.WebGL
import Evergreen.V100.Coord
import Evergreen.V100.Sprite
import Evergreen.V100.Tile
import Evergreen.V100.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V100.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V100.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V100.Units.WorldUnit
            }
        )
    | ReportTool
