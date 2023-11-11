module Evergreen.V110.Tool exposing (..)

import Effect.WebGL
import Evergreen.V110.Coord
import Evergreen.V110.Sprite
import Evergreen.V110.Tile
import Evergreen.V110.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V110.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V110.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V110.Units.WorldUnit
            }
        )
    | ReportTool
