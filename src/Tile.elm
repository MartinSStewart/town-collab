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
    , allTileGroupsExceptText
    , defaultPineTreeColor
    , defaultPostOfficeColor
    , defaultRockColor
    , defaultToPrimaryAndSecondary
    , getData
    , getTileGroupData
    , hasCollision
    , hasCollisionWithCoord
    , pathDirection
    , railDataReverse
    , railPathData
    , reverseDirection
    , texturePositionPixels
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
import Sprite
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
    | BigPineTreeGroup
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
    | StatueGroup
    | HedgeRowGroup
    | HedgeCornerGroup
    | HedgePillarGroup
    | ApartmentGroup
    | RockGroup
    | FlowersGroup
    | ElmTreeGroup
    | DirtPathGroup
    | BigTextGroup
    | HyperlinkGroup
    | BenchGroup
    | ParkingLotGroup
    | ParkingExitGroup
    | ParkingRoadGroup
    | ParkingRoundaboutGroup


allTileGroupsExceptText : List TileGroup
allTileGroupsExceptText =
    [ EmptyTileGroup
    , HouseGroup
    , LogCabinGroup
    , ApartmentGroup
    , HospitalGroup
    , PostOfficeGroup
    , StatueGroup
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
    , RoadStraightGroup
    , RoadTurnGroup
    , Road4WayGroup
    , RoadSidewalkCrossingGroup
    , Road3WayGroup
    , RoadRailCrossingGroup
    , RoadDeadendGroup
    , BusStopGroup
    , FenceStraightGroup
    , HedgeRowGroup
    , HedgeCornerGroup
    , HedgePillarGroup
    , PineTreeGroup
    , BigPineTreeGroup
    , RockGroup
    , FlowersGroup
    , ElmTreeGroup
    , DirtPathGroup
    , BenchGroup
    , ParkingLotGroup
    , ParkingExitGroup
    , ParkingRoadGroup
    , ParkingRoundaboutGroup
    ]


