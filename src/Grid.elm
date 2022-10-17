module Grid exposing
    ( Grid(..)
    , GridChange
    , LocalGridChange
    , Vertex
    , addChange
    , allCells
    , allCellsDict
    , asciiToCellAndLocalCoord
    , cellAndLocalCoordToAscii
    , changeCount
    , empty
    , from
    , getCell
    , localChangeToChange
    , mesh
    , moveUndoPoint
    , region
    , removeUser
    )

import Ascii exposing (Ascii)
import Bounds exposing (Bounds)
import Dict exposing (Dict)
import GridCell exposing (Cell)
import Helper exposing (Coord, RawCellCoord)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Math.Vector2 exposing (Vec2)
import Pixels
import Quantity exposing (Quantity(..))
import Units exposing (CellUnit)
import User exposing (UserId)
import WebGL


type Grid
    = Grid (Dict ( Int, Int ) Cell)


empty : Grid
empty =
    Grid Dict.empty


from : Dict ( Int, Int ) Cell -> Grid
from =
    Grid


asciiToCellAndLocalCoord : Coord Units.AsciiUnit -> ( Coord Units.CellUnit, Int )
asciiToCellAndLocalCoord ( Quantity x, Quantity y ) =
    let
        offset =
            1000000
    in
    ( ( (x + (GridCell.cellSize * offset)) // GridCell.cellSize - offset |> Quantity
      , (y + (GridCell.cellSize * offset)) // GridCell.cellSize - offset |> Quantity
      )
    , modBy GridCell.cellSize x + modBy GridCell.cellSize y * GridCell.cellSize
    )


cellAndLocalCoordToAscii : ( Coord Units.CellUnit, Int ) -> Coord Units.AsciiUnit
cellAndLocalCoordToAscii ( ( Quantity x, Quantity y ), local ) =
    ( (x * GridCell.cellSize + modBy GridCell.cellSize local) |> Quantity
    , (y * GridCell.cellSize + local // GridCell.cellSize) |> Quantity
    )


type alias GridChange =
    { cellPosition : Coord Units.CellUnit, localPosition : Int, change : Ascii, userId : UserId }


type alias LocalGridChange =
    { cellPosition : Coord Units.CellUnit, localPosition : Int, change : Ascii }


localChangeToChange : UserId -> LocalGridChange -> GridChange
localChangeToChange userId change_ =
    { cellPosition = change_.cellPosition
    , localPosition = change_.localPosition
    , change = change_.change
    , userId = userId
    }


moveUndoPoint : UserId -> Dict RawCellCoord Int -> Grid -> Grid
moveUndoPoint userId undoPoint (Grid grid) =
    Dict.foldl
        (\coord moveAmount newGrid ->
            Dict.update coord (Maybe.map (GridCell.moveUndoPoint userId moveAmount)) newGrid
        )
        grid
        undoPoint
        |> Grid


changeCount : Coord Units.CellUnit -> Grid -> Int
changeCount ( Quantity x, Quantity y ) (Grid grid) =
    case Dict.get ( x, y ) grid of
        Just cell ->
            GridCell.changeCount cell

        Nothing ->
            0


addChange : GridChange -> Grid -> Grid
addChange change grid =
    let
        cell : Cell
        cell =
            getCell change.cellPosition grid
                |> Maybe.withDefault GridCell.empty
    in
    GridCell.addLine change.userId change.localPosition change.change cell
        |> (\cell_ -> setCell change.cellPosition cell_ grid)


allCells : Grid -> List ( Coord CellUnit, Cell )
allCells (Grid grid) =
    Dict.toList grid |> List.map (Tuple.mapFirst (\( x, y ) -> ( Units.cellUnit x, Units.cellUnit y )))


allCellsDict : Grid -> Dict ( Int, Int ) Cell
allCellsDict (Grid grid) =
    grid


region : Bounds CellUnit -> Grid -> Grid
region bounds (Grid grid) =
    Dict.filter (\coord _ -> Bounds.contains (Helper.fromRawCoord coord) bounds) grid |> Grid


getCell : Coord Units.CellUnit -> Grid -> Maybe Cell
getCell ( Quantity x, Quantity y ) (Grid grid) =
    Dict.get ( x, y ) grid


setCell : Coord Units.CellUnit -> Cell -> Grid -> Grid
setCell ( Quantity x, Quantity y ) value (Grid grid) =
    Dict.insert ( x, y ) value grid |> Grid


type alias Vertex =
    { position : Vec2, texturePosition : Vec2 }


mesh :
    Coord Units.CellUnit
    -> List { userId : UserId, position : Int, value : Ascii }
    -> WebGL.Mesh Vertex
mesh cellPosition asciiValues =
    let
        list : List { position : Coord Units.AsciiUnit, userId : UserId, value : Ascii }
        list =
            List.map
                (\{ userId, position, value } ->
                    { position = cellAndLocalCoordToAscii ( cellPosition, position )
                    , userId = userId
                    , value = value
                    }
                )
                asciiValues

        indices : List ( Int, Int, Int )
        indices =
            List.range 0 (List.length list - 1)
                |> List.concatMap getIndices
    in
    List.map
        (\{ position, value } ->
            let
                { topLeft, bottomRight } =
                    Ascii.texturePosition value

                ( Quantity x, Quantity y ) =
                    position

                ( w, h ) =
                    Ascii.size
            in
            List.map
                (\uv ->
                    let
                        offset =
                            Math.Vector2.vec2
                                (x * Pixels.inPixels w |> toFloat)
                                (y * Pixels.inPixels h |> toFloat)
                    in
                    { position = Math.Vector2.sub (Math.Vector2.add offset uv) topLeft
                    , texturePosition = uv
                    }
                )
                [ topLeft
                , Math.Vector2.vec2 (Math.Vector2.getX bottomRight) (Math.Vector2.getY topLeft)
                , bottomRight
                , Math.Vector2.vec2 (Math.Vector2.getX topLeft) (Math.Vector2.getY bottomRight)
                ]
        )
        list
        |> Debug.log "grid"
        |> List.concat
        |> (\vertices -> WebGL.indexedTriangles vertices indices)


getIndices : number -> List ( number, number, number )
getIndices indexOffset =
    [ ( 4 * indexOffset + 3, 4 * indexOffset + 1, 4 * indexOffset )
    , ( 4 * indexOffset + 2, 4 * indexOffset + 1, 4 * indexOffset + 3 )
    ]


removeUser : UserId -> Grid -> Grid
removeUser userId grid =
    allCellsDict grid
        |> Dict.map (\_ cell -> GridCell.removeUser userId cell)
        |> from
