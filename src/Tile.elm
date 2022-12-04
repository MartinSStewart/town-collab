module Tile exposing
    ( CollisionMask(..)
    , DefaultColor(..)
    , Direction(..)
    , RailData
    , RailPath(..)
    , RailPathType(..)
    , Tile(..)
    , TileData
    , allTiles
    , defaultPostOfficeColor
    , defaultToPrimaryAndSecondary
    , defaultTreeColor
    , getData
    , hasCollision
    , hasCollisionWithCoord
    , pathDirection
    , railDataReverse
    , railPathData
    , reverseDirection
    , rotateAntiClockwise
    , rotateClockwise
    , texturePositionPixels
    , texturePosition_
    , trainHouseLeftRailPath
    , trainHouseRightRailPath
    )

import Angle
import Axis2d
import Color exposing (Color)
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import List.Nonempty exposing (Nonempty)
import Math.Vector2 exposing (Vec2)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (CellLocalUnit, TileLocalUnit, WorldUnit)
import Vector2d


type Tile
    = EmptyTile
    | HouseDown
    | HouseRight
    | HouseUp
    | HouseLeft
    | RailHorizontal
    | RailVertical
    | RailBottomToRight
    | RailBottomToLeft
    | RailTopToRight
    | RailTopToLeft
    | RailBottomToRightLarge
    | RailBottomToLeftLarge
    | RailTopToRightLarge
    | RailTopToLeftLarge
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
    | MowedGrass1
    | MowedGrass4
    | PineTree


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
    | RailPathBottomToRightLarge
    | RailPathBottomToLeftLarge
    | RailPathTopToRightLarge
    | RailPathTopToLeftLarge
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


trackTurnRadiusLarge : number
trackTurnRadiusLarge =
    6


turnLength =
    trackTurnRadius * pi / 2


turnLengthLarge =
    trackTurnRadiusLarge * pi / 2


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


railPathBottomToRightLarge : RailData
railPathBottomToRightLarge =
    { path = bottomToRightPathLarge
    , distanceToT = \(Quantity distance) -> distance / turnLengthLarge
    , tToDistance = \t -> turnLengthLarge * t |> Quantity
    , startExitDirection = pathStartDirection bottomToRightPathLarge
    , endExitDirection = pathExitDirection bottomToRightPathLarge
    }


railPathBottomToLeftLarge : RailData
railPathBottomToLeftLarge =
    { path = bottomToLeftPathLarge
    , distanceToT = \(Quantity distance) -> distance / turnLengthLarge
    , tToDistance = \t -> turnLengthLarge * t |> Quantity
    , startExitDirection = pathStartDirection bottomToLeftPathLarge
    , endExitDirection = pathExitDirection bottomToLeftPathLarge
    }


railPathTopToRightLarge : RailData
railPathTopToRightLarge =
    { path = topToRightPathLarge
    , distanceToT = \(Quantity distance) -> distance / turnLengthLarge
    , tToDistance = \t -> turnLengthLarge * t |> Quantity
    , startExitDirection = pathStartDirection topToRightPathLarge
    , endExitDirection = pathExitDirection topToRightPathLarge
    }


railPathTopToLeftLarge : RailData
railPathTopToLeftLarge =
    { path = topToLeftPathLarge
    , distanceToT = \(Quantity distance) -> distance / turnLengthLarge
    , tToDistance = \t -> turnLengthLarge * t |> Quantity
    , startExitDirection = pathStartDirection topToLeftPathLarge
    , endExitDirection = pathExitDirection topToLeftPathLarge
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
    , distanceToT = \distance -> railData.distanceToT distance
    , tToDistance = \t -> railData.tToDistance t
    , startExitDirection = railData.endExitDirection
    , endExitDirection = railData.startExitDirection
    }


