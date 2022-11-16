module GridCell exposing
    ( Cell(..)
    , addValue
    , changeCount
    , empty
    , flatten
    , hasChangesBy
    , moveUndoPoint
    , removeUser
    )

import Bounds exposing (Bounds)
import Coord exposing (Coord)
import Dict exposing (Dict)
import EverySet exposing (EverySet)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import Tile exposing (Tile(..))
import Units exposing (CellLocalUnit)


type Cell
    = Cell
        { history : List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
        , undoPoint : Dict Int Int
        , cache : List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
        }


addValue : Id UserId -> Coord CellLocalUnit -> Tile -> Cell -> Cell
addValue userId position line (Cell cell) =
    let
        userUndoPoint =
            Dict.get (Id.toInt userId) cell.undoPoint |> Maybe.withDefault 0

        value =
            { userId = userId, position = position, value = line }
    in
    Cell
        { history =
            List.foldr
                (\change ( newHistory, counter ) ->
                    if change.userId == userId then
                        if counter > 0 then
                            ( change :: newHistory, counter - 1 )

                        else
                            ( newHistory, counter )

                    else
                        ( change :: newHistory, counter )
                )
                ( [], userUndoPoint )
                cell.history
                |> Tuple.first
                |> (\list -> value :: list)
        , undoPoint =
            Dict.insert
                (Id.toInt userId)
                (userUndoPoint + 1)
                cell.undoPoint
        , cache = stepCacheHelper value cell.cache
        }


cellBounds : Bounds unit
cellBounds =
    Nonempty
        (Coord.tuple ( 0, 0 ))
        [ Coord.tuple ( Units.cellSize - 1, Units.cellSize - 1 ) ]
        |> Bounds.fromCoords


updateCache : Cell -> Cell
updateCache (Cell cell) =
    { history = cell.history
    , undoPoint = cell.undoPoint
    , cache = List.foldr stepCache { list = [], undoPoint = cell.undoPoint } cell.history |> .list
    }
        |> Cell


stepCache ({ userId, position, value } as item) state =
    case Dict.get (Id.toInt userId) state.undoPoint of
        Just stepsLeft ->
            if stepsLeft > 0 then
                { list = stepCacheHelper item state.list
                , undoPoint = Dict.insert (Id.toInt userId) (stepsLeft - 1) state.undoPoint
                }

            else
                state

        Nothing ->
            state


stepCacheHelper :
    { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
stepCacheHelper ({ userId, position, value } as item) cache =
    let
        data =
            Tile.getData value
    in
    (if Bounds.contains position cellBounds && value /= EmptyTile then
        [ item ]

     else
        []
    )
        ++ List.filter
            (\item2 ->
                Tile.hasCollision position data item2.position (Tile.getData item2.value)
                    |> not
            )
            cache


removeUser : Id UserId -> Cell -> Cell
removeUser userId (Cell cell) =
    Cell
        { history = List.filter (.userId >> (==) userId) cell.history
        , undoPoint = Dict.remove (Id.toInt userId) cell.undoPoint
        , cache = cell.cache
        }
        |> updateCache


hasChangesBy : Id UserId -> Cell -> Bool
hasChangesBy userId (Cell cell) =
    Dict.member (Id.toInt userId) cell.undoPoint


moveUndoPoint : Id UserId -> Int -> Cell -> Cell
moveUndoPoint userId moveAmount (Cell cell) =
    Cell
        { history = cell.history
        , undoPoint = Dict.update (Id.toInt userId) (Maybe.map ((+) moveAmount)) cell.undoPoint
        , cache = cell.cache
        }
        |> updateCache


changeCount : Cell -> Int
changeCount (Cell { history }) =
    List.length history


flatten : Cell -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
flatten (Cell cell) =
    cell.cache


empty : Cell
empty =
    Cell { history = [], undoPoint = Dict.empty, cache = [] }
