module Units exposing
    ( CellLocalUnit
    , CellUnit
    , MailPixelUnit
    , TileLocalUnit
    , WorldUnit
    , cellSize
    , cellToTile
    , cellUnit
    , localUnit
    , screenFrame
    , tileSize
    , tileUnit
    )

import Coord exposing (Coord)
import Frame2d exposing (Frame2d)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)


type WorldUnit
    = WorldUnit Never


type CellUnit
    = CellUnit Never


type CellLocalUnit
    = LocalUnit Never


type TileLocalUnit
    = TileLocalUnit Never


type MailPixelUnit
    = MailUnit Never


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
    Coord.multiplyTuple ( cellSize, cellSize ) coord |> Coord.toTuple |> Coord.fromTuple


tileSize : number
tileSize =
    18


screenFrame : Point2d WorldUnit WorldUnit -> Frame2d WorldUnit WorldUnit { defines : Pixels }
screenFrame viewPoint =
    Frame2d.atPoint viewPoint