railPathData : RailPath -> RailData
railPathData railPath =
    case railPath of
        RailPathHorizontal { offsetX, offsetY, length } ->
            let
                path =
                    \t -> Point2d.unsafe { x = t * toFloat length + toFloat offsetX, y = toFloat offsetY + 0.5 }
            in
            { path = path
            , distanceToT = \(Quantity distance) -> distance / toFloat (abs length)
            , tToDistance = \t -> toFloat (abs length) * t |> Quantity
            , startExitDirection = pathStartDirection path
            , endExitDirection = pathExitDirection path
            }

        RailPathVertical { offsetX, offsetY, length } ->
            let
                path =
                    \t -> Point2d.unsafe { x = toFloat offsetX + 0.5, y = t * toFloat length + toFloat offsetY }
            in
            { path = path
            , distanceToT = \(Quantity distance) -> distance / (toFloat (abs length) * 1.3)
            , tToDistance = \t -> toFloat (abs length) * 1.3 * t |> Quantity
            , startExitDirection = pathStartDirection path
            , endExitDirection = pathExitDirection path
            }

        RailPathBottomToRight ->
            railPathBottomToRight

        RailPathBottomToLeft ->
            railPathBottomToLeft

        RailPathTopToRight ->
            railPathTopToRight

        RailPathTopToLeft ->
            railPathTopToLeft

        RailPathBottomToRightLarge ->
            railPathBottomToRightLarge

        RailPathBottomToLeftLarge ->
            railPathBottomToLeftLarge

        RailPathTopToRightLarge ->
            railPathTopToRightLarge

        RailPathTopToLeftLarge ->
            railPathTopToLeftLarge

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


texturePosition_ : ( Int, Int ) -> ( Int, Int ) -> { topLeft : Vec2, topRight : Vec2, bottomLeft : Vec2, bottomRight : Vec2 }
texturePosition_ position textureSize =
    let
        ( x, y ) =
            Coord.multiply Units.tileSize (Coord.tuple position) |> Coord.toTuple

        ( w, h ) =
            Coord.multiply Units.tileSize (Coord.tuple textureSize) |> Coord.toTuple
    in
    { topLeft = Math.Vector2.vec2 (toFloat x) (toFloat y)
    , topRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat y)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat (y + h))
    , bottomLeft = Math.Vector2.vec2 (toFloat x) (toFloat (y + h))
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
    , railPath : RailPathType
    , nextClockwise : Tile
    , defaultColors : DefaultColor
    }


type DefaultColor
    = ZeroDefaultColors
    | OneDefaultColor Color
    | TwoDefaultColors Color Color


defaultToPrimaryAndSecondary : DefaultColor -> { primaryColor : Color, secondaryColor : Color }
defaultToPrimaryAndSecondary defaultColors =
    case defaultColors of
        ZeroDefaultColors ->
            { primaryColor = Color.black, secondaryColor = Color.black }

        OneDefaultColor primary ->
            { primaryColor = primary, secondaryColor = Color.black }

        TwoDefaultColors primary secondary ->
            { primaryColor = primary, secondaryColor = secondary }


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
    , HouseDown
    , RailHorizontal
    , RailVertical
    , RailBottomToRight
    , RailBottomToLeft
    , RailTopToRight
    , RailTopToLeft
    , RailBottomToRightLarge
    , RailBottomToLeftLarge
    , RailTopToRightLarge
    , RailTopToLeftLarge
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
    , MowedGrass1
    , MowedGrass4
    , PineTree
    ]


type CollisionMask
    = DefaultCollision
    | CustomCollision (Set ( Int, Int ))


hasCollision :
    Coord c
    -> { a | size : ( Int, Int ), collisionMask : CollisionMask }
    -> Coord c
    -> { b | size : ( Int, Int ), collisionMask : CollisionMask }
    -> Bool
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
                        |> Coord.minus positionA

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
            Set.member (positionA |> Coord.minus positionB |> Coord.toTuple) setB


defaultHouseColors : DefaultColor
defaultHouseColors =
    TwoDefaultColors (Color.rgb255 234 66 36) (Color.rgb255 234 168 36)


defaultSidewalkColor : DefaultColor
defaultSidewalkColor =
    TwoDefaultColors (Color.rgb255 193 182 162) (Color.rgb255 170 160 140)


defaultTreeColor : DefaultColor
defaultTreeColor =
    TwoDefaultColors (Color.rgb255 24 150 65) (Color.rgb255 141 96 65)


