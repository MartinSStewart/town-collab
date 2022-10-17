module GridCell exposing
    ( Cell(..)
    , addLine
    , cellSize
    , changeCount
    , empty
    , flatten
    , hasChangesBy
    , moveUndoPoint
    , removeUser
    )

import Array exposing (Array)
import Ascii exposing (Ascii)
import Dict exposing (Dict)
import EverySet exposing (EverySet)
import List.Nonempty exposing (Nonempty)
import User exposing (RawUserId, UserId)


type Cell
    = Cell
        { history : List { userId : UserId, position : Int, value : Ascii }
        , undoPoint : Dict RawUserId Int
        }


addLine : UserId -> Int -> Ascii -> Cell -> Cell
addLine userId position line (Cell cell) =
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


flatten : EverySet UserId -> EverySet UserId -> Cell -> List { userId : UserId, position : Int, value : Ascii }
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
                                    localCoordToAscii position
                            in
                            { list =
                                item
                                    :: List.filter
                                        (\item2 ->
                                            let
                                                ( x2, y2 ) =
                                                    localCoordToAscii item2.position

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


asciiToLocalCoord : ( Int, Int ) -> Int
asciiToLocalCoord ( x, y ) =
    x + y * cellSize


localCoordToAscii : Int -> ( Int, Int )
localCoordToAscii position =
    ( modBy cellSize position, position // cellSize )


cellSize : Int
cellSize =
    16


empty : Cell
empty =
    Cell { history = [], undoPoint = Dict.empty }
