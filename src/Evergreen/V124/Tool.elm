module Evergreen.V124.Tool exposing (..)

import Effect.WebGL
import Evergreen.V124.Coord
import Evergreen.V124.Sprite
import Evergreen.V124.Tile
import Evergreen.V124.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V124.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V124.Units.WorldUnit
            }
        )
    | ReportTool
