module Tile exposing
    ( CollisionMask(..)
    , DefaultColor(..)
    , Direction(..)
    , RailData
    , RailPath(..)
    , RailPathType(..)
    , Tile(..)
    , TileData
    , TileGroup(..)
    , allTileGroups
    , defaultPostOfficeColor
    , defaultToPrimaryAndSecondary
    , defaultTreeColor
    , getData
    , getTileGroupData
    , hasCollision
    , hasCollisionWithCoord
    , pathDirection
    , railDataReverse
    , railPathData
    , reverseDirection
    , texturePositionPixels
    , texturePosition_
    , tileToTileGroup
    , trainHouseLeftRailPath
    , trainHouseRightRailPath
    )

import Angle
import Axis2d
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (CellLocalUnit, TileLocalUnit, WorldUnit)
import Vector2d


type TileGroup
    = EmptyTileGroup
    | HouseGroup
    | RailStraightGroup
    | RailTurnGroup
    | RailTurnLargeGroup
    | RailStrafeGroup
    | RailStrafeSmallGroup
    | RailCrossingGroup
    | TrainHouseGroup
    | SidewalkGroup
    | SidewalkRailGroup
    | RailTurnSplitGroup
    | RailTurnSplitMirrorGroup
    | PostOfficeGroup
    | PineTreeGroup
    | LogCabinGroup
    | RoadStraightGroup
    | RoadTurnGroup
    | Road4WayGroup
    | RoadSidewalkCrossingGroup
    | Road3WayGroup
    | RoadRailCrossingGroup
    | RoadDeadendGroup
    | FenceStraightGroup
    | BusStopGroup
    | HospitalGroup


allTileGroups : List TileGroup
allTileGroups =
    [ EmptyTileGroup
    , HouseGroup
    , RailStraightGroup
    , RailTurnGroup
    , RailTurnLargeGroup
    , RailStrafeGroup
    , RailStrafeSmallGroup
    , RailCrossingGroup
    , TrainHouseGroup
    , SidewalkGroup
    , SidewalkRailGroup
    , RailTurnSplitGroup
    , RailTurnSplitMirrorGroup
    , PostOfficeGroup
    , PineTreeGroup
    , LogCabinGroup
    , RoadStraightGroup
    , RoadTurnGroup
    , Road4WayGroup
    , RoadSidewalkCrossingGroup
    , Road3WayGroup
    , RoadRailCrossingGroup
    , RoadDeadendGroup
    , FenceStraightGroup
    , BusStopGroup
    , HospitalGroup
    ]


tileToTileGroup : Tile -> Maybe TileGroup
tileToTileGroup tile =
    List.find
        (\tileGroup ->
            getTileGroupData tileGroup |> .tiles |> List.Nonempty.any ((==) tile)
        )
        allTileGroups


type alias TileGroupData =
    { defaultColors : DefaultColor
    , tiles : Nonempty Tile
    , name : String
    }


