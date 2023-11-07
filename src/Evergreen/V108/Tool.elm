module Evergreen.V108.Tool exposing (..)

import Effect.WebGL
import Evergreen.V108.Coord
import Evergreen.V108.Sprite
import Evergreen.V108.Tile
import Evergreen.V108.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V108.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V108.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V108.Units.WorldUnit
            }
        )
    | ReportTool
