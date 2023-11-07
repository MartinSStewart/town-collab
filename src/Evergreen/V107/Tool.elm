module Evergreen.V107.Tool exposing (..)

import Effect.WebGL
import Evergreen.V107.Coord
import Evergreen.V107.Sprite
import Evergreen.V107.Tile
import Evergreen.V107.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V107.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V107.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V107.Units.WorldUnit
            }
        )
    | ReportTool
