module Evergreen.V99.Tool exposing (..)

import Effect.WebGL
import Evergreen.V99.Coord
import Evergreen.V99.Sprite
import Evergreen.V99.Tile
import Evergreen.V99.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V99.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V99.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V99.Units.WorldUnit
            }
        )
    | ReportTool
