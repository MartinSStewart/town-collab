module Tile exposing
    ( Direction(..)
    , RailData
    , RailPath(..)
    , RailPathType(..)
    , Tile(..)
    , allTiles
    , fromChar
    , getData
    , hasCollision
    , hasCollisionWithCoord
    , pathDirection
    , railDataReverse
    , railPathData
    , reverseDirection
    , rotateAntiClockwise
    , rotateClockwise
    , texturePosition
    , texturePositionPixels
    , texturePosition_
    , trainHouseLeftRailPath
    , trainHouseRightRailPath
    )

import Angle
import Axis2d
import Coord exposing (Coord)
import Dict exposing (Dict)
import Direction2d exposing (Direction2d)
import List.Extra as List
import List.Nonempty exposing (Nonempty)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (CellLocalUnit, TileLocalUnit, WorldUnit)
import Vector2d


charToTile : Dict Char Tile
charToTile =
    List.map (\tile -> ( getData tile |> .char, tile )) allTiles |> Dict.fromList


fromChar : Char -> Maybe Tile
fromChar char =
    Dict.get char charToTile


type Tile
    = EmptyTile
    | House
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
    | PostOffice


type Direction
    = Left
    | Right
    | Up
    | Down


reverseDirection : Direction -> Direction
reverseDirection direction =
    case direction of
        Left ->
            Right

        Right ->
            Left

        Up ->
            Down

        Down ->
            Up


type RailPath
    = RailPathHorizontal { offsetX : Int, offsetY : Int, length : Int }
    | RailPathVertical { offsetX : Int, offsetY : Int, length : Int }
    | RailPathBottomToRight
    | RailPathBottomToLeft
    | RailPathTopToRight
    | RailPathTopToLeft
    | RailPathStrafeDown
    | RailPathStrafeUp
    | RailPathStrafeLeft
    | RailPathStrafeRight
    | RailPathStrafeDownSmall
    | RailPathStrafeUpSmall
    | RailPathStrafeLeftSmall
    | RailPathStrafeRightSmall


trackTurnRadius : number
trackTurnRadius =
    4


turnLength =
    trackTurnRadius * pi / 2


type alias RailData =
    { path : Float -> Point2d TileLocalUnit TileLocalUnit
    , distanceToT : Quantity Float TileLocalUnit -> Float
    , tToDistance : Float -> Quantity Float TileLocalUnit
    , startExitDirection : Direction
    , endExitDirection : Direction
    }


pathExitDirection : (Float -> Point2d units coordinates) -> Direction
pathExitDirection path =
    pathStartEndDirection 0.99 1 path


pathStartDirection : (Float -> Point2d units coordinates) -> Direction
pathStartDirection path =
    pathStartEndDirection 0.01 0 path


pathStartEndDirection : Float -> Float -> (Float -> Point2d units coordinates) -> Direction
pathStartEndDirection t1 t2 path =
    let
        angle =
            Direction2d.from (path t1) (path t2)
                |> Maybe.withDefault Direction2d.x
                |> Direction2d.toAngle
                |> Angle.inDegrees
    in
    if angle < -135 then
        Left

    else if angle < -45 then
        Up

    else if angle < 45 then
        Right

    else if angle < 135 then
        Down

    else
        Left


railPathBottomToRight : RailData
railPathBottomToRight =
    { path = bottomToRightPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection bottomToRightPath
    , endExitDirection = pathExitDirection bottomToRightPath
    }


railPathBottomToLeft : RailData
railPathBottomToLeft =
    { path = bottomToLeftPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection bottomToLeftPath
    , endExitDirection = pathExitDirection bottomToLeftPath
    }


railPathTopToRight : RailData
railPathTopToRight =
    { path = topToRightPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection topToRightPath
    , endExitDirection = pathExitDirection topToRightPath
    }


railPathTopToLeft : RailData
railPathTopToLeft =
    { path = topToLeftPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection topToLeftPath
    , endExitDirection = pathExitDirection topToLeftPath
    }


railPathStrafeDown : RailData
railPathStrafeDown =
    { path = strafeDownPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeDownPath
    , endExitDirection = pathExitDirection strafeDownPath
    }


railPathStrafeUp : RailData
railPathStrafeUp =
    { path = strafeUpPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeUpPath
    , endExitDirection = pathExitDirection strafeUpPath
    }


