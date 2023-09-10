module Tool exposing (Tool(..), toCursor)

import Coord exposing (Coord)
import Cursor exposing (CursorSprite(..))
import Effect.WebGL as WebGL
import Quantity exposing (Quantity)
import Shaders exposing (Vertex)
import Tile exposing (TileGroup(..))
import Units exposing (WorldUnit)


type Tool
    = HandTool
    | TilePlacerTool { tileGroup : TileGroup, index : Int, mesh : WebGL.Mesh Vertex }
    | TilePickerTool
    | TextTool (Maybe { cursorPosition : Coord WorldUnit, startColumn : Quantity Int WorldUnit })
    | ReportTool


toCursor : Tool -> Cursor.OtherUsersTool
toCursor tool =
    case tool of
        HandTool ->
            Cursor.HandTool

        TilePlacerTool { tileGroup } ->
            if tileGroup == EmptyTileGroup then
                Cursor.EraserTool

            else
                Cursor.TilePlacerTool

        TilePickerTool ->
            Cursor.TilePickerTool

        TextTool (Just textTool) ->
            Cursor.TextTool (Just { cursorPosition = textTool.cursorPosition })

        TextTool Nothing ->
            Cursor.TextTool Nothing

        ReportTool ->
            Cursor.ReportTool
