module Tests exposing (..)

import AssocList
import Coord exposing (Coord)
import Duration
import Expect exposing (Expectation)
import Grid exposing (Grid)
import GridCell
import Id
import Quantity exposing (Quantity(..))
import Test exposing (Test, describe, test)
import Tile exposing (Direction(..), RailPath(..), Tile(..))
import Time
import Train exposing (Train)
import UrlHelper exposing (ConfirmEmailKey(..), UnsubscribeEmailKey(..))


user0 =
    Id.fromInt 0



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
                                { position = Coord.tuple ( 0, 0 )
                                , change = RailHorizontal
                                , userId = user0
                                }
                            |> Grid.getCell (Coord.tuple ( 0, 0 ))
                in
                case maybeCell of
                    Just cell ->
                        GridCell.flatten cell
                            |> Expect.equal
                                [ { position = Coord.tuple ( 0, 0 )
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
                                { position = Coord.tuple ( 21, 8 )
                                , change = HouseDown
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( 22, 8 )
                                , change = HouseDown
                                , userId = user0
                                }
                            |> Grid.getCell (Coord.tuple ( 1, 0 ))
                in
                case maybeCell of
                    Just cell ->
                        GridCell.flatten cell
                            |> Expect.equal
                                [ { position = Coord.tuple ( 6, 8 )
                                  , userId = user0
                                  , value = HouseDown
                                  }
                                ]

                    Nothing ->
                        Expect.fail "Cell not found"
        , test "Collision test for default collision and custom collision mask" <|
            \_ ->
                Tile.hasCollision
                    (Coord.tuple ( 0, 0 ))
                    (Tile.getData RailHorizontal)
                    (Coord.tuple ( 0, 0 ))
                    (Tile.getData RailBottomToRight)
                    |> Expect.equal False
        , test "Collision test 2 for default collision and custom collision mask" <|
            \_ ->
                Tile.hasCollision
                    (Coord.tuple ( 0, 0 ))
                    (Tile.getData RailHorizontal)
                    (Coord.tuple ( 1, 0 ))
                    (Tile.getData RailBottomToRight)
                    |> Expect.equal False
        , test "Move train" <|
            \_ ->
                let
                    grid =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.tuple ( 0, 0 )
                                , change = TrainHouseLeft
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( -4, 2 )
                                , change = RailBottomToRight
                                , userId = user0
                                }
                in
                Train.moveTrain
                    Train.defaultMaxSpeed
                    (Time.millisToPosix 0)
                    (Time.millisToPosix 1000)
                    { grid = grid, mail = AssocList.empty }
                    { position = Coord.tuple ( 0, 0 )
                    , path = Tile.trainHouseLeftRailPath
                    , previousPaths = []
                    , t = 0.5
                    , speed = Quantity -5
                    , stoppedAtPostOffice = Nothing
                    }
                    |> Expect.equal
                        { position = Coord.tuple ( -4, 2 )
                        , path = RailPathBottomToRight
                        , t = 0.5570423008216338
                        , speed = Quantity 5
                        , previousPaths =
                            [ { path = RailPathHorizontal { length = 3, offsetX = 0, offsetY = 2 }
                              , position = ( Quantity 0, Quantity 0 )
                              , reversed = False
                              }
                            ]
                        , stoppedAtPostOffice = Nothing
                        }
        , test "Train coach is correctly placed" <|
            \_ ->
                let
                    grid : Grid
                    grid =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.tuple ( 0, 0 )
                                , change = TrainHouseLeft
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( -4, 2 )
                                , change = RailBottomToRight
                                , userId = user0
                                }

                    train : Train
                    train =
                        Train.moveTrain
                            Train.defaultMaxSpeed
                            (Time.millisToPosix 0)
                            (Time.millisToPosix 1000)
                            { grid = grid, mail = AssocList.empty }
                            { position = Coord.tuple ( 0, 0 )
                            , path = Tile.trainHouseLeftRailPath
                            , previousPaths = []
                            , t = 0.5
                            , speed = Quantity -2
                            , stoppedAtPostOffice = Nothing
                            }
                in
                Train.getCoach train
                    |> Expect.equal
                        { position = Coord.tuple ( 0, 0 )
                        , path = RailPathHorizontal { length = 3, offsetX = 0, offsetY = 2 }
                        , t = 0
                        }
        , Test.only <|
            test "Train coach is correctly placed 2" <|
                \_ ->
                    let
                        grid : Grid
                        grid =
                            Grid.empty
                                |> Grid.addChange
                                    { position = Coord.tuple ( 0, 0 )
                                    , change = RailHorizontal
                                    , userId = user0
                                    }
                                |> Grid.addChange
                                    { position = Coord.tuple ( 1, 0 )
                                    , change = RailHorizontal
                                    , userId = user0
                                    }
                                |> Grid.addChange
                                    { position = Coord.tuple ( 2, 0 )
                                    , change = RailHorizontal
                                    , userId = user0
                                    }
                                |> Grid.addChange
                                    { position = Coord.tuple ( 3, 0 )
                                    , change = RailHorizontal
                                    , userId = user0
                                    }

                        train : Train
                        train =
                            Train.moveTrain
                                2
                                (Time.millisToPosix 0)
                                (Time.millisToPosix 1000)
                                { grid = grid, mail = AssocList.empty }
                                { position = Coord.tuple ( 0, 0 )
                                , path = RailPathHorizontal { length = 1, offsetX = 0, offsetY = 0 }
                                , previousPaths = []
                                , t = 0.7
                                , speed = Quantity 2
                                , stoppedAtPostOffice = Nothing
                                }
                    in
                    Train.getCoach train
                        |> Expect.equal
                            { position = Coord.tuple ( 0, 0 )
                            , path = RailPathHorizontal { length = 1, offsetX = 0, offsetY = 0 }
                            , t = 0.8
                            }
        , test "Move train with small steps equals single large step" <|
            \_ ->
                let
                    grid =
                        Grid.empty
                            |> Grid.addChange
                                { position = Coord.tuple ( 0, 0 )
                                , change = TrainHouseLeft
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( -1, 2 )
                                , change = RailHorizontal
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( -2, 2 )
                                , change = RailHorizontal
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( -6, 2 )
                                , change = RailBottomToRight
                                , userId = user0
                                }
                            |> Grid.addChange
                                { position = Coord.tuple ( -6, 6 )
                                , change = RailTopToRight
                                , userId = user0
                                }

                    milliseconds =
                        4000

                    smallSteps : Train
                    smallSteps =
                        List.range 1 200
                            |> List.foldl
                                (\_ train ->
                                    Train.moveTrain
                                        Train.defaultMaxSpeed
                                        (Time.millisToPosix 0)
                                        (Time.millisToPosix (milliseconds // 200))
                                        { grid = grid, mail = AssocList.empty }
                                        train
                                )
                                { position = Coord.tuple ( 0, 0 )
                                , path = Tile.trainHouseLeftRailPath
                                , t = 0.5
                                , speed = Quantity -0.1
                                , stoppedAtPostOffice = Nothing
                                , previousPaths = []
                                }

                    largeStep : Train
                    largeStep =
                        Train.moveTrain
                            Train.defaultMaxSpeed
                            (Time.millisToPosix 0)
                            (Time.millisToPosix milliseconds)
                            { grid = grid, mail = AssocList.empty }
                            { position = Coord.tuple ( 0, 0 )
                            , path = Tile.trainHouseLeftRailPath
                            , t = 0.5
                            , speed = Quantity -0.1
                            , stoppedAtPostOffice = Nothing
                            , previousPaths = []
                            }
                in
                trainsApproximatelyEqual smallSteps largeStep
        ]


trainsApproximatelyEqual : Train -> Train -> Expectation
trainsApproximatelyEqual expected actual =
    if
        (expected.path == actual.path)
            && (expected.speed |> Quantity.minus actual.speed |> Quantity.abs |> Quantity.lessThan (Quantity 0.01))
            && (expected.position == actual.position)
            && (abs (expected.t - actual.t) < 0.01)
            && (expected.previousPaths == actual.previousPaths)
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
