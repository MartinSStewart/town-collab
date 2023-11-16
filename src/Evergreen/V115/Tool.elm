module Evergreen.V115.Tool exposing (..)

import Effect.WebGL
import Evergreen.V115.Coord
import Evergreen.V115.Sprite
import Evergreen.V115.Tile
import Evergreen.V115.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V115.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V115.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V115.Units.WorldUnit
            }
        )
    | ReportTool
