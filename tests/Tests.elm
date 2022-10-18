module Tests exposing (..)

import Ascii exposing (Ascii(..))
import Coord exposing (Coord)
import EverySet as Set
import Expect
import Grid
import GridCell
import Test exposing (Test, describe, test)
import Time
import UrlHelper exposing (ConfirmEmailKey(..), UnsubscribeEmailKey(..))
import User


user0 =
    User.userId 0



--a =
--    Grid
--        (Dict.fromList
--            [ ( ( -1, -1 )
--              , Cell
--                    { history = [], undoPoint = Dict.fromList [ ( 0, 1 ) ] }
--              )
--            , ( ( -1, 0 ), Cell { history = [], undoPoint = Dict.fromList [ ( 0, 1 ) ] } )
--            , ( ( 0, -1 ), Cell { history = [], undoPoint = Dict.fromList [ ( 0, 1 ) ] } )
--            , ( ( 0, 0 )
--              , Cell
--                    { history =
--                        [ { position = ( Quantity 0, Quantity 0 )
--                          , userId = UserId 0
--                          , value = RailHorizontal
--                          }
--                        ]
--                    , undoPoint = Dict.fromList [ ( 0, 1 ) ]
--                    }
--              )
--            ]
--        )


tests : Test
tests =
    describe "Tests"
        [ test "Add rail" <|
            \_ ->
                let
                    maybeCell : Maybe GridCell.Cell
                    maybeCell =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( 0, 0 )
                                , change = RailHorizontal
                                , userId = user0
                                }
                            |> Debug.log "a"
                            |> Grid.getCell (Coord.fromRawCoord ( 0, 0 ))
                in
                Expect.fail "Cell not found"

        --case maybeCell of
        --    Just cell ->
        --        GridCell.flatten Set.empty Set.empty cell
        --            |> Expect.equal
        --                [ { position = Coord.fromRawCoord ( 0, 0 )
        --                  , userId = user0
        --                  , value = RailHorizontal
        --                  }
        --                ]
        --
        --    Nothing ->
        --        Expect.fail "Cell not found"
        --, test "Add house overlaps neighbor" <|
        --    \_ ->
        --        let
        --            maybeCell : Maybe GridCell.Cell
        --            maybeCell =
        --                Grid.empty
        --                    |> Grid.addChange
        --                        { position = Coord.fromRawCoord ( 0, 0 )
        --                        , change = RailHorizontal
        --                        , userId = user0
        --                        }
        --                    |> Grid.getCell (Coord.fromRawCoord ( 0, 0 ))
        --        in
        --        case maybeCell of
        --            Just cell ->
        --                GridCell.flatten Set.empty Set.empty cell
        --                    |> Expect.equal
        --                        [ { position = Coord.fromRawCoord ( 0, 0 )
        --                          , userId = user0
        --                          , value = RailHorizontal
        --                          }
        --                        ]
        --
        --            Nothing ->
        --                Expect.fail "Cell not found"
        ]


unsubscribeKey =
    UnsubscribeEmailKey "dbfcfd0d87220f629339bd3adcf452d083fde3246625fb3a93e314f833e20d37"


time seconds =
    Time.millisToPosix ((seconds * 1000) + 10000000)



--
--checkGridValue : ( Coord CellUnit, Coord LocalUnit ) -> Maybe Ascii -> LocalModel.LocalModel a LocalGrid.LocalGrid -> TestResult
--checkGridValue ( cellPosition, localPosition ) value =
--    LocalGrid.localModel
--        >> .grid
--        >> Grid.getCell cellPosition
--        >> Maybe.andThen
--            (GridCell.flatten EverySet.empty EverySet.empty
--                >> List.find (.position >> (==) localPosition)
--                >> Maybe.map .value
--            )
--        >> (\ascii ->
--                if ascii == value then
--                    Passed
--
--                else
--                    failed
--                        ("Wrong value found in grid "
--                            ++ Debug.toString ascii
--                            ++ " at cell position "
--                            ++ Debug.toString cellPosition
--                            ++ " and local position "
--                            ++ Debug.toString localPosition
--                        )
--           )