getTileGroupData : TileGroup -> TileGroupData
getTileGroupData tileGroup =
    case tileGroup of
        EmptyTileGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty EmptyTile []
            , name = "Eraser"
            }

        HouseGroup ->
            { defaultColors = defaultHouseColors
            , tiles = Nonempty HouseDown [ HouseLeft, HouseUp, HouseRight ]
            , name = "Brick house"
            }

        RailStraightGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty RailHorizontal [ RailVertical ]
            , name = "Rail"
            }

        RailTurnGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty RailBottomToLeft [ RailTopToLeft, RailTopToRight, RailBottomToRight ]
            , name = "Rail turn"
            }

        RailTurnLargeGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty RailBottomToLeftLarge [ RailTopToLeftLarge, RailTopToRightLarge, RailBottomToRightLarge ]
            , name = "Big rail turn"
            }

        RailStrafeGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty RailStrafeDown [ RailStrafeLeft, RailStrafeUp, RailStrafeRight ]
            , name = "Big rail bend"
            }

        RailStrafeSmallGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty RailStrafeDownSmall [ RailStrafeLeftSmall, RailStrafeUpSmall, RailStrafeRightSmall ]
            , name = "Rail bend"
            }

        RailCrossingGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty RailCrossing []
            , name = "Rail X'ing"
            }

        TrainHouseGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty TrainHouseRight [ TrainHouseLeft ]
            , name = "Train house"
            }

        SidewalkGroup ->
            { defaultColors = defaultSidewalkColor
            , tiles = Nonempty Sidewalk []
            , name = "Sidewalk"
            }

        SidewalkRailGroup ->
            { defaultColors = defaultSidewalkColor
            , tiles = Nonempty SidewalkHorizontalRailCrossing [ SidewalkVerticalRailCrossing ]
            , name = "Rail crossing"
            }

        RailTurnSplitGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles =
                Nonempty
                    RailBottomToRight_SplitLeft
                    [ RailBottomToLeft_SplitUp, RailTopToLeft_SplitRight, RailTopToRight_SplitDown ]
            , name = "Rail split L."
            }

        RailTurnSplitMirrorGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles =
                Nonempty
                    RailTopToLeft_SplitDown
                    [ RailTopToRight_SplitLeft, RailBottomToRight_SplitUp, RailBottomToLeft_SplitRight ]
            , name = "Rail split R."
            }

        PostOfficeGroup ->
            { defaultColors = defaultPostOfficeColor
            , tiles = Nonempty PostOffice []
            , name = "Post office"
            }

        PineTreeGroup ->
            { defaultColors = defaultTreeColor
            , tiles = Nonempty PineTree []
            , name = "Pine tree"
            }

        LogCabinGroup ->
            { defaultColors = defaultLogCabinColor
            , tiles = Nonempty LogCabinDown [ LogCabinLeft, LogCabinUp, LogCabinRight ]
            , name = "Log cabin"
            }

        RoadStraightGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty RoadHorizontal [ RoadVertical ]
            , name = "Road"
            }

        RoadTurnGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty RoadBottomToLeft [ RoadTopToLeft, RoadTopToRight, RoadBottomToRight ]
            , name = "Road turn"
            }

        Road4WayGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty Road4Way []
            , name = "Road 4-way"
            }

        RoadSidewalkCrossingGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty RoadSidewalkCrossingHorizontal [ RoadSidewalkCrossingVertical ]
            , name = "Crosswalk"
            }

        Road3WayGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty Road3WayDown [ Road3WayLeft, Road3WayUp, Road3WayRight ]
            , name = "Road 3-way"
            }

        RoadRailCrossingGroup ->
            { defaultColors = OneDefaultColor sidewalkColor
            , tiles = Nonempty RoadRailCrossingHorizontal [ RoadRailCrossingVertical ]
            , name = "Rail-road"
            }

        FenceStraightGroup ->
            { defaultColors = defaultFenceColor
            , tiles = Nonempty FenceHorizontal [ FenceDiagonal, FenceVertical, FenceAntidiagonal ]
            , name = "Fence"
            }

        RoadDeadendGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty RoadDeadendDown [ RoadDeadendUp ]
            , name = "Boulevard"
            }

        BusStopGroup ->
            { defaultColors = defaultBusStopColor
            , tiles = Nonempty BusStopDown [ BusStopLeft, BusStopUp, BusStopRight ]
            , name = "Bus stop"
            }

        HospitalGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty Hospital []
            , name = "Hospital"
            }


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
    | LogCabinDown
    | LogCabinRight
    | LogCabinUp
    | LogCabinLeft
    | RoadHorizontal
    | RoadVertical
    | RoadBottomToLeft
    | RoadTopToLeft
    | RoadTopToRight
    | RoadBottomToRight
    | Road4Way
    | RoadSidewalkCrossingHorizontal
    | RoadSidewalkCrossingVertical
    | Road3WayDown
    | Road3WayLeft
    | Road3WayUp
    | Road3WayRight
    | RoadRailCrossingHorizontal
    | RoadRailCrossingVertical
    | FenceHorizontal
    | FenceVertical
    | FenceDiagonal
    | FenceAntidiagonal
    | RoadDeadendUp
    | RoadDeadendDown
    | BusStopDown
    | BusStopLeft
    | BusStopRight
    | BusStopUp
    | Hospital


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


