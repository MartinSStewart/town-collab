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
import List.Nonempty exposing (Nonempty(..))
import Tile exposing (Tile)
import Units exposing (LocalUnit)
import User exposing (RawUserId, UserId)


type Cell
    = Cell
        { history : List { userId : UserId, position : Coord LocalUnit, value : Tile }
        , undoPoint : Dict RawUserId Int
        }


addValue : UserId -> Coord LocalUnit -> Tile -> Cell -> Cell
addValue userId position line (Cell cell) =
    let
        userUndoPoint =
            Dict.get (User.rawId userId) cell.undoPoint |> Maybe.withDefault 0
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
                |> (\list ->
                        { userId = userId, position = position, value = line } :: list
                   )
        , undoPoint =
            Dict.insert
                (User.rawId userId)
                (userUndoPoint + 1)
                cell.undoPoint
        }


removeUser : UserId -> Cell -> Cell
removeUser userId (Cell cell) =
    Cell
        { history = List.filter (.userId >> (==) userId) cell.history
        , undoPoint = Dict.remove (User.rawId userId) cell.undoPoint
        }


hasChangesBy : UserId -> Cell -> Bool
hasChangesBy userId (Cell cell) =
    Dict.member (User.rawId userId) cell.undoPoint


moveUndoPoint : UserId -> Int -> Cell -> Cell
moveUndoPoint userId moveAmount (Cell cell) =
    Cell
        { history = cell.history
        , undoPoint = Dict.update (User.rawId userId) (Maybe.map ((+) moveAmount)) cell.undoPoint
        }


changeCount : Cell -> Int
changeCount (Cell { history }) =
    List.length history


flatten : EverySet UserId -> EverySet UserId -> Cell -> List { userId : UserId, position : Coord LocalUnit, value : Tile }
flatten hiddenUsers hiddenUsersForAll (Cell cell) =
    let
        hidden =
            EverySet.union hiddenUsers hiddenUsersForAll

        cellBounds : Bounds unit
        cellBounds =
            Nonempty
                (Coord.fromRawCoord ( 0, 0 ))
                [ Coord.fromRawCoord ( Units.cellSize - 1, Units.cellSize - 1 ) ]
                |> Bounds.fromCoords
    in
    List.foldr
        (\({ userId, position, value } as item) state ->
            if EverySet.member userId hidden then
                state

            else
                case Dict.get (User.rawId userId) state.undoPoint of
                    Just stepsLeft ->
                        if stepsLeft > 0 then
                            let
                                data =
                                    Tile.getData value

                                ( width, height ) =
                                    data.size

                                ( x, y ) =
                                    Coord.toRawCoord position
                            in
                            { list =
                                (if Bounds.contains position cellBounds then
                                    [ item ]

                                 else
                                    []
                                )
                                    ++ List.filter
                                        (\item2 ->
                                            let
                                                ( x2, y2 ) =
                                                    Coord.toRawCoord item2.position

                                                ( width2, height2 ) =
                                                    (Tile.getData item2.value).size
                                            in
                                            ((x2 >= x && x2 < x + width) || (x >= x2 && x < x2 + width2))
                                                && ((y2 >= y && y2 < y + height) || (y >= y2 && y < y2 + height2))
                                                |> not
                                        )
                                        state.list
                            , undoPoint = Dict.insert (User.rawId userId) (stepsLeft - 1) state.undoPoint
                            }

                        else
                            state

                    Nothing ->
                        state
        )
        { list = [], undoPoint = cell.undoPoint }
        cell.history
        |> .list


empty : Cell
empty =
    Cell { history = [], undoPoint = Dict.empty }
