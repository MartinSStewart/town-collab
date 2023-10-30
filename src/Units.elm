module Units exposing
    ( CellLocalUnit(..)
    , CellUnit(..)
    , MailPixelUnit(..)
    , TerrainUnit(..)
    , TileLocalUnit(..)
    , WorldUnit(..)
    , cellSize
    , cellToTile
    , cellUnit
    , localUnit
    , pixelToTile
    , pixelToTilePoint
    , screenFrame
    , tileHeight
    , tileSize
    , tileToPixel
    , tileUnit
    , tileWidth
    )

import Coord exposing (Coord)
import Frame2d exposing (Frame2d)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))


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


type TerrainUnit
    = TerrainUnit Never


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
    Coord.multiplyTuple ( cellSize, cellSize ) coord |> Coord.toTuple |> Coord.tuple


tileToPixel : Coord WorldUnit -> Coord Pixels
tileToPixel coord =
    Coord.multiply tileSize coord |> Coord.toTuple |> Coord.tuple


pixelToTile : Coord Pixels -> Coord WorldUnit
pixelToTile coord =
    coord |> Coord.divide tileSize |> Coord.toTuple |> Coord.tuple


pixelToTilePoint : Coord Pixels -> Point2d WorldUnit WorldUnit
pixelToTilePoint ( Quantity x, Quantity y ) =
    Point2d.unsafe
        { x = toFloat x / toFloat (Coord.xRaw tileSize)
        , y = toFloat y / toFloat (Coord.yRaw tileSize)
        }


tileSize : Coord unit
tileSize =
    Coord.xy 20 18


tileWidth : Int
tileWidth =
    Coord.xRaw tileSize


tileHeight : Int
tileHeight =
    Coord.yRaw tileSize


screenFrame : Point2d WorldUnit WorldUnit -> Frame2d WorldUnit WorldUnit { defines : Pixels }
screenFrame viewPoint =
    Frame2d.atPoint viewPoint
