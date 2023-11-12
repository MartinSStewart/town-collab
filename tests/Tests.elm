module Tests exposing (tests)

import Animal exposing (AnimalType(..))
import AssocSet
import Backend
import Bytes.Decode
import Bytes.Encode
import Color
import Coord
import Effect.Test
import Effect.Time
import EndToEndTests
import Expect
import Grid exposing (IntersectionType(..))
import GridCell exposing (FrontendHistory)
import Id exposing (Id, UserId)
import IdDict
import Point2d
import Test exposing (Test, describe, test)
import Tile exposing (Tile(..))
import TileCountBot
import Units
import Vector2d


user0 : Id UserId
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
        [ Test.describe "End to end tests" (List.map Effect.Test.toTest EndToEndTests.tests)
        , test "Add rail" <|
            \_ ->
                let
                    maybeCell : Maybe (GridCell.Cell FrontendHistory)
                    maybeCell =
                        Grid.empty
                            |> Grid.addChangeFrontend
                                { position = Coord.tuple ( 0, 0 )
                                , change = RailHorizontal
                                , userId = user0
                                , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                , time = Effect.Time.millisToPosix 0
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
                                  , tile = RailHorizontal
                                  , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                  , time = Effect.Time.millisToPosix 0
                                  }
                                ]

                    Nothing ->
                        Expect.fail "Cell not found"
        , test "Add house overlaps neighbor" <|
            \_ ->
                let
                    maybeCell : Maybe (GridCell.Cell FrontendHistory)
                    maybeCell =
                        Grid.empty
                            |> Grid.addChangeFrontend
                                { position = Coord.tuple ( 21, 8 )
                                , change = HouseDown
                                , userId = user0
                                , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                , time = Effect.Time.millisToPosix 0
                                }
                            |> .grid
                            |> Grid.addChangeFrontend
                                { position = Coord.tuple ( 22, 8 )
                                , change = HouseDown
                                , userId = user0
                                , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                , time = Effect.Time.millisToPosix 0
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
                                  , tile = HouseDown
                                  , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                                  , time = Effect.Time.millisToPosix 0
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
        , test "Grid intersection test" <|
            \_ ->
                let
                    grid =
                        Grid.addChangeFrontend
                            { position = Coord.xy 1 0
                            , change = LogCabinDown
                            , userId = Id.fromInt 0
                            , colors = { primaryColor = Color.black, secondaryColor = Color.black }
                            , time = time 0
                            }
                            Grid.empty
                            |> .grid
                in
                Grid.rayIntersection
                    False
                    Vector2d.zero
                    (Point2d.xy (Units.tileUnit 0) (Units.tileUnit 1))
                    (Point2d.xy (Units.tileUnit 3) (Units.tileUnit 2))
                    grid
                    |> Expect.equal
                        (Just
                            { intersectionType = TileIntersection
                            , intersection = Point2d.unsafe { x = 1.1, y = 1.3666666666666667 }
                            }
                        )
        , test "Animal position" <|
            \_ ->
                Animal.actualPositionWithoutCursor
                    (time 3)
                    { animalType = Hamster
                    , startTime = time 0
                    , position = Point2d.origin
                    , endPosition = Point2d.unsafe { x = 10, y = 0 }
                    }
                    |> Expect.equal (Point2d.unsafe { x = 6, y = 0 })
        , test "Tile to int roundtrip" <|
            \_ ->
                Tile.allTiles
                    |> List.all
                        (\tile ->
                            let
                                tile2 =
                                    Tile.encoder tile |> Bytes.Encode.encode |> Bytes.Decode.decode Tile.decoder
                            in
                            tile2 == Just tile
                        )
                    |> Expect.equal True
        , test "Tiles all have unique ints" <|
            \_ ->
                List.map (\a -> Tile.encoder a |> Bytes.Encode.encode |> Bytes.Decode.decode Tile.decoder) Tile.allTiles
                    |> AssocSet.fromList
                    |> AssocSet.size
                    |> Expect.equal (List.length Tile.allTiles)
        , test "Undo bot change" <|
            \_ ->
                let
                    ( backendModel, userId ) =
                        (Backend.app_ False).init
                            |> Tuple.first
                            |> Backend.createBotUser TileCountBot.name
                in
                case IdDict.get userId backendModel.users of
                    Just user ->
                        Backend.localAddUndo backendModel userId user
                            |> (\( a, _, _ ) -> a)
                            |> (\model ->
                                    case IdDict.get userId model.users of
                                        Just user2 ->
                                            Backend.localGridChange
                                                (time 0)
                                                model
                                                { position = Coord.xy 1 -4
                                                , change = LogCabinDown
                                                , colors = { primaryColor = Color.black, secondaryColor = Color.black }
                                                , time = time 0
                                                }
                                                userId
                                                user2
                                                |> (\( a, _, _ ) -> a)
                                                |> (\model2 ->
                                                        case IdDict.get userId model2.users of
                                                            Just user3 ->
                                                                Backend.localUndo model2 userId user3
                                                                    |> (\( a, _, _ ) ->
                                                                            Grid.getCell (Coord.xy 0 -1) a.grid |> Maybe.map GridCell.flatten
                                                                       )
                                                                    |> Expect.equal (Just [])

                                                            Nothing ->
                                                                Expect.fail "User not found 3"
                                                   )

                                        Nothing ->
                                            Expect.fail "User not found 2"
                               )

                    Nothing ->
                        Expect.fail "User not found"
        ]


time : Int -> Effect.Time.Posix
time seconds =
    Effect.Time.millisToPosix ((seconds * 1000) + 10000000)
