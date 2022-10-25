module Tile exposing
    ( RailPath(..)
    , Tile(..)
    , allTiles
    , fromChar
    , getData
    , hasCollision
    , nearestRailT
    , pathDirection
    , size
    , texturePosition
    , texturePosition_
    , tileToWorld
    , trainHouseLeftRailPath
    , trainHouseRightRailPath
    , worldToTile
    )

import Axis2d
import Coord exposing (Coord)
import Dict exposing (Dict)
import Direction2d exposing (Direction2d)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (CellLocalUnit, TileLocalUnit, WorldCoordinate, WorldPixel, WorldUnit)
import Vector2d


charToTile : Dict Char Tile
charToTile =
    List.map (\tile -> ( getData tile |> .char, tile )) allTiles |> Dict.fromList


fromChar : Char -> Maybe Tile
fromChar char =
    Dict.get char charToTile


size : ( Quantity number Pixels, Quantity number Pixels )
size =
    ( Pixels.pixels 18, Pixels.pixels 18 )


tileToWorld : Coord WorldUnit -> Coord WorldPixel
tileToWorld ( Quantity.Quantity x, Quantity.Quantity y ) =
    let
        ( w, h ) =
            size
    in
    ( Quantity.Quantity (Pixels.inPixels w * x), Quantity.Quantity (Pixels.inPixels h * y) )


worldToTile : Point2d WorldPixel WorldCoordinate -> Coord WorldUnit
worldToTile point =
    let
        ( w, h ) =
            size

        { x, y } =
            Point2d.unwrap point
    in
    ( Quantity.Quantity (x / Pixels.inPixels w |> floor), Quantity.Quantity (y / Pixels.inPixels h |> floor) )


type Tile
    = House
    | RailHorizontal
    | RailVertical
    | RailBottomToRight
    | RailBottomToLeft
    | RailTopToRight
    | RailTopToLeft
    | RailCrossing
    | RailStrafeDown
    | RailStrafeUp
    | RailStrafeLeft
    | RailStrafeRight
    | TrainHouseRight
    | TrainHouseLeft
    | RailStrafeDownSmall
    | RailStrafeUpSmall
    | RailStrafeLeftSmall
    | RailStrafeRightSmall
    | Sidewalk
    | SidewalkHorizontalRailCrossing
    | SidewalkVerticalRailCrossing
    | RailBottomToRight_SplitLeft
    | RailBottomToLeft_SplitUp
    | RailTopToRight_SplitDown
    | RailTopToLeft_SplitRight
    | RailBottomToRight_SplitUp
    | RailBottomToLeft_SplitRight
    | RailTopToRight_SplitLeft
    | RailTopToLeft_SplitDown


texturePosition : Tile -> { topLeft : Vec2, topRight : Vec2, bottomLeft : Vec2, bottomRight : Vec2 }
texturePosition tile =
    let
        data =
            getData tile
    in
    texturePosition_ data.texturePosition data.size


texturePosition_ : ( Int, Int ) -> ( Int, Int ) -> { topLeft : Vec2, topRight : Vec2, bottomLeft : Vec2, bottomRight : Vec2 }
texturePosition_ position textureSize =
    let
        ( Quantity.Quantity tileW, Quantity.Quantity tileH ) =
            size

        ( x, y ) =
            position

        ( w, h ) =
            textureSize
    in
    { topLeft = Math.Vector2.vec2 (toFloat x * tileW) (toFloat y * tileH)
    , topRight = Math.Vector2.vec2 (toFloat (x + w) * tileW) (toFloat y * tileH)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w) * tileW) (toFloat (y + h) * tileH)
    , bottomLeft = Math.Vector2.vec2 (toFloat x * tileW) (toFloat (y + h) * tileH)
    }


type alias TileData =
    { texturePosition : ( Int, Int )
    , size : ( Int, Int )
    , collisionMask : CollisionMask
    , char : Char
    , railPath : RailPath
    }


type RailPath
    = NoRailPath
    | SingleRailPath (Float -> Point2d TileLocalUnit TileLocalUnit)
    | DoubleRailPath (Float -> Point2d TileLocalUnit TileLocalUnit) (Float -> Point2d TileLocalUnit TileLocalUnit)


pathDirection : (Float -> Point2d TileLocalUnit TileLocalUnit) -> Float -> Direction2d TileLocalUnit
pathDirection path t =
    Direction2d.from (path (t - 0.001 |> max 1)) (path (t + 0.001 |> min 1))
        |> Maybe.withDefault Direction2d.x


