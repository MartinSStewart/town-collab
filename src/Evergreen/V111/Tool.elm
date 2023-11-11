module Evergreen.V111.Tool exposing (..)

import Effect.WebGL
import Evergreen.V111.Coord
import Evergreen.V111.Sprite
import Evergreen.V111.Tile
import Evergreen.V111.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V111.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V111.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V111.Units.WorldUnit
            }
        )
    | ReportTool
