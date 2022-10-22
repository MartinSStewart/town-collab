module Tile exposing
    ( Tile(..)
    , allTiles
    , fromChar
    , getData
    , hasCollision
    , size
    , texturePosition
    , tileToWorld
    , worldToTile
    )

import Coord exposing (Coord)
import Dict exposing (Dict)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (LocalUnit, TileUnit, WorldCoordinate, WorldPixel)


charToTile : Dict Char Tile
charToTile =
    List.map (\tile -> ( getData tile |> .char, tile )) allTiles |> Dict.fromList


fromChar : Char -> Maybe Tile
fromChar char =
    Dict.get char charToTile


size : ( Quantity number Pixels, Quantity number Pixels )
size =
    ( Pixels.pixels 18, Pixels.pixels 18 )


tileToWorld : Coord TileUnit -> Coord WorldPixel
tileToWorld ( Quantity.Quantity x, Quantity.Quantity y ) =
    let
        ( w, h ) =
            size
    in
    ( Quantity.Quantity (Pixels.inPixels w * x), Quantity.Quantity (Pixels.inPixels h * y) )


worldToTile : Point2d WorldPixel WorldCoordinate -> Coord TileUnit
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
    { texturePosition : ( Int, Int ), size : ( Int, Int ), collisionMask : CollisionMask, char : Char }


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


hasCollision : Coord LocalUnit -> TileData -> Coord LocalUnit -> TileData -> Bool
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
            }

        RailHorizontal ->
            { texturePosition = ( 0, 0 ), size = ( 1, 1 ), collisionMask = DefaultCollision, char = 'r' }

        RailVertical ->
            { texturePosition = ( 1, 0 ), size = ( 1, 1 ), collisionMask = DefaultCollision, char = 'R' }

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
            }

        RailCrossing ->
            { texturePosition = ( 2, 0 ), size = ( 1, 1 ), collisionMask = DefaultCollision, char = 'e' }

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
            }

        RailStrafeDownSmall ->
            { texturePosition = ( 3, 15 ), size = ( 4, 2 ), collisionMask = DefaultCollision, char = 'u' }

        RailStrafeUpSmall ->
            { texturePosition = ( 7, 15 ), size = ( 4, 2 ), collisionMask = DefaultCollision, char = 'j' }

        RailStrafeLeftSmall ->
            { texturePosition = ( 11, 0 ), size = ( 2, 4 ), collisionMask = DefaultCollision, char = 'i' }

        RailStrafeRightSmall ->
            { texturePosition = ( 11, 4 ), size = ( 2, 4 ), collisionMask = DefaultCollision, char = 'k' }