allTiles : List Tile
allTiles =
    [ House
    , RailHorizontal
    , RailVertical
    , RailBottomToRight
    , RailBottomToLeft
    , RailTopToRight
    , RailTopToLeft
    , RailCrossing
    , RailStrafeUp
    , RailStrafeDown
    , RailStrafeLeft
    , RailStrafeRight
    , TrainHouseRight
    , TrainHouseLeft
    , RailStrafeUpSmall
    , RailStrafeDownSmall
    , RailStrafeLeftSmall
    , RailStrafeRightSmall
    , Sidewalk
    , SidewalkHorizontalRailCrossing
    , SidewalkVerticalRailCrossing
    , RailBottomToRight_SplitLeft
    , RailBottomToLeft_SplitUp
    , RailTopToRight_SplitDown
    , RailTopToLeft_SplitRight
    , RailBottomToRight_SplitUp
    , RailBottomToLeft_SplitRight
    , RailTopToRight_SplitLeft
    , RailTopToLeft_SplitDown
    ]


type CollisionMask
    = DefaultCollision
    | CustomCollision (Set ( Int, Int ))


hasCollision : Coord CellLocalUnit -> TileData -> Coord CellLocalUnit -> TileData -> Bool
hasCollision positionA tileA positionB tileB =
    let
        ( Quantity x, Quantity y ) =
            positionA

        ( Quantity x2, Quantity y2 ) =
            positionB

        ( width, height ) =
            tileA.size

        ( width2, height2 ) =
            tileB.size
    in
    case ( tileA.collisionMask, tileB.collisionMask ) of
        ( DefaultCollision, DefaultCollision ) ->
            ((x2 >= x && x2 < x + width) || (x >= x2 && x < x2 + width2))
                && ((y2 >= y && y2 < y + height) || (y >= y2 && y < y2 + height2))

        ( CustomCollision setA, DefaultCollision ) ->
            Set.toList setA
                |> List.any
                    (\( cx, cy ) ->
                        x2 <= x + cx && x2 + width2 > x + cx && y2 <= y + cy && y2 + height2 > y + cy
                    )

        ( DefaultCollision, CustomCollision setB ) ->
            Set.toList setB
                |> List.any
                    (\( cx, cy ) ->
                        x <= x2 + cx && x + width > x2 + cx && y <= y2 + cy && y + height > y2 + cy
                    )

        ( CustomCollision setA, CustomCollision setB ) ->
            let
                ( Quantity offsetX, Quantity offsetY ) =
                    positionB
                        |> Coord.minusTuple positionA

                intersection =
                    Set.map (\( cx, cy ) -> ( cx + offsetX, cy + offsetY )) setB
                        |> Set.intersect setA
            in
            Set.size intersection > 0


nearestRailT :
    Point2d TileLocalUnit TileLocalUnit
    -> (Float -> Point2d TileLocalUnit TileLocalUnit)
    -> { t : Float, distance : Quantity Float TileLocalUnit, direction : Direction2d TileLocalUnit }
nearestRailT position railPath =
    let
        { t, distance } =
            nearestRailTHelper 3 0 1 position railPath
    in
    { t = t, distance = distance, direction = pathDirection railPath t }


nearestRailTHelper :
    Int
    -> Float
    -> Float
    -> Point2d TileLocalUnit TileLocalUnit
    -> (Float -> Point2d TileLocalUnit TileLocalUnit)
    -> { t : Float, distance : Quantity Float TileLocalUnit }
nearestRailTHelper stepsLeft minT maxT position railPath =
    let
        detail =
            5

        minimumList =
            List.range 0 detail
                |> List.map
                    (\a ->
                        let
                            t =
                                (toFloat a / detail) * (maxT - minT) + minT
                        in
                        { t = t, distance = Point2d.distanceFrom (railPath t) position }
                    )
                |> Quantity.sortBy .distance
    in
    case minimumList of
        first :: second :: _ ->
            if stepsLeft <= 0 then
                first

            else
                nearestRailTHelper (stepsLeft - 1) first.t second.t position railPath

        _ ->
            { t = 0, distance = Quantity.zero }