railPathStrafeLeft : RailData
railPathStrafeLeft =
    { path = strafeLeftPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeLeftPath
    , endExitDirection = pathExitDirection strafeLeftPath
    }


railPathStrafeRight : RailData
railPathStrafeRight =
    { path = strafeRightPath
    , distanceToT = \(Quantity distance) -> distance / turnLength
    , tToDistance = \t -> turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeRightPath
    , endExitDirection = pathExitDirection strafeRightPath
    }


railPathStrafeDownSmall : RailData
railPathStrafeDownSmall =
    { path = strafeDownSmallPath
    , distanceToT = \(Quantity distance) -> distance / (0.76 * turnLength)
    , tToDistance = \t -> 0.76 * turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeDownSmallPath
    , endExitDirection = pathExitDirection strafeDownSmallPath
    }


railPathStrafeUpSmall : RailData
railPathStrafeUpSmall =
    { path = strafeUpSmallPath
    , distanceToT = \(Quantity distance) -> distance / (0.76 * turnLength)
    , tToDistance = \t -> 0.76 * turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeUpSmallPath
    , endExitDirection = pathExitDirection strafeUpSmallPath
    }


railPathStrafeLeftSmall : RailData
railPathStrafeLeftSmall =
    { path = strafeLeftSmallPath
    , distanceToT = \(Quantity distance) -> distance / (0.76 * turnLength)
    , tToDistance = \t -> 0.76 * turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeLeftSmallPath
    , endExitDirection = pathExitDirection strafeLeftSmallPath
    }


railPathStrafeRightSmall : RailData
railPathStrafeRightSmall =
    { path = strafeRightSmallPath
    , distanceToT = \(Quantity distance) -> distance / (0.76 * turnLength)
    , tToDistance = \t -> 0.76 * turnLength * t |> Quantity
    , startExitDirection = pathStartDirection strafeRightSmallPath
    , endExitDirection = pathExitDirection strafeRightSmallPath
    }


railDataReverse : RailData -> RailData
railDataReverse railData =
    { path = \t -> railData.path (1 - t)
    , distanceToT = \distance -> 1 - railData.distanceToT distance
    , tToDistance = \t -> railData.tToDistance (1 - t)
    , startExitDirection = railData.endExitDirection
    , endExitDirection = railData.startExitDirection
    }


railPathData : RailPath -> RailData
railPathData railPath =
    case railPath of
        RailPathHorizontal { offsetX, offsetY, length } ->
            { path = \t -> Point2d.unsafe { x = t * toFloat length + toFloat offsetX, y = toFloat offsetY + 0.5 }
            , distanceToT = \(Quantity distance) -> distance / toFloat length
            , tToDistance = \t -> toFloat length * t |> Quantity
            , startExitDirection = Left
            , endExitDirection = Right
            }

        RailPathVertical { offsetX, offsetY, length } ->
            { path = \t -> Point2d.unsafe { x = toFloat offsetX + 0.5, y = t * toFloat length + toFloat offsetY }
            , distanceToT = \(Quantity distance) -> distance / toFloat length
            , tToDistance = \t -> toFloat length * t |> Quantity
            , startExitDirection = Up
            , endExitDirection = Down
            }

        RailPathBottomToRight ->
            railPathBottomToRight

        RailPathBottomToLeft ->
            railPathBottomToLeft

        RailPathTopToRight ->
            railPathTopToRight

        RailPathTopToLeft ->
            railPathTopToLeft

        RailPathStrafeDown ->
            railPathStrafeDown

        RailPathStrafeUp ->
            railPathStrafeUp

        RailPathStrafeLeft ->
            railPathStrafeLeft

        RailPathStrafeRight ->
            railPathStrafeRight

        RailPathStrafeDownSmall ->
            railPathStrafeDownSmall

        RailPathStrafeUpSmall ->
            railPathStrafeUpSmall

        RailPathStrafeLeftSmall ->
            railPathStrafeLeftSmall

        RailPathStrafeRightSmall ->
            railPathStrafeRightSmall


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
        ( x, y ) =
            position

        ( w, h ) =
            textureSize
    in
    { topLeft = Math.Vector2.vec2 (toFloat x * Units.tileSize) (toFloat y * Units.tileSize)
    , topRight = Math.Vector2.vec2 (toFloat (x + w) * Units.tileSize) (toFloat y * Units.tileSize)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w) * Units.tileSize) (toFloat (y + h) * Units.tileSize)
    , bottomLeft = Math.Vector2.vec2 (toFloat x * Units.tileSize) (toFloat (y + h) * Units.tileSize)
    }


