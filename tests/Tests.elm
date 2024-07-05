module Tests exposing (tests)

import Animal exposing (AnimalType(..))
import AssocSet
import Backend
import Bytes exposing (Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Color
import Coord
import Effect.Test
import Effect.Time
import Effect.WebGL.Texture
import EndToEndTests
import Expect
import Grid exposing (Grid, IntersectionType(..))
import GridCell exposing (FrontendHistory)
import Id exposing (Id, UserId)
import IdDict
import Name
import Point2d
import Quantity
import Test exposing (Test, describe, test)
import TextInputMultiline
import Tile exposing (Tile(..))
import TileCountBot
import Time
import Train exposing (Train)
import Units
import Unsafe
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


mockTexture : Effect.WebGL.Texture.Texture
mockTexture =
    Effect.WebGL.Texture.loadBytesWith
        Effect.WebGL.Texture.defaultOptions
        ( 1, 1 )
        Effect.WebGL.Texture.rgba
        (Bytes.Encode.sequence [ Bytes.Encode.unsignedInt32 BE 0 ] |> Bytes.Encode.encode)
        |> Unsafe.unwrapResult


tests : Test
tests =
    describe "Tests"
        [ Test.describe
            "End to end tests"
            (List.map
                Effect.Test.toTest
                (EndToEndTests.tests mockTexture mockTexture mockTexture mockTexture mockTexture mockTexture)
            )
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
        , test "Move train" <|
            \_ ->
                let
                    addHorizontalRail : Int -> Grid FrontendHistory -> Grid FrontendHistory
                    addHorizontalRail x gridA =
                        Grid.addChangeFrontend
                            { position = Coord.tuple ( x, 0 )
                            , change = RailHorizontal
                            , userId = user0
                            , colors = { primaryColor = Color.white, secondaryColor = Color.white }
                            , time = Effect.Time.millisToPosix 0
                            }
                            gridA
                            |> .grid

                    grid : Grid FrontendHistory
                    grid =
                        List.range 0 16 |> List.foldl addHorizontalRail Grid.empty

                    train : Train
                    train =
                        Train.Train
                            { position = Coord.xy 0 0
                            , path = Tile.RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 }
                            , previousPaths = []
                            , t = 0.5
                            , speed = Train.stoppedSpeed
                            , home = Coord.xy -5 -5
                            , homePath = Tile.trainHouseLeftRailPath
                            , isStuckOrDerailed = Train.IsNotStuckOrDerailed
                            , status = Train.Travelling { startedAt = Time.millisToPosix 0 }
                            , owner = Id.fromInt 0
                            , color = Color.rgb255 80 80 80
                            }

                    moveTrainBy : Int -> Int -> Train -> Train
                    moveTrainBy start end a =
                        Train.moveTrains
                            (Time.millisToPosix end)
                            (Time.millisToPosix start)
                            (IdDict.fromList [ ( Id.fromInt 0, a ) ])
                            { grid = grid, mail = IdDict.empty }
                            |> IdDict.get (Id.fromInt 0)
                            |> Maybe.withDefault train

                    trainA =
                        List.range 1 120
                            |> List.foldl
                                (\_ state ->
                                    let
                                        newTime : Float
                                        newTime =
                                            state.time + 1000 / 60
                                    in
                                    { train = moveTrainBy (round state.time) (round newTime) state.train
                                    , time = newTime
                                    }
                                )
                                { train = train, time = 0 }

                    timeElapsed : Time.Posix
                    timeElapsed =
                        trainA.time |> round |> Time.millisToPosix

                    trainB : Train
                    trainB =
                        moveTrainBy 0 (Time.posixToMillis timeElapsed) train
                in
                Expect.all
                    [ \_ ->
                        Point2d.distanceFrom
                            (Train.trainPosition timeElapsed trainA.train)
                            (Point2d.fromTuple Units.tileUnit ( 2.7, 0.5 ))
                            |> Quantity.unwrap
                            |> Expect.lessThan 0.00000001
                    , \_ ->
                        Point2d.distanceFrom
                            (Train.trainPosition timeElapsed trainB)
                            (Point2d.fromTuple Units.tileUnit ( 2.7, 0.5 ))
                            |> Quantity.unwrap
                            |> Expect.lessThan 0.00000001
                    , \_ -> Expect.within (Expect.Absolute 0.00001) 2.1 (Quantity.unwrap (Train.speed timeElapsed trainA.train))
                    , \_ -> Expect.within (Expect.Absolute 0.00001) 2.1 (Quantity.unwrap (Train.speed timeElapsed trainB))
                    ]
                    ()
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
                    , name = Name.sven
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
        , describe
            "Multiline cursor roundtrips"
            (List.indexedMap
                (\index { cursorIndex, lines } ->
                    test (String.fromInt index) <|
                        \_ ->
                            TextInputMultiline.indexToCoord lines cursorIndex
                                |> TextInputMultiline.coordToIndex lines
                                |> Expect.equal cursorIndex
                )
                [ { cursorIndex = 6, lines = [ [ "test test test" ] ] }
                , { cursorIndex = 6, lines = [ [ "test", "test test" ] ] }
                , { cursorIndex = 10, lines = [ [ "test", "test", "test" ] ] }
                , { cursorIndex = 11, lines = [ [ "test" ], [ "abcd", "1234" ] ] }
                , { cursorIndex = 25, lines = [ [ "test" ], [ "abcd", "1234" ], [ "1", "2" ], [ "123" ], [ "qwer", "tyuuiop" ] ] }
                ]
            )
        ]


time : Int -> Effect.Time.Posix
time seconds =
    Effect.Time.millisToPosix ((seconds * 1000) + 10000000)
