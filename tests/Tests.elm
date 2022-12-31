module Tests exposing (..)

import Color
import Coord exposing (Coord)
import Effect.Time
import Expect exposing (Expectation)
import Grid exposing (Grid)
import GridCell
import Id
import Quantity exposing (Quantity(..))
import Test exposing (Test, describe, test)
import Tile exposing (Direction(..), RailPath(..), Tile(..))
import Train exposing (Train(..))


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
                                , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                }
                            |> .grid
                            |> Grid.getCell (Coord.tuple ( 0, 0 ))
                in
                case maybeCell of
                    Just cell ->
                        GridCell.flatten cell
                            |> Expect.equal
                                [ { position = Coord.tuple ( 0, 0 )
                                  , userId = user0
                                  , value = RailHorizontal
                                  , colors = { primaryColor = Color.white, secondaryColor = Color.white }
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
                                , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                }
                            |> .grid
                            |> Grid.addChange
                                { position = Coord.tuple ( 22, 8 )
                                , change = HouseDown
                                , userId = user0
                                , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                }
                            |> .grid
                            |> Grid.getCell (Coord.tuple ( 1, 0 ))
                in
                case maybeCell of
                    Just cell ->
                        GridCell.flatten cell
                            |> Expect.equal
                                [ { position = Coord.tuple ( 6, 8 )
                                  , userId = user0
                                  , value = HouseDown
                                  , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                  }
                                ]

                    Nothing ->
                        Expect.fail "Cell not found"
        , test "Collision test for default collision and custom collision mask" <|
            \_ ->
                Tile.hasCollision
                    (Coord.tuple ( 0, 0 ))
                    RailHorizontal
                    (Coord.tuple ( 0, 0 ))
                    RailBottomToRight
                    |> Expect.equal False
        , test "Collision test 2 for default collision and custom collision mask" <|
            \_ ->
                Tile.hasCollision
                    (Coord.tuple ( 0, 0 ))
                    RailHorizontal
                    (Coord.tuple ( 1, 0 ))
                    RailBottomToRight
                    |> Expect.equal False

        --, test "Move train" <|
        --    \_ ->
        --        let
        --            grid =
        --                Grid.empty
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( 0, 0 )
        --                        , change = TrainHouseLeft
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( -4, 2 )
        --                        , change = RailBottomToRight
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --        in
        --        Train.moveTrain
        --            (Id.fromInt 0)
        --            Train.defaultMaxSpeed
        --            (Effect.Time.millisToPosix 0)
        --            (Effect.Time.millisToPosix 1000)
        --            { grid = grid, mail = AssocList.empty }
        --            (Train
        --                { position = Coord.tuple ( 0, 0 )
        --                , path = Tile.trainHouseLeftRailPath
        --                , previousPaths = []
        --                , t = 0.5
        --                , speed = Quantity -5
        --                , home = Coord.origin
        --                , homePath = Tile.trainHouseLeftRailPath
        --                , isStuck = Nothing
        --                , status = Train.Travelling
        --                , owner = Id.fromInt 123
        --                }
        --            )
        --            |> Expect.equal
        --                (Train
        --                    { position = Coord.tuple ( -4, 2 )
        --                    , path = RailPathBottomToRight
        --                    , previousPaths =
        --                        [ { path = RailPathHorizontal { length = 3, offsetX = 0, offsetY = 2 }
        --                          , position = ( Quantity 0, Quantity 0 )
        --                          , reversed = False
        --                          }
        --                        ]
        --                    , t = 0.5570423008216338
        --                    , speed = Quantity 5
        --                    , home = Coord.origin
        --                    , homePath = Tile.trainHouseLeftRailPath
        --                    , isStuck = Nothing
        --                    , status = Train.Travelling
        --                    , owner = Id.fromInt 123
        --                    }
        --                )
        --, test "Train coach is correctly placed" <|
        --    \_ ->
        --        let
        --            grid : Grid
        --            grid =
        --                Grid.empty
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( 0, 0 )
        --                        , change = TrainHouseLeft
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( -4, 2 )
        --                        , change = RailBottomToRight
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --
        --            train : Train
        --            train =
        --                Train.moveTrain
        --                    Train.defaultMaxSpeed
        --                    (Effect.Time.millisToPosix 0)
        --                    (Effect.Time.millisToPosix 1000)
        --                    { grid = grid, mail = AssocList.empty }
        --                    { position = Coord.tuple ( 0, 0 )
        --                    , path = Tile.trainHouseLeftRailPath
        --                    , previousPaths = []
        --                    , t = 0.5
        --                    , speed = Quantity -2
        --                    , stoppedAtPostOffice = Nothing
        --                    }
        --        in
        --        Train.getCoach train
        --            |> Expect.equal
        --                { position = Coord.tuple ( 0, 0 )
        --                , path = RailPathHorizontal { length = 3, offsetX = 0, offsetY = 2 }
        --                , t = 0
        --                }
        --, Test.only <|
        --    test "Train coach is correctly placed 2" <|
        --        \_ ->
        --            let
        --                grid : Grid
        --                grid =
        --                    Grid.empty
        --                        |> Grid.addChange
        --                            { position = Coord.tuple ( 0, 0 )
        --                            , change = RailHorizontal
        --                            , userId = user0
        --                            , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                            }
        --                        |> .grid
        --                        |> Grid.addChange
        --                            { position = Coord.tuple ( 1, 0 )
        --                            , change = RailHorizontal
        --                            , userId = user0
        --                            , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                            }
        --                        |> .grid
        --                        |> Grid.addChange
        --                            { position = Coord.tuple ( 2, 0 )
        --                            , change = RailHorizontal
        --                            , userId = user0
        --                            , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                            }
        --                        |> .grid
        --                        |> Grid.addChange
        --                            { position = Coord.tuple ( 3, 0 )
        --                            , change = RailHorizontal
        --                            , userId = user0
        --                            , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                            }
        --                        |> .grid
        --
        --                train : Train
        --                train =
        --                    Train.moveTrain
        --                        2
        --                        (Effect.Time.millisToPosix 0)
        --                        (Effect.Time.millisToPosix 1000)
        --                        { grid = grid, mail = AssocList.empty }
        --                        { position = Coord.tuple ( 0, 0 )
        --                        , path = RailPathHorizontal { length = 1, offsetX = 0, offsetY = 0 }
        --                        , previousPaths = []
        --                        , t = 0.7
        --                        , speed = Quantity 2
        --                        , stoppedAtPostOffice = Nothing
        --                        }
        --            in
        --            Train.getCoach train
        --                |> Expect.equal
        --                    { position = Coord.tuple ( 0, 0 )
        --                    , path = RailPathHorizontal { length = 1, offsetX = 0, offsetY = 0 }
        --                    , t = 0.8
        --                    }
        --, test "Move train with small steps equals single large step" <|
        --    \_ ->
        --        let
        --            grid =
        --                Grid.empty
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( 0, 0 )
        --                        , change = TrainHouseLeft
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( -1, 2 )
        --                        , change = RailHorizontal
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( -2, 2 )
        --                        , change = RailHorizontal
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( -6, 2 )
        --                        , change = RailBottomToRight
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --                    |> Grid.addChange
        --                        { position = Coord.tuple ( -6, 6 )
        --                        , change = RailTopToRight
        --                        , userId = user0
        --                        , colors = { primaryColor = Color.white, secondaryColor = Color.white }
        --                        }
        --                    |> .grid
        --
        --            milliseconds =
        --                4000
        --
        --            smallSteps : Train
        --            smallSteps =
        --                List.range 1 200
        --                    |> List.foldl
        --                        (\_ train ->
        --                            Train.moveTrain
        --                                Train.defaultMaxSpeed
        --                                (Effect.Time.millisToPosix 0)
        --                                (Effect.Time.millisToPosix (milliseconds // 200))
        --                                { grid = grid, mail = AssocList.empty }
        --                                train
        --                        )
        --                        { position = Coord.tuple ( 0, 0 )
        --                        , path = Tile.trainHouseLeftRailPath
        --                        , t = 0.5
        --                        , speed = Quantity -0.1
        --                        , stoppedAtPostOffice = Nothing
        --                        , previousPaths = []
        --                        }
        --
        --            largeStep : Train
        --            largeStep =
        --                Train.moveTrain
        --                    Train.defaultMaxSpeed
        --                    (Effect.Time.millisToPosix 0)
        --                    (Effect.Time.millisToPosix milliseconds)
        --                    { grid = grid, mail = AssocList.empty }
        --                    { position = Coord.tuple ( 0, 0 )
        --                    , path = Tile.trainHouseLeftRailPath
        --                    , t = 0.5
        --                    , speed = Quantity -0.1
        --                    , stoppedAtPostOffice = Nothing
        --                    , previousPaths = []
        --                    }
        --        in
        --        trainsApproximatelyEqual smallSteps largeStep
        ]


trainsApproximatelyEqual : Train -> Train -> Expectation
trainsApproximatelyEqual (Train expected) (Train actual) =
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


time seconds =
    Effect.Time.millisToPosix ((seconds * 1000) + 10000000)



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