texturePositionPixels : ( Int, Int ) -> ( Int, Int ) -> { topLeft : Vec2, topRight : Vec2, bottomLeft : Vec2, bottomRight : Vec2 }
texturePositionPixels position textureSize =
    let
        ( x, y ) =
            position

        ( w, h ) =
            textureSize
    in
    { topLeft = Math.Vector2.vec2 (toFloat x) (toFloat y)
    , topRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat y)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat (y + h))
    , bottomLeft = Math.Vector2.vec2 (toFloat x) (toFloat (y + h))
    }


type alias TileData =
    { texturePosition : ( Int, Int )
    , texturePositionTopLayer : Maybe { yOffset : Int, texturePosition : ( Int, Int ) }
    , size : ( Int, Int )
    , collisionMask : CollisionMask
    , char : Char
    , railPath : RailPathType
    , nextClockwise : Tile
    }


type RailPathType
    = NoRailPath
    | SingleRailPath RailPath
    | DoubleRailPath RailPath RailPath


pathDirection : (Float -> Point2d TileLocalUnit TileLocalUnit) -> Float -> Direction2d TileLocalUnit
pathDirection path t =
    Direction2d.from (path (t - 0.01 |> max 0)) (path (t + 0.01 |> min 1))
        |> Maybe.withDefault Direction2d.x