texturePosition_ : Coord unit -> Coord unit -> { topLeft : Vec2, topRight : Vec2, bottomLeft : Vec2, bottomRight : Vec2 }
texturePosition_ position textureSize =
    let
        ( x, y ) =
            Coord.multiply Units.tileSize position |> Coord.toTuple

        ( w, h ) =
            Coord.multiply Units.tileSize textureSize |> Coord.toTuple
    in
    { topLeft = Math.Vector2.vec2 (toFloat x) (toFloat y)
    , topRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat y)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat (y + h))
    , bottomLeft = Math.Vector2.vec2 (toFloat x) (toFloat (y + h))
    }


texturePositionPixels : Coord b -> Coord b -> { topLeft : Vec2, topRight : Vec2, bottomLeft : Vec2, bottomRight : Vec2 }
texturePositionPixels position textureSize =
    let
        ( x, y ) =
            Coord.toTuple position

        ( w, h ) =
            Coord.toTuple textureSize
    in
    { topLeft = Math.Vector2.vec2 (toFloat x) (toFloat y)
    , topRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat y)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w)) (toFloat (y + h))
    , bottomLeft = Math.Vector2.vec2 (toFloat x) (toFloat (y + h))
    }


type alias TileData unit =
    { texturePosition : Maybe (Coord unit)
    , texturePositionTopLayer : Maybe { yOffset : Int, texturePosition : Coord unit }
    , size : Coord unit
    , collisionMask : CollisionMask
    , railPath : RailPathType
    }


type DefaultColor
    = ZeroDefaultColors
    | OneDefaultColor Color
    | TwoDefaultColors Colors


defaultToPrimaryAndSecondary : DefaultColor -> Colors
defaultToPrimaryAndSecondary defaultColors =
    case defaultColors of
        ZeroDefaultColors ->
            { primaryColor = Color.black, secondaryColor = Color.black }

        OneDefaultColor primary ->
            { primaryColor = primary, secondaryColor = Color.black }

        TwoDefaultColors colors ->
            colors


type RailPathType
    = NoRailPath
    | SingleRailPath RailPath
    | DoubleRailPath RailPath RailPath
    | RailSplitPath { primary : RailPath, secondary : RailPath, texturePosition : Coord Pixels }


pathDirection : (Float -> Point2d TileLocalUnit TileLocalUnit) -> Float -> Direction2d TileLocalUnit
pathDirection path t =
    Direction2d.from (path (t - 0.01 |> max 0)) (path (t + 0.01 |> min 1))
        |> Maybe.withDefault Direction2d.x


type CollisionMask
    = DefaultCollision
    | CustomCollision (Set ( Int, Int ))


hasCollision : Coord c -> Tile -> Coord c -> Tile -> Bool
hasCollision positionA tileA positionB tileB =
    let
        tileDataA =
            getData tileA

        tileDataB =
            getData tileB

        ( Quantity x, Quantity y ) =
            positionA

        ( Quantity x2, Quantity y2 ) =
            positionB

        ( Quantity width, Quantity height ) =
            tileDataA.size

        ( Quantity width2, Quantity height2 ) =
            tileDataB.size
    in
    if
        ((isFence tileA && tileA == tileB) && positionA /= positionB)
            || (isFence tileA && isFence tileB && tileA /= tileB)
    then
        False

    else
        case ( tileDataA.collisionMask, tileDataB.collisionMask ) of
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


isFence tile =
    tile == FenceHorizontal || tile == FenceVertical || tile == FenceDiagonal || tile == FenceAntidiagonal


hasCollisionWithCoord : Coord CellLocalUnit -> Coord CellLocalUnit -> TileData unit -> Bool
hasCollisionWithCoord positionA positionB tileB =
    let
        ( Quantity x, Quantity y ) =
            positionA

        ( Quantity x2, Quantity y2 ) =
            positionB

        ( Quantity width2, Quantity height2 ) =
            tileB.size
    in
    case tileB.collisionMask of
        DefaultCollision ->
            (x >= x2 && x < x2 + width2) && (y >= y2 && y < y2 + height2)

        CustomCollision setB ->
            Set.member (positionA |> Coord.minus positionB |> Coord.toTuple) setB


