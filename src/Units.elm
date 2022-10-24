module Units exposing
    ( CellLocalUnit
    , CellUnit
    , ScreenCoordinate
    , TileLocalUnit
    , WorldCoordinate
    , WorldPixel
    , WorldUnit
    , cellSize
    , cellToTile
    , cellUnit
    , inWorldUnits
    , localUnit
    , pixelToWorldPixel
    , screenFrame
    , tileUnit
    , worldUnit
    )

import Coord exposing (Coord)
import Frame2d exposing (Frame2d)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Vector2d exposing (Vector2d)


type WorldPixel
    = WorldPixel Never


type WorldUnit
    = WorldUnit Never


type CellUnit
    = CellUnit Never


type CellLocalUnit
    = LocalUnit Never


type TileLocalUnit
    = TileLocalUnit Never


tileUnit : number -> Quantity number WorldUnit
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


localUnit : number -> Quantity number CellLocalUnit
localUnit =
    Quantity.Quantity


cellSize : number
cellSize =
    16


cellToTile : Coord CellUnit -> Coord WorldUnit
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
