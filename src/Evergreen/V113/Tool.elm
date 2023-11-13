module Evergreen.V113.Tool exposing (..)

import Effect.WebGL
import Evergreen.V113.Coord
import Evergreen.V113.Sprite
import Evergreen.V113.Tile
import Evergreen.V113.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V113.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V113.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V113.Units.WorldUnit
            }
        )
    | ReportTool