allTiles : List Tile
allTiles =
    [ EmptyTile
    , House
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
    , PostOffice
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


hasCollisionWithCoord : Coord CellLocalUnit -> Coord CellLocalUnit -> TileData -> Bool
hasCollisionWithCoord positionA positionB tileB =
    let
        ( Quantity x, Quantity y ) =
            positionA

        ( Quantity x2, Quantity y2 ) =
            positionB

        ( width2, height2 ) =
            tileB.size
    in
    case tileB.collisionMask of
        DefaultCollision ->
            (x >= x2 && x < x2 + width2) && (y >= y2 && y < y2 + height2)

        CustomCollision setB ->
            Set.member (positionA |> Coord.minusTuple positionB |> Coord.toTuple) setB


getData : Tile -> TileData
getData tile =
    case tile of
        EmptyTile ->
            { texturePosition = ( 0, 5 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = ' '
            , railPath = NoRailPath
            , nextClockwise = EmptyTile
            }

        House ->
            { texturePosition = ( 0, 1 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 0, 5 ) }
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
            , nextClockwise = House
            }

        RailHorizontal ->
            { texturePosition = ( 0, 0 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'r'
            , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = RailVertical
            }

        RailVertical ->
            { texturePosition = ( 1, 0 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'R'
            , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = RailHorizontal
            }

        RailBottomToRight ->
            { texturePosition = ( 3, 0 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathBottomToRight
            , nextClockwise = RailBottomToLeft
            }

        RailBottomToLeft ->
            { texturePosition = ( 7, 0 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathBottomToLeft
            , nextClockwise = RailTopToLeft
            }

        RailTopToRight ->
            { texturePosition = ( 3, 4 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathTopToRight
            , nextClockwise = RailBottomToRight
            }

        RailTopToLeft ->
            { texturePosition = ( 7, 4 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathTopToLeft
            , nextClockwise = RailTopToRight
            }

        RailCrossing ->
            { texturePosition = ( 2, 0 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'e'
            , railPath =
                DoubleRailPath
                    (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
                    (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = RailCrossing
            }

        RailStrafeDown ->
            { texturePosition = ( 0, 8 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathStrafeDown
            , nextClockwise = RailStrafeLeft
            }

        RailStrafeUp ->
            { texturePosition = ( 5, 8 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathStrafeUp
            , nextClockwise = RailStrafeRight
            }

        RailStrafeLeft ->
            { texturePosition = ( 0, 11 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathStrafeLeft
            , nextClockwise = RailStrafeUp
            }

        RailStrafeRight ->
            { texturePosition = ( 0, 16 )
            , texturePositionTopLayer = Nothing
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
            , railPath = SingleRailPath RailPathStrafeRight
            , nextClockwise = RailStrafeDown
            }

        TrainHouseRight ->
            { texturePosition = ( 3, 11 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 13, 8 ) }
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
            , nextClockwise = TrainHouseLeft
            }

        TrainHouseLeft ->
            { texturePosition = ( 7, 11 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 17, 8 ) }
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
            , nextClockwise = TrainHouseRight
            }

        RailStrafeDownSmall ->
            { texturePosition = ( 3, 15 )
            , texturePositionTopLayer = Nothing
            , size = ( 4, 2 )
            , collisionMask = DefaultCollision
            , char = 'u'
            , railPath = SingleRailPath RailPathStrafeDownSmall
            , nextClockwise = RailStrafeLeftSmall
            }

        RailStrafeUpSmall ->
            { texturePosition = ( 7, 15 )
            , texturePositionTopLayer = Nothing
            , size = ( 4, 2 )
            , collisionMask = DefaultCollision
            , char = 'j'
            , railPath = SingleRailPath RailPathStrafeUpSmall
            , nextClockwise = RailStrafeRightSmall
            }

        RailStrafeLeftSmall ->
            { texturePosition = ( 0, 21 )
            , texturePositionTopLayer = Nothing
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , char = 'U'
            , railPath = SingleRailPath RailPathStrafeLeftSmall
            , nextClockwise = RailStrafeUpSmall
            }

        RailStrafeRightSmall ->
            { texturePosition = ( 0, 25 )
            , texturePositionTopLayer = Nothing
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , char = 'J'
            , railPath = SingleRailPath RailPathStrafeRightSmall
            , nextClockwise = RailStrafeDownSmall
            }

        Sidewalk ->
            { texturePosition = ( 2, 4 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'z'
            , railPath = NoRailPath
            , nextClockwise = Sidewalk
            }

        SidewalkHorizontalRailCrossing ->
            { texturePosition = ( 0, 4 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'x'
            , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = SidewalkVerticalRailCrossing
            }

        SidewalkVerticalRailCrossing ->
            { texturePosition = ( 1, 4 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , char = 'X'
            , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = SidewalkHorizontalRailCrossing
            }

        RailBottomToRight_SplitLeft ->
            { texturePosition = ( 3, 17 )
            , texturePositionTopLayer = Nothing
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
                    RailPathBottomToRight
                    (RailPathHorizontal { offsetX = 1, offsetY = 0, length = 3 })
            , nextClockwise = RailBottomToLeft_SplitUp
            }

        RailBottomToLeft_SplitUp ->
            { texturePosition = ( 7, 17 )
            , texturePositionTopLayer = Nothing
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
                    RailPathBottomToLeft
                    (RailPathVertical { offsetX = 3, offsetY = 1, length = 3 })
            , nextClockwise = RailTopToLeft_SplitRight
            }

        RailTopToRight_SplitDown ->
            { texturePosition = ( 3, 21 )
            , texturePositionTopLayer = Nothing
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
                    RailPathTopToRight
                    (RailPathVertical { offsetX = 0, offsetY = 0, length = 3 })
            , nextClockwise = RailBottomToRight_SplitLeft
            }

        RailTopToLeft_SplitRight ->
            { texturePosition = ( 7, 21 )
            , texturePositionTopLayer = Nothing
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
                    RailPathTopToLeft
                    (RailPathHorizontal { offsetX = 0, offsetY = 3, length = 3 })
            , nextClockwise = RailTopToRight_SplitDown
            }

        RailBottomToRight_SplitUp ->
            { texturePosition = ( 3, 25 )
            , texturePositionTopLayer = Nothing
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
                    RailPathBottomToRight
                    (RailPathVertical { offsetX = 0, offsetY = 1, length = 3 })
            , nextClockwise = RailBottomToLeft_SplitRight
            }

        RailBottomToLeft_SplitRight ->
            { texturePosition = ( 7, 25 )
            , texturePositionTopLayer = Nothing
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
                    RailPathBottomToLeft
                    (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 })
            , nextClockwise = RailTopToLeft_SplitDown
            }

        RailTopToRight_SplitLeft ->
            { texturePosition = ( 3, 29 )
            , texturePositionTopLayer = Nothing
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
                    RailPathTopToRight
                    (RailPathHorizontal { offsetX = 1, offsetY = 3, length = 3 })
            , nextClockwise = RailBottomToRight_SplitUp
            }

        RailTopToLeft_SplitDown ->
            { texturePosition = ( 7, 29 )
            , texturePositionTopLayer = Nothing
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
                    RailPathTopToLeft
                    (RailPathVertical { offsetX = 3, offsetY = 0, length = 3 })
            , nextClockwise = RailTopToRight_SplitLeft
            }

        PostOffice ->
            { texturePosition = ( 0, 38 )
            , texturePositionTopLayer = Just { yOffset = -1, texturePosition = ( 0, 33 ) }
            , size = ( 4, 5 )
            , collisionMask = postOfficeCollision
            , char = 'p'
            , railPath =
                SingleRailPath
                    (RailPathHorizontal { offsetX = 0, offsetY = 4, length = 4 })
            , nextClockwise = PostOffice
            }


rotateClockwise : Tile -> Tile
rotateClockwise tile =
    getData tile |> .nextClockwise


rotateAntiClockwise : Tile -> Tile
rotateAntiClockwise tile =
    rotationAntiClockwiseHelper (List.Nonempty.singleton tile) |> List.Nonempty.head


rotationAntiClockwiseHelper : Nonempty Tile -> Nonempty Tile
rotationAntiClockwiseHelper list =
    let
        next =
            List.Nonempty.head list |> rotateClockwise
    in
    if List.Nonempty.any ((==) next) list then
        list

    else
        rotationAntiClockwiseHelper (List.Nonempty.cons next list)


postOfficeCollision =
    collsionRectangle 0 1 4 4


collsionRectangle x y width height =
    List.range x (x + width - 1)
        |> List.concatMap
            (\x2 ->
                List.range y (y + height - 1)
                    |> List.map (Tuple.pair x2)
            )
        |> Set.fromList
        |> CustomCollision


strafeDownSmallPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeDownSmallPath t =
    let
        t1 =
            0.05

        t1Speed =
            4

        t2 =
            0.5
    in
    if t < t1 then
        Point2d.unsafe { x = t * t1Speed, y = 0.5 }

    else if t <= t2 then
        bottomToLeftPath (0.76 * (t - t1))
            |> Point2d.translateBy (Vector2d.unsafe { x = t1 * t1Speed, y = 0 })

    else
        let
            { x, y } =
                strafeDownSmallPath (1 - t) |> Point2d.unwrap
        in
        Point2d.unsafe { x = 4 - x, y = 2 - y }


strafeUpSmallPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeUpSmallPath t =
    strafeDownSmallPath t |> Point2d.mirrorAcross (Axis2d.translateBy (Vector2d.unsafe { x = 0, y = 1 }) Axis2d.x)


strafeRightSmallPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeRightSmallPath t =
    let
        { x, y } =
            strafeDownSmallPath t |> Point2d.unwrap
    in
    Point2d.unsafe { x = y, y = x }


strafeLeftSmallPath : Float -> Point2d TileLocalUnit TileLocalUnit
strafeLeftSmallPath t =
    strafeRightSmallPath t |> Point2d.mirrorAcross (Axis2d.translateBy (Vector2d.unsafe { x = 1, y = 0 }) Axis2d.y)


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
        { x = (trackTurnRadius - 0.5) * sin (t * pi / 2)
        , y = (trackTurnRadius - 0.5) * cos (t * pi / 2)
        }


topToRightPath : Float -> Point2d TileLocalUnit TileLocalUnit
topToRightPath t =
    Point2d.unsafe
        { x = trackTurnRadius - (trackTurnRadius - 0.5) * sin (t * pi / 2)
        , y = (trackTurnRadius - 0.5) * cos (t * pi / 2)
        }


bottomToLeftPath : Float -> Point2d TileLocalUnit TileLocalUnit
bottomToLeftPath t =
    Point2d.unsafe
        { x = (trackTurnRadius - 0.5) * sin (t * pi / 2)
        , y = trackTurnRadius - (trackTurnRadius - 0.5) * cos (t * pi / 2)
        }


bottomToRightPath : Float -> Point2d TileLocalUnit TileLocalUnit
bottomToRightPath t =
    Point2d.unsafe
        { x = trackTurnRadius - (trackTurnRadius - 0.5) * sin (t * pi / 2)
        , y = trackTurnRadius - (trackTurnRadius - 0.5) * cos (t * pi / 2)
        }


trainHouseLeftRailPath : RailPath
trainHouseLeftRailPath =
    RailPathHorizontal { offsetX = 0, offsetY = 2, length = 3 }


trainHouseRightRailPath : RailPath
trainHouseRightRailPath =
    RailPathHorizontal { offsetX = 1, offsetY = 2, length = 3 }