getData : Tile -> TileData
getData tile =
    case tile of
        House ->
            { texturePosition = ( 0, 1 )
            , size = ( 3, 3 )
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'h'
            , railPath = NoRailPath
            }

        RailHorizontal ->
            { texturePosition = ( 0, 0 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'r'
            , railPath = SingleRailPath (\t -> Point2d.unsafe { x = t, y = 0.5 })
            }

        RailVertical ->
            { texturePosition = ( 1, 0 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'R'
            , railPath = SingleRailPath (\t -> Point2d.unsafe { x = 0.5, y = t })
            }

        RailBottomToRight ->
            { texturePosition = ( 3, 0 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 1, 0 )
                , ( 2, 0 )
                , ( 3, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'q'
            , railPath = SingleRailPath bottomToRight
            }

        RailBottomToLeft ->
            { texturePosition = ( 7, 0 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 2, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'w'
            , railPath = SingleRailPath bottomToLeftPath
            }

        RailTopToRight ->
            { texturePosition = ( 3, 4 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 1, 3 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'a'
            , railPath = SingleRailPath topToRightPath
            }

        RailTopToLeft ->
            { texturePosition = ( 7, 4 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 2, 0 )
                , ( 3, 0 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                , ( 2, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 's'
            , railPath = SingleRailPath topToLeftPath
            }

        RailCrossing ->
            { texturePosition = ( 2, 0 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'e'
            , railPath = DoubleRailPath (\t -> Point2d.unsafe { x = t, y = 0.5 }) (\t -> Point2d.unsafe { x = 0.5, y = t })
            }

        RailStrafeDown ->
            { texturePosition = ( 0, 8 )
            , size = ( 5, 3 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 2, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 4, 1 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 4, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'n'
            , railPath = SingleRailPath strafeDownPath
            }

        RailStrafeUp ->
            { texturePosition = ( 5, 8 )
            , size = ( 5, 3 )
            , collisionMask =
                [ ( 2, 0 )
                , ( 3, 0 )
                , ( 4, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 4, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'm'
            , railPath = SingleRailPath strafeUpPath
            }

        RailStrafeLeft ->
            { texturePosition = ( 0, 11 )
            , size = ( 3, 5 )
            , collisionMask =
                [ ( 0, 2 )
                , ( 0, 3 )
                , ( 0, 4 )
                , ( 1, 0 )
                , ( 1, 1 )
                , ( 1, 2 )
                , ( 1, 3 )
                , ( 1, 4 )
                , ( 2, 0 )
                , ( 2, 1 )
                , ( 2, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'N'
            , railPath = SingleRailPath strafeLeftPath
            }

        RailStrafeRight ->
            { texturePosition = ( 0, 16 )
            , size = ( 3, 5 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 0, 1 )
                , ( 0, 2 )
                , ( 1, 0 )
                , ( 1, 1 )
                , ( 1, 2 )
                , ( 1, 3 )
                , ( 1, 4 )
                , ( 2, 2 )
                , ( 2, 3 )
                , ( 2, 4 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'M'
            , railPath = SingleRailPath strafeRightPath
            }

        TrainHouseRight ->
            { texturePosition = ( 3, 11 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 't'
            , railPath = SingleRailPath trainHouseRightRailPath
            }

        TrainHouseLeft ->
            { texturePosition = ( 7, 11 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'T'
            , railPath = SingleRailPath trainHouseLeftRailPath
            }

        RailStrafeDownSmall ->
            { texturePosition = ( 3, 15 )
            , size = ( 4, 2 )
            , collisionMask = DefaultCollision
            , char = 'u'
            , railPath = NoRailPath
            }

        RailStrafeUpSmall ->
            { texturePosition = ( 7, 15 )
            , size = ( 4, 2 )
            , collisionMask = DefaultCollision
            , char = 'j'
            , railPath = NoRailPath
            }

        RailStrafeLeftSmall ->
            { texturePosition = ( 0, 21 )
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , char = 'U'
            , railPath = NoRailPath
            }

        RailStrafeRightSmall ->
            { texturePosition = ( 0, 25 )
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , char = 'J'
            , railPath = NoRailPath
            }

        Sidewalk ->
            { texturePosition = ( 2, 4 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'z'
            , railPath = NoRailPath
            }

        SidewalkHorizontalRailCrossing ->
            { texturePosition = ( 0, 4 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'x'
            , railPath = SingleRailPath (\t -> Point2d.unsafe { x = t, y = 0.5 })
            }

        SidewalkVerticalRailCrossing ->
            { texturePosition = ( 1, 4 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'X'
            , railPath = SingleRailPath (\t -> Point2d.unsafe { x = 0.5, y = t })
            }

        RailBottomToRight_SplitLeft ->
            { texturePosition = ( 3, 17 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 1, 0 )
                , ( 2, 0 )
                , ( 3, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'i'
            , railPath =
                DoubleRailPath
                    bottomToRight
                    (\t -> Point2d.unsafe { x = 1 + t * 3, y = 0.5 })
            }

        RailBottomToLeft_SplitUp ->
            { texturePosition = ( 7, 17 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 2, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'o'
            , railPath =
                DoubleRailPath
                    bottomToLeftPath
                    (\t -> Point2d.unsafe { x = 3.5, y = 1 + t * 3 })
            }

        RailTopToRight_SplitDown ->
            { texturePosition = ( 3, 21 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 1, 3 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'k'
            , railPath =
                DoubleRailPath
                    topToRightPath
                    (\t -> Point2d.unsafe { x = 0.5, y = t * 3 })
            }

        RailTopToLeft_SplitRight ->
            { texturePosition = ( 7, 21 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 2, 0 )
                , ( 3, 0 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                , ( 2, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'l'
            , railPath =
                DoubleRailPath
                    topToLeftPath
                    (\t -> Point2d.unsafe { x = t * 3, y = 3.5 })
            }

        RailBottomToRight_SplitUp ->
            { texturePosition = ( 3, 25 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 1, 0 )
                , ( 2, 0 )
                , ( 3, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'I'
            , railPath =
                DoubleRailPath
                    bottomToRight
                    (\t -> Point2d.unsafe { x = 0.5, y = 1 + t * 3 })
            }

        RailBottomToLeft_SplitRight ->
            { texturePosition = ( 7, 25 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 2, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'O'
            , railPath =
                DoubleRailPath
                    bottomToLeftPath
                    (\t -> Point2d.unsafe { x = t * 3, y = 0.5 })
            }

        RailTopToRight_SplitLeft ->
            { texturePosition = ( 3, 29 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 1, 3 )
                , ( 2, 3 )
                , ( 3, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'K'
            , railPath =
                DoubleRailPath
                    topToRightPath
                    (\t -> Point2d.unsafe { x = 1 + t * 3, y = 3.5 })
            }

        RailTopToLeft_SplitDown ->
            let
                _ =
                    abc
            in
            { texturePosition = ( 7, 29 )
            , size = ( 4, 4 )
            , collisionMask =
                [ ( 2, 0 )
                , ( 3, 0 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 2, 2 )
                , ( 3, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                , ( 2, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , char = 'L'
            , railPath =
                DoubleRailPath
                    topToLeftPath
                    (\t -> Point2d.unsafe { x = 3.5, y = t * 3 })
            }


abc =
    let
        detail =
            80
    in
    List.range 0 detail
        |> List.map
            (\a ->
                strafeRightPath (toFloat a / detail)
                    |> Point2d.unwrap
                    |> (\{ x, y } -> ( x, y ))
            )
        |> Debug.log "abc"


strafeDownPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeDownPath t =
    let
        t1 =
            0.01

        t1Speed =
            5

        t2 =
            0.5
    in
    if t < t1 then
        Point2d.unsafe { x = t * t1Speed, y = 0.5 }

    else if t <= t2 then
        bottomToLeftPath (t - t1)
            |> Point2d.translateBy (Vector2d.unsafe { x = t1 * t1Speed, y = 0 })

    else
        let
            { x, y } =
                strafeDownPath (1 - t) |> Point2d.unwrap
        in
        Point2d.unsafe { x = 5 - x, y = 3 - y }


strafeUpPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeUpPath t =
    strafeDownPath t |> Point2d.mirrorAcross (Axis2d.translateBy (Vector2d.unsafe { x = 0, y = 1.5 }) Axis2d.x)


strafeRightPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeRightPath t =
    let
        { x, y } =
            strafeDownPath t |> Point2d.unwrap
    in
    Point2d.unsafe { x = y, y = x }


strafeLeftPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeLeftPath t =
    strafeRightPath t |> Point2d.mirrorAcross (Axis2d.translateBy (Vector2d.unsafe { x = 1.5, y = 0 }) Axis2d.y)


topToLeftPath : Float -> Point2d TileLocalUnit TileLocalUnit
topToLeftPath t =
    Point2d.unsafe
        { x = 3.5 * sin (t * pi / 2)
        , y = 3.5 * cos (t * pi / 2)
        }


topToRightPath : Float -> Point2d TileLocalUnit TileLocalUnit
topToRightPath t =
    Point2d.unsafe
        { x = 4 - 3.5 * sin (t * pi / 2)
        , y = 3.5 * cos (t * pi / 2)
        }


bottomToLeftPath : Float -> Point2d TileLocalUnit TileLocalUnit
bottomToLeftPath t =
    Point2d.unsafe
        { x = 3.5 * sin (t * pi / 2)
        , y = 4 - 3.5 * cos (t * pi / 2)
        }


bottomToRight : Float -> Point2d TileLocalUnit TileLocalUnit
bottomToRight t =
    Point2d.unsafe
        { x = 4 - 3.5 * sin (t * pi / 2)
        , y = 4 - 3.5 * cos (t * pi / 2)
        }


trainHouseLeftRailPath : Float -> Point2d TileLocalUnit TileLocalUnit
trainHouseLeftRailPath t =
    Point2d.unsafe { x = t * 3, y = 2.5 }


trainHouseRightRailPath : Float -> Point2d TileLocalUnit TileLocalUnit
trainHouseRightRailPath t =
    Point2d.unsafe { x = 1 + t * 3, y = 2.5 }
