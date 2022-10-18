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

import Ascii exposing (Ascii)
import Dict exposing (Dict)
import EverySet exposing (EverySet)
import Helper exposing (Coord)
import Units exposing (LocalUnit)
import User exposing (RawUserId, UserId)


type Cell
    = Cell
        { history : List { userId : UserId, position : Coord LocalUnit, value : Ascii }
        , undoPoint : Dict RawUserId Int
        }


addValue : UserId -> Coord LocalUnit -> Ascii -> Cell -> Cell
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
                |> (::) { userId = userId, position = position, value = line }
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


flatten : EverySet UserId -> EverySet UserId -> Cell -> List { userId : UserId, position : Coord LocalUnit, value : Ascii }
flatten hiddenUsers hiddenUsersForAll (Cell cell) =
    let
        hidden =
            EverySet.union hiddenUsers hiddenUsersForAll
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
                                    Ascii.getData value

                                ( width, height ) =
                                    data.size

                                ( x, y ) =
                                    Helper.toRawCoord position
                            in
                            { list =
                                item
                                    :: List.filter
                                        (\item2 ->
                                            let
                                                ( x2, y2 ) =
                                                    Helper.toRawCoord item2.position

                                                ( width2, height2 ) =
                                                    (Ascii.getData item2.value).size
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