defaultHouseColors : DefaultColor
defaultHouseColors =
    TwoDefaultColors { primaryColor = Color.rgb255 234 100 66, secondaryColor = Color.rgb255 234 168 36 }


sidewalkColor =
    Color.rgb255 193 182 162


defaultSidewalkColor : DefaultColor
defaultSidewalkColor =
    OneDefaultColor sidewalkColor


defaultFenceColor : DefaultColor
defaultFenceColor =
    OneDefaultColor (Color.rgb255 220 129 97)


defaultTreeColor : DefaultColor
defaultTreeColor =
    TwoDefaultColors { primaryColor = Color.rgb255 24 150 65, secondaryColor = Color.rgb255 141 96 65 }


defaultPostOfficeColor : DefaultColor
defaultPostOfficeColor =
    TwoDefaultColors { primaryColor = sidewalkColor, secondaryColor = Color.rgb255 209 209 209 }


defaultLogCabinColor : DefaultColor
defaultLogCabinColor =
    TwoDefaultColors { primaryColor = Color.rgb255 220 129 97, secondaryColor = Color.rgb255 236 202 66 }


defaultRoadColor : DefaultColor
defaultRoadColor =
    TwoDefaultColors { primaryColor = sidewalkColor, secondaryColor = Color.rgb255 243 243 243 }


defaultBusStopColor : DefaultColor
defaultBusStopColor =
    TwoDefaultColors { primaryColor = sidewalkColor, secondaryColor = Color.rgb255 250 202 16 }


