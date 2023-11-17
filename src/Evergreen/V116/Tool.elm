module Evergreen.V116.Tool exposing (..)

import Effect.WebGL
import Evergreen.V116.Coord
import Evergreen.V116.Sprite
import Evergreen.V116.Tile
import Evergreen.V116.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V116.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V116.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V116.Units.WorldUnit
            }
        )
    | ReportTool
