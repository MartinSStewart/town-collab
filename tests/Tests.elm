module Tests exposing (..)

import Coord exposing (Coord)
import Duration
import Expect exposing (Expectation)
import Grid
import GridCell
import Quantity exposing (Quantity(..))
import Test exposing (Test, describe, test)
import Tile exposing (Direction(..), RailPath(..), Tile(..))
import Time
import Train exposing (Train)
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
                case maybeCell of
                    Just cell ->
                        GridCell.flatten cell
                            |> Expect.equal
                                [ { position = Coord.fromRawCoord ( 0, 0 )
                                  , userId = user0
                                  , value = RailHorizontal
                                  }
                                ]

                    Nothing ->
                        Expect.fail "Cell not found"
        , test "Add house overlaps neighbor" <|
            \_ ->
                let
                    maybeCell : Maybe GridCell.Cell
                    maybeCell =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( 21, 8 )
                                , change = House
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( 22, 8 )
                                , change = House
                                , userId = user0
                                }
                            |> Grid.getCell (Coord.fromRawCoord ( 1, 0 ))
                in
                case maybeCell of
                    Just cell ->
                        GridCell.flatten cell
                            |> Expect.equal
                                [ { position = Coord.fromRawCoord ( 6, 8 )
                                  , userId = user0
                                  , value = House
                                  }
                                ]

                    Nothing ->
                        Expect.fail "Cell not found"
        , test "Collision test for default collision and custom collision mask" <|
            \_ ->
                Tile.hasCollision
                    (Coord.fromRawCoord ( 0, 0 ))
                    (Tile.getData RailHorizontal)
                    (Coord.fromRawCoord ( 0, 0 ))
                    (Tile.getData RailBottomToRight)
                    |> Expect.equal False
        , test "Collision test 2 for default collision and custom collision mask" <|
            \_ ->
                Tile.hasCollision
                    (Coord.fromRawCoord ( 0, 0 ))
                    (Tile.getData RailHorizontal)
                    (Coord.fromRawCoord ( 1, 0 ))
                    (Tile.getData RailBottomToRight)
                    |> Expect.equal False
        , test "Move train" <|
            \_ ->
                let
                    grid =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( 0, 0 )
                                , change = TrainHouseLeft
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( -4, 2 )
                                , change = RailBottomToRight
                                , userId = user0
                                }
                in
                Train.moveTrain
                    Duration.second
                    grid
                    { position = Coord.fromRawCoord ( 0, 0 )
                    , path = Tile.trainHouseLeftRailPath
                    , t = 0.5
                    , speed = Quantity -3
                    }
                    |> Expect.equal
                        { position = Coord.fromRawCoord ( -4, 2 )
                        , path = RailPathBottomToRight
                        , t = 0.238732414637843
                        , speed = Quantity 3
                        }
        , test "Move train with small steps equals single large step" <|
            \_ ->
                let
                    grid =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( 0, 0 )
                                , change = TrainHouseLeft
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( -1, 2 )
                                , change = RailHorizontal
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( -2, 2 )
                                , change = RailHorizontal
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( -6, 2 )
                                , change = RailBottomToRight
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.fromRawCoord ( -6, 6 )
                                , change = RailTopToRight
                                , userId = user0
                                }

                    smallSteps : Train
                    smallSteps =
                        List.range 1 180
                            |> List.foldl
                                (\_ train -> Train.moveTrain (Duration.seconds (1 / 60)) grid train)
                                { position = Coord.fromRawCoord ( 0, 0 )
                                , path = Tile.trainHouseLeftRailPath
                                , t = 0.5
                                , speed = Quantity -5
                                }

                    largeStep : Train
                    largeStep =
                        Train.moveTrain
                            (Duration.seconds 3)
                            grid
                            { position = Coord.fromRawCoord ( 0, 0 )
                            , path = Tile.trainHouseLeftRailPath
                            , t = 0.5
                            , speed = Quantity -5
                            }
                in
                trainsApproximatelyEqual smallSteps largeStep
        ]


trainsApproximatelyEqual : Train -> Train -> Expectation
trainsApproximatelyEqual expected actual =
    if
        (expected.path == actual.path)
            && (expected.speed == actual.speed)
            && (expected.position == actual.position)
            && (abs (expected.t - actual.t) < 0.01)
    then
        Expect.pass

    else
        Expect.equal expected actual


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