getData : Tile -> TileData unit
getData tile =
    case tile of
        EmptyTile ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        HouseDown ->
            { texturePosition = Coord.xy 0 1 |> Just
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 0 5 }
            , size = Coord.xy 3 3
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
            }

        HouseRight ->
            { texturePosition = Coord.xy 11 4 |> Just
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 16 }
            , size = Coord.xy 2 4
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
            }

        HouseUp ->
            { texturePosition = Coord.xy 15 12 |> Just
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 15 15 }
            , size = Coord.xy 3 3
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
            }

        HouseLeft ->
            { texturePosition = Coord.xy 11 0 |> Just
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 8 }
            , size = Coord.xy 2 4
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
            }

        RailHorizontal ->
            { texturePosition = Coord.xy 0 0 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            }

        RailVertical ->
            { texturePosition = Coord.xy 1 0 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            }

        RailBottomToRight ->
            { texturePosition = Coord.xy 3 0 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
            }

        RailBottomToLeft ->
            { texturePosition = Coord.xy 7 0 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
            }

        RailTopToRight ->
            { texturePosition = Coord.xy 3 4 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
            }

        RailTopToLeft ->
            { texturePosition = Coord.xy 7 4 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
            }

        RailBottomToRightLarge ->
            { texturePosition = Coord.xy 0 43 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 6 6
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
            }

        RailBottomToLeftLarge ->
            { texturePosition = Coord.xy 6 43 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 6 6
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
            }

        RailTopToRightLarge ->
            { texturePosition = Coord.xy 0 49 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 6 6
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
            }

        RailTopToLeftLarge ->
            { texturePosition = Coord.xy 6 49 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 6 6
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
            }

        RailCrossing ->
            { texturePosition = Coord.xy 2 0 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath =
                DoubleRailPath
                    (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
                    (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            }

        RailStrafeDown ->
            { texturePosition = Coord.xy 0 8 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 5 3
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
            }

        RailStrafeUp ->
            { texturePosition = Coord.xy 5 8 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 5 3
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
            }

        RailStrafeLeft ->
            { texturePosition = Coord.xy 0 11 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 5
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
            }

        RailStrafeRight ->
            { texturePosition = Coord.xy 0 16 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 5
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
            }

        TrainHouseRight ->
            { texturePosition = Coord.xy 3 11 |> Just
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 13 8 }
            , size = Coord.xy 4 4
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
            }

        TrainHouseLeft ->
            { texturePosition = Coord.xy 7 11 |> Just
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 17 8 }
            , size = Coord.xy 4 4
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
            }

        RailStrafeDownSmall ->
            { texturePosition = Coord.xy 3 15 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 2
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeDownSmall
            }

        RailStrafeUpSmall ->
            { texturePosition = Coord.xy 7 15 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 2
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeUpSmall
            }

        RailStrafeLeftSmall ->
            { texturePosition = Coord.xy 0 21 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 2 4
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeLeftSmall
            }

        RailStrafeRightSmall ->
            { texturePosition = Coord.xy 0 25 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 2 4
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath RailPathStrafeRightSmall
            }

        Sidewalk ->
            { texturePosition = Coord.xy 2 4 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        SidewalkHorizontalRailCrossing ->
            { texturePosition = Coord.xy 0 4 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            }

        SidewalkVerticalRailCrossing ->
            { texturePosition = Coord.xy 1 4 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
            }

        RailBottomToRight_SplitLeft ->
            { texturePosition = Coord.xy 3 17 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathHorizontal { offsetX = 1, offsetY = 0, length = 3 }
                    , secondary = RailPathBottomToRight
                    , texturePosition = Coord.xy 20 40
                    }
            }

        RailBottomToLeft_SplitUp ->
            { texturePosition = Coord.xy 7 17 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathVertical { offsetX = 3, offsetY = 1, length = 3 }
                    , secondary = RailPathBottomToLeft
                    , texturePosition = Coord.xy 24 40
                    }
            }

        RailTopToRight_SplitDown ->
            { texturePosition = Coord.xy 3 21 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathVertical { offsetX = 0, offsetY = 0, length = 3 }
                    , secondary = RailPathTopToRight
                    , texturePosition = Coord.xy 20 44
                    }
            }

        RailTopToLeft_SplitRight ->
            { texturePosition = Coord.xy 7 21 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathHorizontal { offsetX = 0, offsetY = 3, length = 3 }
                    , secondary = RailPathTopToLeft
                    , texturePosition = Coord.xy 24 44
                    }
            }

        RailBottomToRight_SplitUp ->
            { texturePosition = Coord.xy 3 25 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathVertical { offsetX = 0, offsetY = 1, length = 3 }
                    , secondary = RailPathBottomToRight
                    , texturePosition = Coord.xy 20 48
                    }
            }

        RailBottomToLeft_SplitRight ->
            { texturePosition = Coord.xy 7 25 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 }
                    , secondary = RailPathBottomToLeft
                    , texturePosition = Coord.xy 24 48
                    }
            }

        RailTopToRight_SplitLeft ->
            { texturePosition = Coord.xy 3 29 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathHorizontal { offsetX = 1, offsetY = 3, length = 3 }
                    , secondary = RailPathTopToRight
                    , texturePosition = Coord.xy 20 52
                    }
            }

        RailTopToLeft_SplitDown ->
            { texturePosition = Coord.xy 7 29 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
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
                RailSplitPath
                    { primary = RailPathVertical { offsetX = 3, offsetY = 0, length = 3 }
                    , secondary = RailPathTopToLeft
                    , texturePosition = Coord.xy 24 52
                    }
            }

        PostOffice ->
            { texturePosition = Coord.xy 0 38 |> Just
            , texturePositionTopLayer = Just { yOffset = -1, texturePosition = Coord.xy 0 33 }
            , size = Coord.xy 4 5
            , collisionMask = postOfficeCollision
            , railPath =
                SingleRailPath
                    (RailPathHorizontal { offsetX = 0, offsetY = 4, length = 4 })
            }

        MowedGrass1 ->
            { texturePosition = Coord.xy 11 20 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 1
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        MowedGrass4 ->
            { texturePosition = Coord.xy 11 20 |> Just
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 4 4
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        PineTree ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 24 }
            , size = Coord.xy 1 2
            , collisionMask = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
            , railPath = NoRailPath
            }

        LogCabinDown ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 26 }
            , size = Coord.xy 2 3
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        LogCabinRight ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 29 }
            , size = Coord.xy 2 3
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        LogCabinUp ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 32 }
            , size = Coord.xy 2 3
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        LogCabinLeft ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 11 35 }
            , size = Coord.xy 2 3
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                , ( 0, 2 )
                , ( 1, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        RoadHorizontal ->
            { texturePosition = Just (Coord.xy 15 21)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadVertical ->
            { texturePosition = Just (Coord.xy 14 30)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 1
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadBottomToLeft ->
            { texturePosition = Just (Coord.xy 16 24)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadTopToLeft ->
            { texturePosition = Just (Coord.xy 16 27)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadTopToRight ->
            { texturePosition = Just (Coord.xy 13 27)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadBottomToRight ->
            { texturePosition = Just (Coord.xy 13 24)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        Road4Way ->
            { texturePosition = Just (Coord.xy 16 21)
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 16 18 }
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadSidewalkCrossingHorizontal ->
            { texturePosition = Just (Coord.xy 15 18)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadSidewalkCrossingVertical ->
            { texturePosition = Just (Coord.xy 14 31)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 1
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        Road3WayDown ->
            { texturePosition = Just (Coord.xy 13 32)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        Road3WayLeft ->
            { texturePosition = Just (Coord.xy 16 32)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        Road3WayUp ->
            { texturePosition = Just (Coord.xy 16 35)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        Road3WayRight ->
            { texturePosition = Just (Coord.xy 13 35)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 3
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadRailCrossingHorizontal ->
            { texturePosition = Just (Coord.xy 19 27)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 1 3
            , collisionMask = DefaultCollision
            , railPath = RailPathVertical { offsetX = 0, offsetY = 0, length = 3 } |> SingleRailPath
            }

        RoadRailCrossingVertical ->
            { texturePosition = Just (Coord.xy 17 30)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 3 1
            , collisionMask = DefaultCollision
            , railPath = RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 } |> SingleRailPath
            }

        FenceHorizontal ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { texturePosition = Coord.xy 8 33, yOffset = 0 }
            , size = Coord.xy 2 1
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        FenceVertical ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { texturePosition = Coord.xy 10 33, yOffset = 0 }
            , size = Coord.xy 1 2
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        FenceDiagonal ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { texturePosition = Coord.xy 8 36, yOffset = 0 }
            , size = Coord.xy 2 2
            , collisionMask =
                [ ( 1, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        FenceAntidiagonal ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { texturePosition = Coord.xy 8 34, yOffset = 0 }
            , size = Coord.xy 2 2
            , collisionMask =
                [ ( 0, 0 )
                , ( 0, 1 )
                , ( 1, 1 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        RoadDeadendUp ->
            { texturePosition = Just (Coord.xy 10 38)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 5 4
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        RoadDeadendDown ->
            { texturePosition = Just (Coord.xy 15 38)
            , texturePositionTopLayer = Nothing
            , size = Coord.xy 5 4
            , collisionMask = DefaultCollision
            , railPath = NoRailPath
            }

        BusStopDown ->
            { texturePosition = Just (Coord.xy 12 42)
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 12 44 }
            , size = Coord.xy 2 2
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        BusStopLeft ->
            { texturePosition = Just (Coord.xy 14 42)
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 16 42 }
            , size = Coord.xy 1 3
            , collisionMask =
                [ ( 0, 1 )
                , ( 0, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        BusStopRight ->
            { texturePosition = Just (Coord.xy 14 42)
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 15 42 }
            , size = Coord.xy 1 3
            , collisionMask =
                [ ( 0, 1 )
                , ( 0, 2 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        BusStopUp ->
            { texturePosition = Just (Coord.xy 12 42)
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 12 46 }
            , size = Coord.xy 2 2
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }

        Hospital ->
            { texturePosition = Nothing
            , texturePositionTopLayer = Just { yOffset = 0, texturePosition = Coord.xy 14 46 }
            , size = Coord.xy 3 5
            , collisionMask =
                [ ( 0, 1 )
                , ( 1, 1 )
                ]
                    |> Set.fromList
                    |> CustomCollision
            , railPath = NoRailPath
            }


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
