module Units exposing
    ( CellLocalUnit
    , CellUnit
    , TileLocalUnit
    , WorldUnit
    , cellSize
    , cellToTile
    , cellUnit
    , localUnit
    , pixelToWorldPixel
    , screenFrame
    , tileSize
    , tileUnit
    )

import Coord exposing (Coord)
import Frame2d exposing (Frame2d)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Vector2d exposing (Vector2d)


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


pixelToWorldPixel : Float -> Vector2d Pixels Pixels -> Coord WorldUnit
pixelToWorldPixel devicePixelRatio v =
    let
        ( Quantity w, Quantity h ) =
            tileSize

        { x, y } =
            Vector2d.unwrap v
    in
    ( x * devicePixelRatio / w |> round |> tileUnit, y * devicePixelRatio / h |> round |> tileUnit )


tileSize : ( Quantity number Pixels, Quantity number Pixels )
tileSize =
    ( Pixels.pixels 18, Pixels.pixels 18 )


screenFrame : Point2d WorldUnit WorldUnit -> Frame2d WorldUnit WorldUnit { defines : Pixels }
screenFrame viewPoint =
    Frame2d.atPoint viewPoint