tileToTileGroup : Tile -> Maybe TileGroup
tileToTileGroup tile =
    List.find
        (\tileGroup ->
            getTileGroupData tileGroup |> .tiles |> List.Nonempty.any ((==) tile)
        )
        allTileGroupsExceptText


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

        BigTextGroup ->
            { defaultColors = OneDefaultColor Color.black
            , tiles = List.Nonempty.map BigText Sprite.asciiChars
            , name = "Text"
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
            { defaultColors = defaultPineTreeColor
            , tiles = Nonempty PineTree1 [ PineTree2 ]
            , name = "Pine tree"
            }

        BigPineTreeGroup ->
            { defaultColors = defaultPineTreeColor
            , tiles = Nonempty BigPineTree []
            , name = "Big pine tree"
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
            { defaultColors = defaultHospitalColor
            , tiles = Nonempty Hospital []
            , name = "Hospital"
            }

        StatueGroup ->
            { defaultColors = defaultStatueColor
            , tiles = Nonempty Statue []
            , name = "Statue"
            }

        HedgeRowGroup ->
            { defaultColors = defaultHedgeBushColor
            , tiles = Nonempty HedgeRowDown [ HedgeRowLeft, HedgeRowUp, HedgeRowRight ]
            , name = "Hedge row"
            }

        HedgeCornerGroup ->
            { defaultColors = defaultHedgeBushColor
            , tiles = Nonempty HedgeCornerDownLeft [ HedgeCornerUpLeft, HedgeCornerUpRight, HedgeCornerDownRight ]
            , name = "Hedge corner"
            }

        HedgePillarGroup ->
            { defaultColors = defaultHedgeBushColor
            , tiles = Nonempty HedgePillarDownLeft [ HedgePillarUpLeft, HedgePillarUpRight, HedgePillarDownRight ]
            , name = "Hedge pillar"
            }

        ApartmentGroup ->
            { defaultColors = defaultApartmentColor
            , tiles = Nonempty ApartmentDown [ ApartmentLeft, ApartmentUp, ApartmentRight ]
            , name = "Apartment"
            }

        RockGroup ->
            { defaultColors = defaultRockColor
            , tiles = Nonempty RockDown [ RockLeft, RockUp, RockRight ]
            , name = "Rock"
            }

        FlowersGroup ->
            { defaultColors = defaultFlowerColor
            , tiles = Nonempty Flowers1 [ Flowers2 ]
            , name = "Flowers"
            }

        ElmTreeGroup ->
            { defaultColors = defaultElmTreeColor
            , tiles = Nonempty ElmTree []
            , name = "Elm tree"
            }

        DirtPathGroup ->
            { defaultColors = defaultDirtPathColor
            , tiles = Nonempty DirtPathHorizontal [ DirtPathVertical ]
            , name = "Dirt path"
            }

        HyperlinkGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty Hyperlink []
            , name = "Hyperlink"
            }

        BenchGroup ->
            { defaultColors = defaultBenchColor
            , tiles = Nonempty BenchDown [ BenchLeft, BenchUp, BenchRight ]
            , name = "Bench"
            }

        ParkingLotGroup ->
            { defaultColors = OneDefaultColor (Color.rgb255 243 243 243)
            , tiles = Nonempty ParkingDown [ ParkingLeft, ParkingUp, ParkingRight ]
            , name = "Parking lot"
            }

        ParkingExitGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty ParkingExitDown [ ParkingExitLeft, ParkingExitUp, ParkingExitRight ]
            , name = "Parking exit"
            }

        ParkingRoadGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty ParkingRoad []
            , name = "Parking road"
            }

        ParkingRoundaboutGroup ->
            { defaultColors = defaultSidewalkColor
            , tiles = Nonempty ParkingRoundabout []
            , name = "Parking roundabout"
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
    | PineTree1
    | PineTree2
    | BigPineTree
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
    | Statue
    | HedgeRowDown
    | HedgeRowLeft
    | HedgeRowRight
    | HedgeRowUp
    | HedgeCornerDownLeft
    | HedgeCornerDownRight
    | HedgeCornerUpLeft
    | HedgeCornerUpRight
    | HedgePillarDownLeft
    | HedgePillarDownRight
    | HedgePillarUpLeft
    | HedgePillarUpRight
    | ApartmentDown
    | ApartmentLeft
    | ApartmentRight
    | ApartmentUp
    | RockDown
    | RockLeft
    | RockRight
    | RockUp
    | Flowers1
    | Flowers2
    | ElmTree
    | DirtPathHorizontal
    | DirtPathVertical
    | BigText Char
    | Hyperlink
    | BenchDown
    | BenchLeft
    | BenchUp
    | BenchRight
    | ParkingDown
    | ParkingLeft
    | ParkingUp
    | ParkingRight
    | ParkingExitDown
    | ParkingExitLeft
    | ParkingExitUp
    | ParkingExitRight
    | ParkingRoad
    | ParkingRoundabout


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
    , texturePositionTopLayer :
        Maybe
            { -- Used as a tie breaker if two tiles are at the same y position and overlapping
              yOffset : Float
            , texturePosition : Coord unit
            }
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
    tile == FenceHorizontal || tile == FenceVertical || tile == FenceDiagonal || tile == FenceAntidiagonal || tile == DirtPathHorizontal || tile == DirtPathVertical


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


defaultPineTreeColor : DefaultColor
defaultPineTreeColor =
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


defaultHospitalColor : DefaultColor
defaultHospitalColor =
    TwoDefaultColors { primaryColor = Color.rgb255 245 245 245, secondaryColor = Color.rgb255 163 224 223 }


defaultStatueColor : DefaultColor
defaultStatueColor =
    TwoDefaultColors { primaryColor = Color.rgb255 208 195 173, secondaryColor = Color.rgb255 171 129 128 }


defaultHedgeBushColor =
    OneDefaultColor (Color.rgb255 74 148 74)


defaultApartmentColor =
    TwoDefaultColors { primaryColor = Color.rgb255 127 53 53, secondaryColor = Color.rgb255 202 170 105 }


defaultRockColor =
    OneDefaultColor (Color.rgb255 160 160 160)


defaultFlowerColor =
    TwoDefaultColors { primaryColor = Color.rgb255 242 210 81, secondaryColor = Color.rgb255 242 146 0 }


defaultElmTreeColor =
    TwoDefaultColors { primaryColor = Color.rgb255 39 171 82, secondaryColor = Color.rgb255 141 96 65 }


defaultDirtPathColor =
    OneDefaultColor (Color.rgb255 192 146 117)


defaultBenchColor =
    OneDefaultColor (Color.rgb255 162 115 83)


getData : Tile -> TileData unit
getData tile =
    case tile of
        EmptyTile ->
            emptyTile

        HouseDown ->
            houseDown

        HouseRight ->
            houseRight

        HouseUp ->
            houseUp

        HouseLeft ->
            houseLeft

        RailHorizontal ->
            railHorizontal

        RailVertical ->
            railVertical

        RailBottomToRight ->
            railBottomToRight

        RailBottomToLeft ->
            railBottomToLeft

        RailTopToRight ->
            railTopToRight

        RailTopToLeft ->
            railTopToLeft

        RailBottomToRightLarge ->
            railBottomToRightLarge

        RailBottomToLeftLarge ->
            railBottomToLeftLarge

        RailTopToRightLarge ->
            railTopToRightLarge

        RailTopToLeftLarge ->
            railTopToLeftLarge

        RailCrossing ->
            railCrossing

        RailStrafeDown ->
            railStrafeDown

        RailStrafeUp ->
            railStrafeUp

        RailStrafeLeft ->
            railStrafeLeft

        RailStrafeRight ->
            railStrafeRight

        TrainHouseRight ->
            trainHouseRight

        TrainHouseLeft ->
            trainHouseLeft

        RailStrafeDownSmall ->
            railStrafeDownSmall

        RailStrafeUpSmall ->
            railStrafeUpSmall

        RailStrafeLeftSmall ->
            railStrafeLeftSmall

        RailStrafeRightSmall ->
            railStrafeRightSmall

        Sidewalk ->
            sidewalk

        SidewalkHorizontalRailCrossing ->
            sidewalkHorizontalRailCrossing

        SidewalkVerticalRailCrossing ->
            sidewalkVerticalRailCrossing

        RailBottomToRight_SplitLeft ->
            railBottomToRight_SplitLeft

        RailBottomToLeft_SplitUp ->
            railBottomToLeft_SplitUp

        RailTopToRight_SplitDown ->
            railTopToRight_SplitDown

        RailTopToLeft_SplitRight ->
            railTopToLeft_SplitRight

        RailBottomToRight_SplitUp ->
            railBottomToRight_SplitUp

        RailBottomToLeft_SplitRight ->
            railBottomToLeft_SplitRight

        RailTopToRight_SplitLeft ->
            railTopToRight_SplitLeft

        RailTopToLeft_SplitDown ->
            railTopToLeft_SplitDown

        PostOffice ->
            postOffice

        MowedGrass1 ->
            mowedGrass1

        MowedGrass4 ->
            mowedGrass4

        PineTree1 ->
            pineTree1

        PineTree2 ->
            pineTree2

        BigPineTree ->
            bigPineTree

        LogCabinDown ->
            logCabinDown

        LogCabinRight ->
            logCabinRight

        LogCabinUp ->
            logCabinUp

        LogCabinLeft ->
            logCabinLeft

        RoadHorizontal ->
            roadHorizontal

        RoadVertical ->
            roadVertical

        RoadBottomToLeft ->
            roadBottomToLeft

        RoadTopToLeft ->
            roadTopToLeft

        RoadTopToRight ->
            roadTopToRight

        RoadBottomToRight ->
            roadBottomToRight

        Road4Way ->
            road4Way

        RoadSidewalkCrossingHorizontal ->
            roadSidewalkCrossingHorizontal

        RoadSidewalkCrossingVertical ->
            roadSidewalkCrossingVertical

        Road3WayDown ->
            road3WayDown

        Road3WayLeft ->
            road3WayLeft

        Road3WayUp ->
            road3WayUp

        Road3WayRight ->
            road3WayRight

        RoadRailCrossingHorizontal ->
            roadRailCrossingHorizontal

        RoadRailCrossingVertical ->
            roadRailCrossingVertical

        FenceHorizontal ->
            fenceHorizontal

        FenceVertical ->
            fenceVertical

        FenceDiagonal ->
            fenceDiagonal

        FenceAntidiagonal ->
            fenceAntidiagonal

        RoadDeadendUp ->
            roadDeadendUp

        RoadDeadendDown ->
            roadDeadendDown

        BusStopDown ->
            busStopDown

        BusStopLeft ->
            busStopLeft

        BusStopRight ->
            busStopRight

        BusStopUp ->
            busStopUp

        Hospital ->
            hospital

        Statue ->
            statue

        HedgeRowDown ->
            hedgeRowDown

        HedgeRowLeft ->
            hedgeRowLeft

        HedgeRowRight ->
            hedgeRowRight

        HedgeRowUp ->
            hedgeRowUp

        HedgeCornerDownLeft ->
            hedgeCornerDownLeft

        HedgeCornerDownRight ->
            hedgeCornerDownRight

        HedgeCornerUpLeft ->
            hedgeCornerUpLeft

        HedgeCornerUpRight ->
            hedgeCornerUpRight

        HedgePillarDownLeft ->
            hedgePillarDownLeft

        HedgePillarDownRight ->
            hedgePillarDownRight

        HedgePillarUpLeft ->
            hedgePillarUpLeft

        HedgePillarUpRight ->
            hedgePillarUpRight

        ApartmentDown ->
            apartmentDown

        ApartmentLeft ->
            apartmentLeft

        ApartmentRight ->
            apartmentRight

        ApartmentUp ->
            apartmentUp

        RockDown ->
            rockDown

        RockLeft ->
            rockLeft

        RockRight ->
            rockRight

        RockUp ->
            rockUp

        Flowers1 ->
            flowers1

        Flowers2 ->
            flowers2

        ElmTree ->
            elmTree

        DirtPathHorizontal ->
            dirtPathHorizontal

        DirtPathVertical ->
            dirtPathVertical

        BigText char ->
            bigText char

        Hyperlink ->
            hyperlink

        BenchDown ->
            benchDown

        BenchLeft ->
            benchLeft

        BenchUp ->
            benchUp

        BenchRight ->
            benchRight

        ParkingDown ->
            parkingDown

        ParkingLeft ->
            parkingLeft

        ParkingUp ->
            parkingUp

        ParkingRight ->
            parkingRight

        ParkingExitDown ->
            parkingExitDown

        ParkingExitLeft ->
            parkingExitLeft

        ParkingExitUp ->
            parkingExitUp

        ParkingExitRight ->
            parkingExitRight

        ParkingRoad ->
            parkingRoad

        ParkingRoundabout ->
            parkingRoundabout


emptyTile =
    { texturePosition = Nothing
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


houseDown =
    { texturePosition = Coord.xy 0 1 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset HouseDown, texturePosition = Coord.xy 0 5 |> Coord.multiply Units.tileSize }
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


houseRight =
    { texturePosition = Coord.xy 11 4 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset HouseRight, texturePosition = Coord.xy 11 16 |> Coord.multiply Units.tileSize }
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


houseUp =
    { texturePosition = Coord.xy 15 12 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset HouseUp, texturePosition = Coord.xy 15 15 |> Coord.multiply Units.tileSize }
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


houseLeft =
    { texturePosition = Coord.xy 11 0 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset HouseLeft, texturePosition = Coord.xy 11 8 |> Coord.multiply Units.tileSize }
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


railHorizontal =
    { texturePosition = Coord.xy 0 0 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
    }


railVertical =
    { texturePosition = Coord.xy 1 0 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
    }


railBottomToRight =
    { texturePosition = Coord.xy 3 0 |> Coord.multiply Units.tileSize |> Just
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


railBottomToLeft =
    { texturePosition = Coord.xy 7 0 |> Coord.multiply Units.tileSize |> Just
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


railTopToRight =
    { texturePosition = Coord.xy 3 4 |> Coord.multiply Units.tileSize |> Just
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


railTopToLeft =
    { texturePosition = Coord.xy 7 4 |> Coord.multiply Units.tileSize |> Just
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


railBottomToRightLarge =
    { texturePosition = Coord.xy 0 43 |> Coord.multiply Units.tileSize |> Just
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


railBottomToLeftLarge =
    { texturePosition = Coord.xy 6 43 |> Coord.multiply Units.tileSize |> Just
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


railTopToRightLarge =
    { texturePosition = Coord.xy 0 49 |> Coord.multiply Units.tileSize |> Just
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


railTopToLeftLarge =
    { texturePosition = Coord.xy 6 49 |> Coord.multiply Units.tileSize |> Just
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


railCrossing =
    { texturePosition = Coord.xy 2 0 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath =
        DoubleRailPath
            (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
    }


railStrafeDown =
    { texturePosition = Coord.xy 0 8 |> Coord.multiply Units.tileSize |> Just
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


railStrafeUp =
    { texturePosition = Coord.xy 5 8 |> Coord.multiply Units.tileSize |> Just
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


railStrafeLeft =
    { texturePosition = Coord.xy 0 11 |> Coord.multiply Units.tileSize |> Just
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


railStrafeRight =
    { texturePosition = Coord.xy 0 16 |> Coord.multiply Units.tileSize |> Just
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


trainHouseRight =
    { texturePosition = Coord.xy 3 11 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset TrainHouseRight, texturePosition = Coord.xy 13 8 |> Coord.multiply Units.tileSize }
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


trainHouseLeft =
    { texturePosition = Coord.xy 7 11 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset TrainHouseLeft, texturePosition = Coord.xy 17 8 |> Coord.multiply Units.tileSize }
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


railStrafeDownSmall =
    { texturePosition = Coord.xy 3 15 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 4 2
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeDownSmall
    }


railStrafeUpSmall =
    { texturePosition = Coord.xy 7 15 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 4 2
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeUpSmall
    }


railStrafeLeftSmall =
    { texturePosition = Coord.xy 0 21 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 2 4
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeLeftSmall
    }


railStrafeRightSmall =
    { texturePosition = Coord.xy 0 25 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 2 4
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeRightSmall
    }


sidewalk =
    { texturePosition = Coord.xy 2 4 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


sidewalkHorizontalRailCrossing =
    { texturePosition = Coord.xy 0 4 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
    }


sidewalkVerticalRailCrossing =
    { texturePosition = Coord.xy 1 4 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
    }


railBottomToRight_SplitLeft =
    { texturePosition = Coord.xy 3 17 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 20 40 |> Coord.multiply Units.tileSize
            }
    }


railBottomToLeft_SplitUp =
    { texturePosition = Coord.xy 7 17 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 24 40 |> Coord.multiply Units.tileSize
            }
    }


railTopToRight_SplitDown =
    { texturePosition = Coord.xy 3 21 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 20 44 |> Coord.multiply Units.tileSize
            }
    }


railTopToLeft_SplitRight =
    { texturePosition = Coord.xy 7 21 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 24 44 |> Coord.multiply Units.tileSize
            }
    }


railBottomToRight_SplitUp =
    { texturePosition = Coord.xy 3 25 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 20 48 |> Coord.multiply Units.tileSize
            }
    }


railBottomToLeft_SplitRight =
    { texturePosition = Coord.xy 7 25 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 24 48 |> Coord.multiply Units.tileSize
            }
    }


railTopToRight_SplitLeft =
    { texturePosition = Coord.xy 3 29 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 20 52 |> Coord.multiply Units.tileSize
            }
    }


railTopToLeft_SplitDown =
    { texturePosition = Coord.xy 7 29 |> Coord.multiply Units.tileSize |> Just
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
            , texturePosition = Coord.xy 24 52 |> Coord.multiply Units.tileSize
            }
    }


postOffice =
    { texturePosition = Coord.xy 0 38 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Just { yOffset = yOffset PostOffice, texturePosition = Coord.xy 0 33 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 4 5
    , collisionMask = postOfficeCollision
    , railPath =
        SingleRailPath
            (RailPathHorizontal { offsetX = 0, offsetY = 4, length = 4 })
    }


mowedGrass1 =
    { texturePosition = Coord.xy 11 20 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


mowedGrass4 =
    { texturePosition = Coord.xy 11 20 |> Coord.multiply Units.tileSize |> Just
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 4 4
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


pineTree1 =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset PineTree1, texturePosition = Coord.xy 11 24 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 2
    , collisionMask = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
    , railPath = NoRailPath
    }


pineTree2 =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset PineTree1, texturePosition = Coord.xy 12 24 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 2
    , collisionMask = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
    , railPath = NoRailPath
    }


bigPineTree : TileData units
bigPineTree =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset BigPineTree, texturePosition = Coord.xy 640 756 }
    , size = Coord.xy 3 3
    , collisionMask = Set.fromList [ ( 1, 2 ) ] |> CustomCollision
    , railPath = NoRailPath
    }


logCabinDown =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset LogCabinDown, texturePosition = Coord.xy 11 26 |> Coord.multiply Units.tileSize }
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


logCabinRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset LogCabinRight, texturePosition = Coord.xy 11 29 |> Coord.multiply Units.tileSize }
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


logCabinUp =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset LogCabinUp, texturePosition = Coord.xy 11 32 |> Coord.multiply Units.tileSize }
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


logCabinLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset LogCabinLeft, texturePosition = Coord.xy 11 35 |> Coord.multiply Units.tileSize }
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


roadHorizontal =
    { texturePosition = Just (Coord.xy 15 21 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadVertical =
    { texturePosition = Just (Coord.xy 14 30 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadBottomToLeft =
    { texturePosition = Just (Coord.xy 16 24 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadTopToLeft =
    { texturePosition = Just (Coord.xy 16 27 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadTopToRight =
    { texturePosition = Just (Coord.xy 13 27 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadBottomToRight =
    { texturePosition = Just (Coord.xy 13 24 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


road4Way =
    { texturePosition = Just (Coord.xy 16 21 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Just { yOffset = yOffset Road4Way, texturePosition = Coord.xy 16 18 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadSidewalkCrossingHorizontal =
    { texturePosition = Just (Coord.xy 15 18 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadSidewalkCrossingVertical =
    { texturePosition = Just (Coord.xy 14 31 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


road3WayDown =
    { texturePosition = Just (Coord.xy 13 32 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


road3WayLeft =
    { texturePosition = Just (Coord.xy 16 32 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


road3WayUp =
    { texturePosition = Just (Coord.xy 16 35 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


road3WayRight =
    { texturePosition = Just (Coord.xy 13 35 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadRailCrossingHorizontal =
    { texturePosition = Just (Coord.xy 19 27 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 3
    , collisionMask = DefaultCollision
    , railPath = RailPathVertical { offsetX = 0, offsetY = 0, length = 3 } |> SingleRailPath
    }


roadRailCrossingVertical =
    { texturePosition = Just (Coord.xy 17 30 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 1
    , collisionMask = DefaultCollision
    , railPath = RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 } |> SingleRailPath
    }


fenceHorizontal =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { texturePosition = Coord.xy 8 33 |> Coord.multiply Units.tileSize, yOffset = yOffset FenceHorizontal }
    , size = Coord.xy 2 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


fenceVertical =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { texturePosition = Coord.xy 10 33 |> Coord.multiply Units.tileSize, yOffset = yOffset FenceVertical }
    , size = Coord.xy 1 2
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


fenceDiagonal =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { texturePosition = Coord.xy 8 36 |> Coord.multiply Units.tileSize, yOffset = yOffset FenceDiagonal }
    , size = Coord.xy 2 2
    , collisionMask =
        [ ( 1, 0 )
        , ( 0, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


fenceAntidiagonal =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { texturePosition = Coord.xy 8 34 |> Coord.multiply Units.tileSize, yOffset = yOffset FenceAntidiagonal }
    , size = Coord.xy 2 2
    , collisionMask =
        [ ( 0, 0 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


roadDeadendUp =
    { texturePosition = Just (Coord.xy 10 38 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 5 4
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


roadDeadendDown =
    { texturePosition = Just (Coord.xy 15 38 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 5 4
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


busStopDown =
    { texturePosition = Just (Coord.xy 12 42 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Just { yOffset = yOffset BusStopDown, texturePosition = Coord.xy 12 44 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 2 2
    , collisionMask =
        [ ( 0, 1 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


busStopLeft =
    { texturePosition = Just (Coord.xy 14 42 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Just { yOffset = yOffset BusStopLeft, texturePosition = Coord.xy 16 42 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 3
    , collisionMask =
        [ ( 0, 1 )
        , ( 0, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


busStopRight =
    { texturePosition = Just (Coord.xy 14 42 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Just { yOffset = yOffset BusStopRight, texturePosition = Coord.xy 15 42 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 3
    , collisionMask =
        [ ( 0, 1 )
        , ( 0, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


busStopUp =
    { texturePosition = Just (Coord.xy 12 42 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Just { yOffset = yOffset BusStopUp, texturePosition = Coord.xy 12 46 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 2 2
    , collisionMask =
        [ ( 0, 1 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hospital =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset Hospital, texturePosition = Coord.xy 14 46 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 5
    , collisionMask =
        [ ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 2 )
        , ( 0, 3 )
        , ( 1, 3 )
        , ( 2, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        , ( 2, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


statue =
    { texturePosition = Just (Coord.xy 12 50 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Just { yOffset = yOffset Statue, texturePosition = Coord.xy 17 43 |> Coord.multiply Units.tileSize }
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


hedgeRowDown =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeRowDown, texturePosition = Coord.xy 17 46 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeRowLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeRowLeft, texturePosition = Coord.xy 17 48 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeRowRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeRowRight, texturePosition = Coord.xy 17 50 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeRowUp =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeRowUp, texturePosition = Coord.xy 17 52 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeCornerDownLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeCornerDownLeft, texturePosition = Coord.xy 14 54 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeCornerDownRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeCornerDownRight, texturePosition = Coord.xy 17 54 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeCornerUpLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeCornerUpLeft, texturePosition = Coord.xy 7 41 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgeCornerUpRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgeCornerUpRight, texturePosition = Coord.xy 14 52 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgePillarDownLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgePillarDownLeft, texturePosition = Coord.xy 28 52 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgePillarDownRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgePillarDownRight, texturePosition = Coord.xy 28 54 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgePillarUpLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgePillarUpLeft, texturePosition = Coord.xy 31 52 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


hedgePillarUpRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset HedgePillarUpRight, texturePosition = Coord.xy 31 54 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


apartmentDown =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset ApartmentDown, texturePosition = Coord.xy 28 40 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 2 5
    , collisionMask =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


apartmentLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset ApartmentLeft, texturePosition = Coord.xy 30 45 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 2 5
    , collisionMask =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


apartmentRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset ApartmentRight, texturePosition = Coord.xy 28 45 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 2 5
    , collisionMask =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


apartmentUp =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset ApartmentUp, texturePosition = Coord.xy 30 40 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 2 5
    , collisionMask =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


rockDown =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset RockDown, texturePosition = Coord.xy 12 48 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


rockLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset RockLeft, texturePosition = Coord.xy 13 48 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


rockRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset RockRight, texturePosition = Coord.xy 12 49 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


rockUp =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset RockUp, texturePosition = Coord.xy 13 49 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


flowers1 =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset Flowers1, texturePosition = Coord.xy 28 50 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


flowers2 =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset Flowers2, texturePosition = Coord.xy 31 50 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 2
    , collisionMask =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


elmTree =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset ElmTree, texturePosition = Coord.xy 32 47 |> Coord.multiply Units.tileSize }
    , size = Coord.xy 3 3
    , collisionMask =
        [ ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


dirtPathHorizontal =
    { texturePosition = Just (Coord.xy 34 50 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 2 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


dirtPathVertical =
    { texturePosition = Just (Coord.xy 34 51 |> Coord.multiply Units.tileSize)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 2
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


bigText : Char -> TileData unit
bigText char =
    { texturePosition = Just (Sprite.charTexturePosition char)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 2
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


hyperlink : TileData unit
hyperlink =
    { texturePosition = Just (Coord.xy 700 918)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 2
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


benchDown : TileData unit
benchDown =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset BenchDown, texturePosition = Coord.xy 640 738 }
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


benchLeft : TileData unit
benchLeft =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset BenchDown, texturePosition = Coord.xy 660 720 }
    , size = Coord.xy 1 2
    , collisionMask = [ ( 0, 1 ) ] |> Set.fromList |> CustomCollision
    , railPath = NoRailPath
    }


benchRight : TileData unit
benchRight =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset BenchDown, texturePosition = Coord.xy 680 720 }
    , size = Coord.xy 1 2
    , collisionMask = [ ( 0, 1 ) ] |> Set.fromList |> CustomCollision
    , railPath = NoRailPath
    }


benchUp : TileData unit
benchUp =
    { texturePosition = Nothing
    , texturePositionTopLayer = Just { yOffset = yOffset BenchDown, texturePosition = Coord.xy 700 738 }
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingDown : TileData unit
parkingDown =
    { texturePosition = Just (Coord.xy 640 666)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingLeft : TileData unit
parkingLeft =
    { texturePosition = Just (Coord.xy 700 720)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingRight : TileData unit
parkingRight =
    { texturePosition = Just (Coord.xy 640 720)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingUp : TileData unit
parkingUp =
    { texturePosition = Just (Coord.xy 640 702)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingExitDown : TileData unit
parkingExitDown =
    { texturePosition = Just (Coord.xy 660 702)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingExitLeft : TileData unit
parkingExitLeft =
    { texturePosition = Just (Coord.xy 740 648)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingExitRight : TileData unit
parkingExitRight =
    { texturePosition = Just (Coord.xy 720 648)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 3
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingExitUp : TileData unit
parkingExitUp =
    { texturePosition = Just (Coord.xy 660 630)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingRoad : TileData unit
parkingRoad =
    { texturePosition = Just (Coord.xy 640 684)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 1 1
    , collisionMask = DefaultCollision
    , railPath = NoRailPath
    }


parkingRoundabout : TileData unit
parkingRoundabout =
    { texturePosition = Just (Coord.xy 660 648)
    , texturePositionTopLayer = Nothing
    , size = Coord.xy 3 3
    , collisionMask =
        [ ( 0, 0 )
        , ( 1, 0 )
        , ( 2, 0 )
        , ( 0, 1 )
        , ( 2, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    }


yOffset : Tile -> Float
yOffset tile =
    case List.elemIndex tile zOrderBackToFront of
        Just index ->
            toFloat index / toFloat tileCount

        Nothing ->
            0


tileCount : Int
tileCount =
    List.length zOrderBackToFront


zOrderBackToFront : List Tile
zOrderBackToFront =
    [ PostOffice
    , FenceHorizontal
    , FenceVertical
    , FenceDiagonal
    , FenceAntidiagonal
    , EmptyTile
    , HouseDown
    , HouseRight
    , HouseUp
    , HouseLeft
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
    , RailStrafeDown
    , RailStrafeUp
    , RailStrafeLeft
    , RailStrafeRight
    , TrainHouseRight
    , TrainHouseLeft
    , RailStrafeDownSmall
    , RailStrafeUpSmall
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
    , MowedGrass1
    , MowedGrass4
    , PineTree1
    , PineTree2
    , LogCabinDown
    , LogCabinRight
    , LogCabinUp
    , LogCabinLeft
    , RoadHorizontal
    , RoadVertical
    , RoadBottomToLeft
    , RoadTopToLeft
    , RoadTopToRight
    , RoadBottomToRight
    , Road4Way
    , RoadSidewalkCrossingHorizontal
    , RoadSidewalkCrossingVertical
    , Road3WayDown
    , Road3WayLeft
    , Road3WayUp
    , Road3WayRight
    , RoadRailCrossingHorizontal
    , RoadRailCrossingVertical
    , RoadDeadendUp
    , RoadDeadendDown
    , BusStopDown
    , BusStopLeft
    , BusStopRight
    , BusStopUp
    , Statue
    , Flowers1
    , Flowers2
    , ApartmentDown
    , ApartmentLeft
    , ApartmentRight
    , ApartmentUp
    , HedgeRowDown
    , HedgeRowLeft
    , HedgeRowRight
    , HedgeRowUp
    , HedgeCornerDownLeft
    , HedgeCornerDownRight
    , HedgeCornerUpLeft
    , HedgeCornerUpRight
    , HedgePillarDownLeft
    , HedgePillarDownRight
    , HedgePillarUpLeft
    , HedgePillarUpRight
    , RockDown
    , RockLeft
    , RockRight
    , RockUp
    , BigPineTree
    , ElmTree
    , Hospital
    ]


postOfficeCollision : CollisionMask
postOfficeCollision =
    collisionRectangle 0 1 4 4


collisionRectangle x y width height =
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