defaultPostOfficeColor : DefaultColor
defaultPostOfficeColor =
    OneDefaultColor (Color.rgb255 209 209 209)


getData : Tile -> TileData
getData tile =
    case tile of
        EmptyTile ->
            { texturePosition = ( 0, 5 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            , nextClockwise = EmptyTile
            , defaultColors = ZeroDefaultColors
            }

        HouseDown ->
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
            , railPath = NoRailPath
            , nextClockwise = HouseLeft
            , defaultColors = defaultHouseColors
            }

        HouseRight ->
            { texturePosition = ( 11, 4 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 11, 16 ) }
            , size = ( 2, 4 )
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            , nextClockwise = HouseDown
            , defaultColors = defaultHouseColors
            }

        HouseUp ->
            { texturePosition = ( 15, 12 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 15, 15 ) }
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
            , railPath = NoRailPath
            , nextClockwise = HouseRight
            , defaultColors = defaultHouseColors
            }

        HouseLeft ->
            { texturePosition = ( 11, 0 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 11, 8 ) }
            , size = ( 2, 4 )
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                , ( 0, 3 )
                , ( 1, 3 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            , nextClockwise = HouseUp
            , defaultColors = defaultHouseColors
            }

        RailHorizontal ->
            { texturePosition = ( 0, 0 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = RailVertical
            , defaultColors = ZeroDefaultColors
            }

        RailVertical ->
            { texturePosition = ( 1, 0 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = RailHorizontal
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathBottomToRight
            , nextClockwise = RailBottomToLeft
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathBottomToLeft
            , nextClockwise = RailTopToLeft
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathTopToRight
            , nextClockwise = RailBottomToRight
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathTopToLeft
            , nextClockwise = RailTopToRight
            , defaultColors = ZeroDefaultColors
            }

        RailBottomToRightLarge ->
            { texturePosition = ( 0, 43 )
            , texturePositionTopLayer = Nothing
            , size = ( 6, 6 )
            , collisionMask =
                [ ( 5, 0 )
                , ( 4, 0 )
                , ( 3, 0 )
                , ( 2, 0 )

                --, ( 5, 1 )
                , ( 4, 1 )
                , ( 3, 1 )
                , ( 2, 1 )
                , ( 1, 1 )
                , ( 2, 2 )
                , ( 1, 2 )
                , ( 1, 3 )
                , ( 0, 3 )
                , ( 1, 4 )
                , ( 0, 4 )

                --, ( 1, 5 )
                , ( 0, 5 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = SingleRailPath RailPathBottomToRightLarge
            , nextClockwise = RailBottomToLeftLarge
            , defaultColors = ZeroDefaultColors
            }

        RailBottomToLeftLarge ->
            { texturePosition = ( 6, 43 )
            , texturePositionTopLayer = Nothing
            , size = ( 6, 6 )
            , collisionMask =
                [ ( 0, 0 )
                , ( 1, 0 )
                , ( 2, 0 )
                , ( 3, 0 )

                --, ( 0, 1 )
                , ( 1, 1 )
                , ( 2, 1 )
                , ( 3, 1 )
                , ( 4, 1 )
                , ( 3, 2 )
                , ( 4, 2 )
                , ( 4, 3 )
                , ( 5, 3 )
                , ( 4, 4 )
                , ( 5, 4 )

                --, ( 4, 5 )
                , ( 5, 5 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = SingleRailPath RailPathBottomToLeftLarge
            , nextClockwise = RailTopToLeftLarge
            , defaultColors = ZeroDefaultColors
            }

        RailTopToRightLarge ->
            { texturePosition = ( 0, 49 )
            , texturePositionTopLayer = Nothing
            , size = ( 6, 6 )
            , collisionMask =
                [ ( 5, 5 )
                , ( 4, 5 )
                , ( 3, 5 )
                , ( 2, 5 )

                --, ( 5, 4 )
                , ( 4, 4 )
                , ( 3, 4 )
                , ( 2, 4 )
                , ( 1, 4 )
                , ( 2, 3 )
                , ( 1, 3 )
                , ( 1, 2 )
                , ( 0, 2 )
                , ( 1, 1 )
                , ( 0, 1 )

                --, ( 1, 0 )
                , ( 0, 0 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = SingleRailPath RailPathTopToRightLarge
            , nextClockwise = RailBottomToRightLarge
            , defaultColors = ZeroDefaultColors
            }

        RailTopToLeftLarge ->
            { texturePosition = ( 6, 49 )
            , texturePositionTopLayer = Nothing
            , size = ( 6, 6 )
            , collisionMask =
                [ ( 0, 5 )
                , ( 1, 5 )
                , ( 2, 5 )
                , ( 3, 5 )

                --, ( 0, 4 )
                , ( 1, 4 )
                , ( 2, 4 )
                , ( 3, 4 )
                , ( 4, 4 )
                , ( 3, 3 )
                , ( 4, 3 )
                , ( 4, 2 )
                , ( 5, 2 )
                , ( 4, 1 )
                , ( 5, 1 )

                --, ( 4, 0 )
                , ( 5, 0 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = SingleRailPath RailPathTopToLeftLarge
            , nextClockwise = RailTopToRightLarge
            , defaultColors = ZeroDefaultColors
            }

        RailCrossing ->
            { texturePosition = ( 2, 0 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath =
                DoubleRailPath
                    (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
                    (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = RailCrossing
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathStrafeDown
            , nextClockwise = RailStrafeLeft
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathStrafeUp
            , nextClockwise = RailStrafeRight
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathStrafeLeft
            , nextClockwise = RailStrafeUp
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath RailPathStrafeRight
            , nextClockwise = RailStrafeDown
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath trainHouseRightRailPath
            , nextClockwise = TrainHouseLeft
            , defaultColors = ZeroDefaultColors
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
            , railPath = SingleRailPath trainHouseLeftRailPath
            , nextClockwise = TrainHouseRight
            , defaultColors = ZeroDefaultColors
            }

        RailStrafeDownSmall ->
            { texturePosition = ( 3, 15 )
            , texturePositionTopLayer = Nothing
            , size = ( 4, 2 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeDownSmall
            , nextClockwise = RailStrafeLeftSmall
            , defaultColors = ZeroDefaultColors
            }

        RailStrafeUpSmall ->
            { texturePosition = ( 7, 15 )
            , texturePositionTopLayer = Nothing
            , size = ( 4, 2 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeUpSmall
            , nextClockwise = RailStrafeRightSmall
            , defaultColors = ZeroDefaultColors
            }

        RailStrafeLeftSmall ->
            { texturePosition = ( 0, 21 )
            , texturePositionTopLayer = Nothing
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeLeftSmall
            , nextClockwise = RailStrafeUpSmall
            , defaultColors = ZeroDefaultColors
            }

        RailStrafeRightSmall ->
            { texturePosition = ( 0, 25 )
            , texturePositionTopLayer = Nothing
            , size = ( 2, 4 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeRightSmall
            , nextClockwise = RailStrafeDownSmall
            , defaultColors = ZeroDefaultColors
            }

        Sidewalk ->
            { texturePosition = ( 2, 4 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            , nextClockwise = Sidewalk
            , defaultColors = defaultSidewalkColor
            }

        SidewalkHorizontalRailCrossing ->
            { texturePosition = ( 0, 4 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = SidewalkVerticalRailCrossing
            , defaultColors = defaultSidewalkColor
            }

        SidewalkVerticalRailCrossing ->
            { texturePosition = ( 1, 4 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            , nextClockwise = SidewalkHorizontalRailCrossing
            , defaultColors = defaultSidewalkColor
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
            , railPath =
                DoubleRailPath
                    RailPathBottomToRight
                    (RailPathHorizontal { offsetX = 1, offsetY = 0, length = 3 })
            , nextClockwise = RailBottomToLeft_SplitUp
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathBottomToLeft
                    (RailPathVertical { offsetX = 3, offsetY = 1, length = 3 })
            , nextClockwise = RailTopToLeft_SplitRight
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathTopToRight
                    (RailPathVertical { offsetX = 0, offsetY = 0, length = 3 })
            , nextClockwise = RailBottomToRight_SplitLeft
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathTopToLeft
                    (RailPathHorizontal { offsetX = 0, offsetY = 3, length = 3 })
            , nextClockwise = RailTopToRight_SplitDown
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathBottomToRight
                    (RailPathVertical { offsetX = 0, offsetY = 1, length = 3 })
            , nextClockwise = RailBottomToLeft_SplitRight
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathBottomToLeft
                    (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 })
            , nextClockwise = RailTopToLeft_SplitDown
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathTopToRight
                    (RailPathHorizontal { offsetX = 1, offsetY = 3, length = 3 })
            , nextClockwise = RailBottomToRight_SplitUp
            , defaultColors = ZeroDefaultColors
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
            , railPath =
                DoubleRailPath
                    RailPathTopToLeft
                    (RailPathVertical { offsetX = 3, offsetY = 0, length = 3 })
            , nextClockwise = RailTopToRight_SplitLeft
            , defaultColors = ZeroDefaultColors
            }

        PostOffice ->
            { texturePosition = ( 0, 38 )
            , texturePositionTopLayer = Just { yOffset = -1, texturePosition = ( 0, 33 ) }
            , size = ( 4, 5 )
            , collisionMask = postOfficeCollision
            , railPath =
                SingleRailPath
                    (RailPathHorizontal { offsetX = 0, offsetY = 4, length = 4 })
            , nextClockwise = PostOffice
            , defaultColors = defaultPostOfficeColor
            }

        MowedGrass1 ->
            { texturePosition = ( 11, 20 )
            , texturePositionTopLayer = Nothing
            , size = ( 1, 1 )
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            , nextClockwise = MowedGrass4
            , defaultColors = ZeroDefaultColors
            }

        MowedGrass4 ->
            { texturePosition = ( 11, 20 )
            , texturePositionTopLayer = Nothing
            , size = ( 4, 4 )
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            , nextClockwise = MowedGrass4
            , defaultColors = ZeroDefaultColors
            }

        PineTree ->
            { texturePosition = ( 11, 24 )
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = ( 11, 24 ) }
            , size = ( 1, 2 )
            , collisionMask = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
            , railPath = NoRailPath
            , nextClockwise = PineTree
            , defaultColors = defaultTreeColor
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


topToLeftPathLarge : Float -> Point2d TileLocalUnit TileLocalUnit
topToLeftPathLarge t =
    Point2d.unsafe
        { x = (trackTurnRadiusLarge - 0.5) * sin (t * pi / 2)
        , y = (trackTurnRadiusLarge - 0.5) * cos (t * pi / 2)
        }


topToRightPathLarge : Float -> Point2d TileLocalUnit TileLocalUnit
topToRightPathLarge t =
    Point2d.unsafe
        { x = trackTurnRadiusLarge - (trackTurnRadiusLarge - 0.5) * sin (t * pi / 2)
        , y = (trackTurnRadiusLarge - 0.5) * cos (t * pi / 2)
        }


bottomToLeftPathLarge : Float -> Point2d TileLocalUnit TileLocalUnit
bottomToLeftPathLarge t =
    Point2d.unsafe
        { x = (trackTurnRadiusLarge - 0.5) * sin (t * pi / 2)
        , y = trackTurnRadiusLarge - (trackTurnRadiusLarge - 0.5) * cos (t * pi / 2)
        }


bottomToRightPathLarge : Float -> Point2d TileLocalUnit TileLocalUnit
bottomToRightPathLarge t =
    Point2d.unsafe
        { x = trackTurnRadiusLarge - (trackTurnRadiusLarge - 0.5) * sin (t * pi / 2)
        , y = trackTurnRadiusLarge - (trackTurnRadiusLarge - 0.5) * cos (t * pi / 2)
        }


trainHouseLeftRailPath : RailPath
trainHouseLeftRailPath =
    RailPathHorizontal { offsetX = 3, offsetY = 2, length = -3 }


trainHouseRightRailPath : RailPath
trainHouseRightRailPath =
    RailPathHorizontal { offsetX = 1, offsetY = 2, length = 3 }
