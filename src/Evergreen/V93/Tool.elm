module Evergreen.V93.Tool exposing (..)

import Effect.WebGL
import Evergreen.V93.Coord
import Evergreen.V93.Sprite
import Evergreen.V93.Tile
import Evergreen.V93.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V93.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V93.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V93.Units.WorldUnit
            }
        )
    | ReportTool
