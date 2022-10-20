module Units exposing
    ( CellUnit
    , LocalUnit
    , ScreenCoordinate
    , TileUnit
    , WorldCoordinate
    , WorldPixel
    , cellSize
    , cellToTile
    , cellUnit
    , inWorldUnits
    , localUnit
    , pixelToWorldPixel
    , screenFrame
    , tileToWorld
    , tileUnit
    , worldToTile
    , worldUnit
    )

import Coord exposing (Coord)
import Frame2d exposing (Frame2d)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity, Rate)
import Tile
import Vector2d exposing (Vector2d)


type WorldPixel
    = WorldPixel Never


type TileUnit
    = TileUnit Never


type CellUnit
    = CellUnit Never


type LocalUnit
    = LocalUnit Never


tileUnit : number -> Quantity number TileUnit
tileUnit =
    Quantity.Quantity


worldUnit : number -> Quantity number WorldPixel
worldUnit =
    Quantity.Quantity


inWorldUnits : Quantity Int WorldPixel -> Int
inWorldUnits (Quantity.Quantity value) =
    value


cellUnit : number -> Quantity number CellUnit
cellUnit =
    Quantity.Quantity


localUnit : number -> Quantity number LocalUnit
localUnit =
    Quantity.Quantity


tileToWorld : Coord TileUnit -> Coord WorldPixel
tileToWorld ( Quantity.Quantity x, Quantity.Quantity y ) =
    let
        ( w, h ) =
            Tile.size
    in
    ( Quantity.Quantity (Pixels.inPixels w * x), Quantity.Quantity (Pixels.inPixels h * y) )


worldToTile : Point2d WorldPixel WorldCoordinate -> Coord TileUnit
worldToTile point =
    let
        ( w, h ) =
            Tile.size

        { x, y } =
            Point2d.unwrap point
    in
    ( Quantity.Quantity (x / Pixels.inPixels w |> floor), Quantity.Quantity (y / Pixels.inPixels h |> floor) )


cellSize : Int
cellSize =
    16


cellToTile : Coord CellUnit -> Coord TileUnit
cellToTile coord =
    Coord.multiplyTuple ( cellSize, cellSize ) coord |> Coord.toRawCoord |> Coord.fromRawCoord


pixelToWorldPixel : Float -> Vector2d Pixels ScreenCoordinate -> Coord WorldPixel
pixelToWorldPixel devicePixelRatio v =
    let
        { x, y } =
            Vector2d.unwrap v
    in
    ( x * devicePixelRatio |> round |> worldUnit, y * devicePixelRatio |> round |> worldUnit )


screenFrame : Point2d WorldPixel WorldCoordinate -> Frame2d WorldPixel WorldCoordinate { defines : ScreenCoordinate }
screenFrame viewPoint =
    Frame2d.atPoint viewPoint


type ScreenCoordinate
    = ScreenCoordinate Never


type WorldCoordinate
    = WorldCoordinate Never
