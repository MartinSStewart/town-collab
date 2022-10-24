module Tile exposing
    ( RailPath(..)
    , Tile(..)
    , allTiles
    , fromChar
    , getData
    , hasCollision
    , nearestRailT
    , size
    , texturePosition
    , tileToWorld
    , trainHouseLeftRailPath
    , trainHouseRightRailPath
    , worldToTile
    )

import Coord exposing (Coord)
import Dict exposing (Dict)
import List.Extra as List
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (CellLocalUnit, TileLocalUnit, WorldCoordinate, WorldPixel, WorldUnit)


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


texturePosition : Tile -> { topLeft : Vec2, bottomRight : Vec2 }
texturePosition tile =
    let
        ( Quantity.Quantity tileW, Quantity.Quantity tileH ) =
            size

        data =
            getData tile

        ( x, y ) =
            data.texturePosition

        ( w, h ) =
            data.size
    in
    { topLeft = Math.Vector2.vec2 (toFloat x * tileW) (toFloat y * tileH)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w) * tileW) (toFloat (y + h) * tileH)
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
    -> { t : Float, distance : Quantity Float TileLocalUnit }
nearestRailT position railPath =
    List.range 0 20
        |> List.map
            (\a ->
                let
                    t =
                        toFloat a / 20
                in
                { t = t, distance = Point2d.distanceFrom (railPath t) position }
            )
        |> Quantity.minimumBy .distance
        |> Maybe.withDefault { t = 0, distance = Quantity.zero }


getData : Tile -> TileData
getData tile =
    case tile of
        House ->
            { texturePosition = ( 0, 1 )
            , size = ( 3, 2 )
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
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
            , railPath =
                SingleRailPath
                    (\t ->
                        Point2d.unsafe
                            { x = 0.5 + 3.5 * sin (t * pi / 2)
                            , y = 0.5 + 3.5 * cos (t * pi / 2)
                            }
                    )
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
            , railPath =
                SingleRailPath
                    (\t ->
                        let
                            t2 =
                                1 - t
                        in
                        Point2d.unsafe
                            { x = 0.5 + 3.5 * cos (t * pi / 2)
                            , y = 0.5 + 3.5 * sin (t2 * pi / 2)
                            }
                    )
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
            , railPath = NoRailPath
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
            , railPath = NoRailPath
            }

        RailCrossing ->
            { texturePosition = ( 2, 0 )
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'e'
            , railPath = NoRailPath
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
            , char = 'U'
            , railPath = NoRailPath
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
            , char = 'J'
            , railPath = NoRailPath
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
            , char = 'I'
            , railPath = NoRailPath
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
            , char = 'K'
            , railPath = NoRailPath
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
            { texturePosition = ( 11, 0 )
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , char = 'i'
            , railPath = NoRailPath
            }

        RailStrafeRightSmall ->
            { texturePosition = ( 11, 4 )
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , char = 'k'
            , railPath = NoRailPath
            }


trainHouseLeftRailPath : Float -> Point2d TileLocalUnit TileLocalUnit
trainHouseLeftRailPath t =
    Point2d.unsafe { x = t * 3, y = 2.5 }


trainHouseRightRailPath : Float -> Point2d TileLocalUnit TileLocalUnit
trainHouseRightRailPath t =
    Point2d.unsafe { x = 1 + t * 3, y = 2.5 }
