module Tile exposing
    ( Category(..)
    , CollisionMask(..)
    , DefaultColor(..)
    , Direction(..)
    , RailData
    , RailPath(..)
    , RailPathType(..)
    , Tile(..)
    , TileData
    , TileGroup(..)
    , allCategories
    , allTileGroupsExceptText
    , buildingCategory
    , categoryToString
    , codec
    , defaultPineTreeColor
    , defaultPostOfficeColor
    , defaultRockColor
    , defaultToPrimaryAndSecondary
    , getData
    , getTileGroupData
    , hasCollision
    , hasCollisionWithCoord
    , pathDirection
    , railCategory
    , railDataReverse
    , railPathData
    , reverseDirection
    , roadCategory
    , sceneryCategory
    , texturePositionPixels
    , tileToTileGroup
    , trainHouseLeftRailPath
    , trainHouseRightRailPath
    )

import Angle
import Axis2d
import BoundingBox2d exposing (BoundingBox2d)
import Bounds exposing (Bounds)
import Codec exposing (Codec)
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Sprite
import String.Nonempty exposing (NonemptyString(..))
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
    | ParkingRoadGroup
    | ParkingRoundaboutGroup
    | CornerHouseGroup
    | DogHouseGroup
    | MushroomGroup
    | TreeStumpGroup
    | SunflowersGroup
    | RailDeadendGroup
    | RailStrafeSplitGroup
    | RailStrafeSplitMirrorGroup
    | RoadStraightManholeGroup


codec : Codec TileGroup
codec =
    Codec.enum
        Codec.string
        [ ( "EmptyTile", EmptyTileGroup )
        , ( "House", HouseGroup )
        , ( "RailStraight", RailStraightGroup )
        , ( "RailTurn", RailTurnGroup )
        , ( "RailTurnLarge", RailTurnLargeGroup )
        , ( "RailStrafe", RailStrafeGroup )
        , ( "RailStrafeSmall", RailStrafeSmallGroup )
        , ( "RailCrossing", RailCrossingGroup )
        , ( "TrainHouse", TrainHouseGroup )
        , ( "Sidewalk", SidewalkGroup )
        , ( "SidewalkRail", SidewalkRailGroup )
        , ( "RailTurnSplit", RailTurnSplitGroup )
        , ( "RailTurnSplitMirror", RailTurnSplitMirrorGroup )
        , ( "PostOffice", PostOfficeGroup )
        , ( "PineTree", PineTreeGroup )
        , ( "BigPineTree", BigPineTreeGroup )
        , ( "LogCabin", LogCabinGroup )
        , ( "RoadStraight", RoadStraightGroup )
        , ( "RoadTurn", RoadTurnGroup )
        , ( "Road4Way", Road4WayGroup )
        , ( "RoadSidewalkCrossing", RoadSidewalkCrossingGroup )
        , ( "Road3Way", Road3WayGroup )
        , ( "RoadRailCrossing", RoadRailCrossingGroup )
        , ( "RoadDeadend", RoadDeadendGroup )
        , ( "FenceStraight", FenceStraightGroup )
        , ( "BusStop", BusStopGroup )
        , ( "Hospital", HospitalGroup )
        , ( "Statue", StatueGroup )
        , ( "HedgeRow", HedgeRowGroup )
        , ( "HedgeCorner", HedgeCornerGroup )
        , ( "HedgePillar", HedgePillarGroup )
        , ( "Apartment", ApartmentGroup )
        , ( "Rock", RockGroup )
        , ( "Flowers", FlowersGroup )
        , ( "ElmTree", ElmTreeGroup )
        , ( "DirtPath", DirtPathGroup )
        , ( "BigText", BigTextGroup )
        , ( "Hyperlink", HyperlinkGroup )
        , ( "Bench", BenchGroup )
        , ( "ParkingLot", ParkingLotGroup )
        , ( "ParkingRoad", ParkingRoadGroup )
        , ( "ParkingRoundabout", ParkingRoundaboutGroup )
        , ( "CornerHouse", CornerHouseGroup )
        , ( "DogHouse", DogHouseGroup )
        , ( "Mushroom", MushroomGroup )
        , ( "TreeStump", TreeStumpGroup )
        , ( "Sunflowers", SunflowersGroup )
        , ( "RailDeadend", RailDeadendGroup )
        , ( "RailStrafeSplit", RailStrafeSplitGroup )
        , ( "RailStrafeSplitMirror", RailStrafeSplitMirrorGroup )
        , ( "RoadManhole", RoadStraightManholeGroup )
        ]


allTileGroupsExceptText : List TileGroup
allTileGroupsExceptText =
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
    , BigPineTreeGroup
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
    , StatueGroup
    , HedgeRowGroup
    , HedgeCornerGroup
    , HedgePillarGroup
    , ApartmentGroup
    , RockGroup
    , FlowersGroup
    , ElmTreeGroup
    , DirtPathGroup
    , HyperlinkGroup
    , BenchGroup
    , ParkingLotGroup
    , ParkingRoadGroup
    , ParkingRoundaboutGroup
    , CornerHouseGroup
    ]


categoryToString : Category -> NonemptyString
categoryToString category =
    case category of
        Buildings ->
            NonemptyString 'b' "uildings"

        Scenery ->
            NonemptyString 's' "cenery"

        Rail ->
            NonemptyString 't' "rains"

        Road ->
            NonemptyString 'r' "oads"


type Category
    = Scenery
    | Buildings
    | Rail
    | Road


allCategories : List Category
allCategories =
    [ Scenery
    , Buildings
    , Rail
    , Road
    ]


sceneryCategory : List TileGroup
sceneryCategory =
    [ PineTreeGroup
    , BigPineTreeGroup
    , TreeStumpGroup
    , FenceStraightGroup
    , StatueGroup
    , HedgeRowGroup
    , HedgeCornerGroup
    , HedgePillarGroup
    , RockGroup
    , FlowersGroup
    , SunflowersGroup
    , ElmTreeGroup
    , DirtPathGroup
    , SidewalkGroup
    , BenchGroup
    , DogHouseGroup
    , MushroomGroup
    ]


buildingCategory : List TileGroup
buildingCategory =
    [ HouseGroup
    , TrainHouseGroup
    , PostOfficeGroup
    , LogCabinGroup
    , BusStopGroup
    , HospitalGroup
    , ApartmentGroup
    , CornerHouseGroup
    , DogHouseGroup
    ]


railCategory : List TileGroup
railCategory =
    [ RailStraightGroup
    , RailTurnGroup
    , RailTurnLargeGroup
    , RailStrafeGroup
    , RailStrafeSmallGroup
    , RailCrossingGroup
    , TrainHouseGroup
    , SidewalkRailGroup
    , RailTurnSplitGroup
    , RailTurnSplitMirrorGroup
    , PostOfficeGroup
    , RoadRailCrossingGroup
    , RailDeadendGroup
    , RailStrafeSplitGroup
    , RailStrafeSplitMirrorGroup
    ]


roadCategory : List TileGroup
roadCategory =
    [ SidewalkGroup
    , RoadStraightGroup
    , RoadStraightManholeGroup
    , RoadTurnGroup
    , Road4WayGroup
    , RoadSidewalkCrossingGroup
    , Road3WayGroup
    , RoadRailCrossingGroup
    , RoadDeadendGroup
    , ParkingLotGroup
    , ParkingRoadGroup
    , ParkingRoundaboutGroup
    ]


tileToTileGroup : Tile -> Maybe { tileGroup : TileGroup, index : Int }
tileToTileGroup tile =
    List.findMap
        (\tileGroup ->
            case getTileGroupData tileGroup |> .tiles |> List.Nonempty.toList |> List.findIndex ((==) tile) of
                Just index ->
                    Just { tileGroup = tileGroup, index = index }

                Nothing ->
                    Nothing
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

        ParkingRoadGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles = Nonempty ParkingRoad []
            , name = "Parking road"
            }

        ParkingRoundaboutGroup ->
            { defaultColors = defaultSidewalkColor
            , tiles = Nonempty ParkingRoundabout []
            , name = "Parking circle"
            }

        CornerHouseGroup ->
            { defaultColors = defaultCornerHouseColor
            , tiles = Nonempty CornerHouseUpLeft [ CornerHouseUpRight, CornerHouseDownRight, CornerHouseDownLeft ]
            , name = "Corner house"
            }

        DogHouseGroup ->
            { defaultColors = defaultLogCabinColor
            , tiles = Nonempty DogHouseDown [ DogHouseLeft, DogHouseUp, DogHouseRight ]
            , name = "Dog house"
            }

        MushroomGroup ->
            { defaultColors = defaultMushroomColor
            , tiles = Nonempty Mushroom []
            , name = "Mushroom"
            }

        TreeStumpGroup ->
            { defaultColors = defaultTreeStumpColor
            , tiles = Nonempty TreeStump1 [ TreeStump2 ]
            , name = "Tree stump"
            }

        SunflowersGroup ->
            { defaultColors = defaultSunflowerColor
            , tiles = Nonempty Sunflowers []
            , name = "Mushroom"
            }

        RailDeadendGroup ->
            { defaultColors = defaultRailDeadEndColor
            , tiles = Nonempty RailDeadEndLeft [ RailDeadEndRight ]
            , name = "Rail dead end"
            }

        RailStrafeSplitGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles =
                Nonempty
                    RailStrafeLeftToRight_SplitUp
                    [ RailStrafeTopToBottom_SplitLeft
                    , RailStrafeRightToLeft_SplitDown
                    , RailStrafeBottomToTop_SplitLeft
                    ]
            , name = "Rail split strafe L."
            }

        RailStrafeSplitMirrorGroup ->
            { defaultColors = ZeroDefaultColors
            , tiles =
                Nonempty
                    RailStrafeLeftToRight_SplitDown
                    [ RailStrafeTopToBottom_SplitRight
                    , RailStrafeRightToLeft_SplitUp
                    , RailStrafeBottomToTop_SplitRight
                    ]
            , name = "Rail split strafe R."
            }

        RoadStraightManholeGroup ->
            { defaultColors = defaultRoadColor
            , tiles = Nonempty RoadManholeDown [ RoadManholeLeft, RoadManholeUp, RoadManholeRight ]
            , name = "Manhole road"
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
    | ParkingRoad
    | ParkingRoundabout
    | CornerHouseUpLeft
    | CornerHouseUpRight
    | CornerHouseDownLeft
    | CornerHouseDownRight
    | DogHouseDown
    | DogHouseRight
    | DogHouseUp
    | DogHouseLeft
    | Mushroom
    | TreeStump1
    | TreeStump2
    | Sunflowers
    | RailDeadEndLeft
    | RailDeadEndRight
    | RailStrafeLeftToRight_SplitUp
    | RailStrafeLeftToRight_SplitDown
    | RailStrafeRightToLeft_SplitUp
    | RailStrafeRightToLeft_SplitDown
    | RailStrafeTopToBottom_SplitLeft
    | RailStrafeTopToBottom_SplitRight
    | RailStrafeBottomToTop_SplitLeft
    | RailStrafeBottomToTop_SplitRight
    | RoadManholeDown
    | RoadManholeLeft
    | RoadManholeUp
    | RoadManholeRight


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


texturePositionPixels : Coord b -> Coord b -> { topLeft : Float, topRight : Float, bottomLeft : Float, bottomRight : Float }
texturePositionPixels position textureSize =
    let
        ( x, y ) =
            Coord.toTuple position

        ( w, h ) =
            Coord.toTuple textureSize
    in
    { topLeft = toFloat x + Sprite.textureWidth * toFloat y
    , topRight = toFloat (x + w) + Sprite.textureWidth * toFloat y
    , bottomRight = toFloat (x + w) + Sprite.textureWidth * toFloat (y + h)
    , bottomLeft = toFloat x + Sprite.textureWidth * toFloat (y + h)
    }


type alias TileData unit =
    { texturePosition : Coord unit
    , size : Coord unit
    , tileCollision : CollisionMask
    , railPath : RailPathType
    , movementCollision : List (Bounds unit)
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
        case ( tileDataA.tileCollision, tileDataB.tileCollision ) of
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
    case tileB.tileCollision of
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


defaultTreeStumpColor : DefaultColor
defaultTreeStumpColor =
    OneDefaultColor (Color.rgb255 141 96 65)


defaultRailDeadEndColor : DefaultColor
defaultRailDeadEndColor =
    TwoDefaultColors { primaryColor = Color.rgb255 217 209 40, secondaryColor = Color.rgb255 217 139 40 }


defaultSunflowerColor : DefaultColor
defaultSunflowerColor =
    TwoDefaultColors { primaryColor = Color.rgb255 255 224 36, secondaryColor = Color.rgb255 77 185 91 }


defaultMushroomColor : DefaultColor
defaultMushroomColor =
    TwoDefaultColors { primaryColor = Color.rgb255 211 39 39, secondaryColor = Color.rgb255 238 238 238 }


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


defaultCornerHouseColor =
    TwoDefaultColors { primaryColor = Color.rgb255 101 108 124, secondaryColor = Color.rgb255 103 157 236 }


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

        ParkingRoad ->
            parkingRoad

        ParkingRoundabout ->
            parkingRoundabout

        CornerHouseUpLeft ->
            cornerHouseUpLeft

        CornerHouseUpRight ->
            cornerHouseUpRight

        CornerHouseDownLeft ->
            cornerHouseDownLeft

        CornerHouseDownRight ->
            cornerHouseDownRight

        DogHouseDown ->
            dogHouseDown

        DogHouseRight ->
            dogHouseRight

        DogHouseUp ->
            dogHouseUp

        DogHouseLeft ->
            dogHouseLeft

        Mushroom ->
            mushroom

        TreeStump1 ->
            treeStump1

        TreeStump2 ->
            treeStump2

        Sunflowers ->
            sunflowers

        RailDeadEndLeft ->
            railDeadEndLeft

        RailDeadEndRight ->
            railDeadEndRight

        RailStrafeLeftToRight_SplitUp ->
            railStrafeLeftToRight_SplitUp

        RailStrafeLeftToRight_SplitDown ->
            railStrafeLeftToRight_SplitDown

        RailStrafeRightToLeft_SplitUp ->
            railStrafeRightToLeft_SplitUp

        RailStrafeRightToLeft_SplitDown ->
            railStrafeRightToLeft_SplitDown

        RailStrafeTopToBottom_SplitLeft ->
            railStrafeTopToBottom_SplitLeft

        RailStrafeTopToBottom_SplitRight ->
            railStrafeTopToBottom_SplitRight

        RailStrafeBottomToTop_SplitLeft ->
            railStrafeBottomToTop_SplitLeft

        RailStrafeBottomToTop_SplitRight ->
            railStrafeBottomToTop_SplitRight

        RoadManholeDown ->
            roadManholeDown

        RoadManholeLeft ->
            roadManholeLeft

        RoadManholeUp ->
            roadManholeUp

        RoadManholeRight ->
            roadManholeRight


emptyTile : TileData units
emptyTile =
    { texturePosition = Coord.xy 120 738
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


houseDown : TileData units
houseDown =
    { texturePosition = Coord.xy 0 5 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision =
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 7 6) (Coord.xy 48 24) ]
    }


houseRight : TileData units
houseRight =
    { texturePosition = Coord.xy 11 16 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 4
    , tileCollision =
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 3 5) (Coord.xy 27 46) ]
    }


houseUp : TileData units
houseUp =
    { texturePosition = Coord.xy 15 15 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision =
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 6) (Coord.xy 48 27) ]
    }


houseLeft : TileData units
houseLeft =
    { texturePosition = Coord.xy 11 8 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 4
    , tileCollision =
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 10 5) (Coord.xy 27 46) ]
    }


railHorizontal : TileData units
railHorizontal =
    { texturePosition = Coord.xy 0 0 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
    , movementCollision = []
    }


railVertical : TileData units
railVertical =
    { texturePosition = Coord.xy 1 0 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
    , movementCollision = []
    }


railBottomToRight : TileData units
railBottomToRight =
    { texturePosition = Coord.xy 3 0 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railBottomToLeft : TileData units
railBottomToLeft =
    { texturePosition = Coord.xy 7 0 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railTopToRight : TileData units
railTopToRight =
    { texturePosition = Coord.xy 3 4 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railTopToLeft : TileData units
railTopToLeft =
    { texturePosition = Coord.xy 7 4 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railBottomToRightLarge : TileData units
railBottomToRightLarge =
    { texturePosition = Coord.xy 0 43 |> Coord.multiply Units.tileSize
    , size = Coord.xy 6 6
    , tileCollision =
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
    , movementCollision = []
    }


railBottomToLeftLarge : TileData units
railBottomToLeftLarge =
    { texturePosition = Coord.xy 6 43 |> Coord.multiply Units.tileSize
    , size = Coord.xy 6 6
    , tileCollision =
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
    , movementCollision = []
    }


railTopToRightLarge : TileData units
railTopToRightLarge =
    { texturePosition = Coord.xy 0 49 |> Coord.multiply Units.tileSize
    , size = Coord.xy 6 6
    , tileCollision =
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
    , movementCollision = []
    }


railTopToLeftLarge : TileData units
railTopToLeftLarge =
    { texturePosition = Coord.xy 6 49 |> Coord.multiply Units.tileSize
    , size = Coord.xy 6 6
    , tileCollision =
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
    , movementCollision = []
    }


railCrossing : TileData units
railCrossing =
    { texturePosition = Coord.xy 2 0 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath =
        DoubleRailPath
            (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
            (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
    , movementCollision = []
    }


railStrafeDown : TileData units
railStrafeDown =
    { texturePosition = Coord.xy 0 8 |> Coord.multiply Units.tileSize
    , size = Coord.xy 5 3
    , tileCollision =
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
    , movementCollision = []
    }


railStrafeUp : TileData units
railStrafeUp =
    { texturePosition = Coord.xy 5 8 |> Coord.multiply Units.tileSize
    , size = Coord.xy 5 3
    , tileCollision =
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
    , movementCollision = []
    }


railStrafeLeft : TileData units
railStrafeLeft =
    { texturePosition = Coord.xy 0 11 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 5
    , tileCollision =
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
    , movementCollision = []
    }


railStrafeRight : TileData units
railStrafeRight =
    { texturePosition = Coord.xy 0 16 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 5
    , tileCollision =
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
    , movementCollision = []
    }


trainHouseRight : TileData units
trainHouseRight =
    { texturePosition = Coord.xy 3 11 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


trainHouseLeft : TileData units
trainHouseLeft =
    { texturePosition = Coord.xy 7 11 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railStrafeDownSmall : TileData units
railStrafeDownSmall =
    { texturePosition = Coord.xy 3 15 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 2
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeDownSmall
    , movementCollision = []
    }


railStrafeUpSmall : TileData units
railStrafeUpSmall =
    { texturePosition = Coord.xy 7 15 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 2
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeUpSmall
    , movementCollision = []
    }


railStrafeLeftSmall : TileData units
railStrafeLeftSmall =
    { texturePosition = Coord.xy 0 21 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 4
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeLeftSmall
    , movementCollision = []
    }


railStrafeRightSmall : TileData units
railStrafeRightSmall =
    { texturePosition = Coord.xy 0 25 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 4
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath RailPathStrafeRightSmall
    , movementCollision = []
    }


sidewalk : TileData units
sidewalk =
    { texturePosition = Coord.xy 2 4 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


sidewalkHorizontalRailCrossing : TileData units
sidewalkHorizontalRailCrossing =
    { texturePosition = Coord.xy 0 4 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath (RailPathHorizontal { offsetX = 0, offsetY = 0, length = 1 })
    , movementCollision = []
    }


sidewalkVerticalRailCrossing : TileData units
sidewalkVerticalRailCrossing =
    { texturePosition = Coord.xy 1 4 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = SingleRailPath (RailPathVertical { offsetX = 0, offsetY = 0, length = 1 })
    , movementCollision = []
    }


railBottomToRight_SplitLeft : TileData units
railBottomToRight_SplitLeft =
    { texturePosition = Coord.xy 3 17 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railBottomToLeft_SplitUp : TileData units
railBottomToLeft_SplitUp =
    { texturePosition = Coord.xy 7 17 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railTopToRight_SplitDown : TileData units
railTopToRight_SplitDown =
    { texturePosition = Coord.xy 3 21 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railTopToLeft_SplitRight : TileData units
railTopToLeft_SplitRight =
    { texturePosition = Coord.xy 7 21 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railBottomToRight_SplitUp : TileData units
railBottomToRight_SplitUp =
    { texturePosition = Coord.xy 3 25 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railBottomToLeft_SplitRight : TileData units
railBottomToLeft_SplitRight =
    { texturePosition = Coord.xy 7 25 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railTopToRight_SplitLeft : TileData units
railTopToRight_SplitLeft =
    { texturePosition = Coord.xy 3 29 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


railTopToLeft_SplitDown : TileData units
railTopToLeft_SplitDown =
    { texturePosition = Coord.xy 7 29 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision =
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
    , movementCollision = []
    }


postOffice : TileData units
postOffice =
    { texturePosition = Coord.xy 0 33 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 5
    , tileCollision = collisionRectangle 0 1 4 4
    , railPath =
        SingleRailPath
            (RailPathHorizontal { offsetX = 0, offsetY = 4, length = 4 })
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 13 27) (Coord.xy 52 34) ]
    }


mowedGrass1 : TileData units
mowedGrass1 =
    { texturePosition = Coord.xy 11 20 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


mowedGrass4 : TileData units
mowedGrass4 =
    { texturePosition = Coord.xy 11 20 |> Coord.multiply Units.tileSize
    , size = Coord.xy 4 4
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


pineTree1 : TileData units
pineTree1 =
    { texturePosition = Coord.xy 11 24 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 2
    , tileCollision = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 7) (Coord.xy 12 8) ]
    }


pineTree2 : TileData units
pineTree2 =
    { texturePosition = Coord.xy 12 24 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 2
    , tileCollision = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 8) (Coord.xy 12 9) ]
    }


bigPineTree : TileData units
bigPineTree =
    { texturePosition = Coord.xy 640 756
    , size = Coord.xy 3 3
    , tileCollision = Set.fromList [ ( 1, 2 ) ] |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 24 41) (Coord.xy 13 10) ]
    }


logCabinDown : TileData units
logCabinDown =
    { texturePosition = Coord.xy 11 26 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 18) (Coord.xy 36 34) ]
    }


logCabinRight : TileData units
logCabinRight =
    { texturePosition = Coord.xy 11 29 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 18) (Coord.xy 36 34) ]
    }


logCabinUp : TileData units
logCabinUp =
    { texturePosition = Coord.xy 11 32 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 18) (Coord.xy 36 34) ]
    }


logCabinLeft : TileData units
logCabinLeft =
    { texturePosition = Coord.xy 11 35 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 18) (Coord.xy 36 34) ]
    }


roadHorizontal : TileData units
roadHorizontal =
    { texturePosition = Coord.xy 15 21 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadVertical : TileData units
roadVertical =
    { texturePosition = Coord.xy 14 30 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadBottomToLeft : TileData units
roadBottomToLeft =
    { texturePosition = Coord.xy 16 24 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadTopToLeft : TileData units
roadTopToLeft =
    { texturePosition = Coord.xy 16 27 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadTopToRight : TileData units
roadTopToRight =
    { texturePosition = Coord.xy 13 27 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadBottomToRight : TileData units
roadBottomToRight =
    { texturePosition = Coord.xy 13 24 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


road4Way : TileData units
road4Way =
    { texturePosition = Coord.xy 16 21 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadSidewalkCrossingHorizontal : TileData units
roadSidewalkCrossingHorizontal =
    { texturePosition = Coord.xy 15 18 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadSidewalkCrossingVertical : TileData units
roadSidewalkCrossingVertical =
    { texturePosition = Coord.xy 14 31 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


road3WayDown : TileData units
road3WayDown =
    { texturePosition = Coord.xy 13 32 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


road3WayLeft : TileData units
road3WayLeft =
    { texturePosition = Coord.xy 16 32 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


road3WayUp : TileData units
road3WayUp =
    { texturePosition = Coord.xy 16 35 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


road3WayRight : TileData units
road3WayRight =
    { texturePosition = Coord.xy 13 35 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadRailCrossingHorizontal : TileData units
roadRailCrossingHorizontal =
    { texturePosition = Coord.xy 19 27 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 3
    , tileCollision = DefaultCollision
    , railPath = RailPathVertical { offsetX = 0, offsetY = 0, length = 3 } |> SingleRailPath
    , movementCollision = []
    }


roadRailCrossingVertical : TileData units
roadRailCrossingVertical =
    { texturePosition = Coord.xy 17 30 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 1
    , tileCollision = DefaultCollision
    , railPath = RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 } |> SingleRailPath
    , movementCollision = []
    }


fenceHorizontal : TileData units
fenceHorizontal =
    { texturePosition = Coord.xy 8 33 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 8 7) (Coord.xy 24 5) ]
    }


fenceVertical : TileData units
fenceVertical =
    { texturePosition = Coord.xy 10 33 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 2
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 8 7) (Coord.xy 4 23) ]
    }


fenceDiagonal : TileData units
fenceDiagonal =
    { texturePosition = Coord.xy 8 36 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 1, 0 )
        , ( 0, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 8 16) (Coord.xy 14 14)
        , Bounds.fromCoordAndSize (Coord.xy 18 7) (Coord.xy 14 14)
        ]
    }


fenceAntidiagonal : TileData units
fenceAntidiagonal =
    { texturePosition = Coord.xy 8 34 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 0, 0 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 8 7) (Coord.xy 14 14)
        , Bounds.fromCoordAndSize (Coord.xy 18 16) (Coord.xy 14 14)
        ]
    }


roadDeadendUp : TileData units
roadDeadendUp =
    { texturePosition = Coord.xy 10 38 |> Coord.multiply Units.tileSize
    , size = Coord.xy 5 4
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadDeadendDown : TileData units
roadDeadendDown =
    { texturePosition = Coord.xy 15 38 |> Coord.multiply Units.tileSize
    , size = Coord.xy 5 4
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


busStopDown : TileData units
busStopDown =
    { texturePosition = Coord.xy 12 44 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 20) (Coord.xy 31 13) ]
    }


busStopLeft : TileData units
busStopLeft =
    { texturePosition = Coord.xy 16 42 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 0, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 3 4) (Coord.xy 12 29) ]
    }


busStopRight : TileData units
busStopRight =
    { texturePosition = Coord.xy 15 42 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 0, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 4) (Coord.xy 12 29) ]
    }


busStopUp : TileData units
busStopUp =
    { texturePosition = Coord.xy 12 46 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 0) (Coord.xy 31 13) ]
    }


hospital : TileData units
hospital =
    { texturePosition = Coord.xy 14 46 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 5
    , tileCollision =
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 54) ]
    }


statue : TileData units
statue =
    { texturePosition = Coord.xy 12 50 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 14 10) (Coord.xy 12 9) ]
    }


hedgeRowDown : TileData units
hedgeRowDown =
    { texturePosition = Coord.xy 17 46 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 27) (Coord.xy 20 9) ]
    }


hedgeRowLeft : TileData units
hedgeRowLeft =
    { texturePosition = Coord.xy 17 48 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 10 18) ]
    }


hedgeRowRight : TileData units
hedgeRowRight =
    { texturePosition = Coord.xy 17 50 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 30 18) (Coord.xy 10 18) ]
    }


hedgeRowUp : TileData units
hedgeRowUp =
    { texturePosition = Coord.xy 17 52 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 20 9) ]
    }


hedgeCornerDownLeft : TileData units
hedgeCornerDownLeft =
    { texturePosition = Coord.xy 14 54 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 20 27) (Coord.xy 20 9)
        , Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 10 18)
        ]
    }


hedgeCornerDownRight : TileData units
hedgeCornerDownRight =
    { texturePosition = Coord.xy 17 54 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 30 18) (Coord.xy 10 18)
        , Bounds.fromCoordAndSize (Coord.xy 20 27) (Coord.xy 20 9)
        ]
    }


hedgeCornerUpLeft : TileData units
hedgeCornerUpLeft =
    { texturePosition = Coord.xy 7 41 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 20 9)
        , Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 10 18)
        ]
    }


hedgeCornerUpRight : TileData units
hedgeCornerUpRight =
    { texturePosition = Coord.xy 14 52 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 20 9)
        , Bounds.fromCoordAndSize (Coord.xy 30 18) (Coord.xy 10 18)
        ]
    }


hedgePillarDownLeft : TileData units
hedgePillarDownLeft =
    { texturePosition = Coord.xy 28 52 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 27) (Coord.xy 10 9) ]
    }


hedgePillarDownRight : TileData units
hedgePillarDownRight =
    { texturePosition = Coord.xy 28 54 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 30 27) (Coord.xy 10 9) ]
    }


hedgePillarUpLeft : TileData units
hedgePillarUpLeft =
    { texturePosition = Coord.xy 31 52 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 10 9) ]
    }


hedgePillarUpRight : TileData units
hedgePillarUpRight =
    { texturePosition = Coord.xy 31 54 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 30 18) (Coord.xy 10 9) ]
    }


apartmentDown : TileData units
apartmentDown =
    { texturePosition = Coord.xy 28 40 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 5
    , tileCollision =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 45) (Coord.xy 40 41) ]
    }


apartmentLeft : TileData units
apartmentLeft =
    { texturePosition = Coord.xy 30 45 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 5
    , tileCollision =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 27) (Coord.xy 35 63) ]
    }


apartmentRight : TileData units
apartmentRight =
    { texturePosition = Coord.xy 28 45 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 5
    , tileCollision =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 27) (Coord.xy 35 63) ]
    }


apartmentUp : TileData units
apartmentUp =
    { texturePosition = Coord.xy 30 40 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 5
    , tileCollision =
        [ ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 48) (Coord.xy 40 38) ]
    }


rockDown : TileData units
rockDown =
    { texturePosition = Coord.xy 12 48 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 1 2) (Coord.xy 18 16) ]
    }


rockLeft : TileData units
rockLeft =
    { texturePosition = Coord.xy 13 48 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 1 2) (Coord.xy 18 16) ]
    }


rockRight : TileData units
rockRight =
    { texturePosition = Coord.xy 12 49 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 1 2) (Coord.xy 18 16) ]
    }


rockUp : TileData units
rockUp =
    { texturePosition = Coord.xy 13 49 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 1 2) (Coord.xy 18 16) ]
    }


flowers1 : TileData units
flowers1 =
    { texturePosition = Coord.xy 28 50 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 20 18) ]
    }


flowers2 : TileData units
flowers2 =
    { texturePosition = Coord.xy 31 50 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 20 18) ]
    }


elmTree : TileData units
elmTree =
    { texturePosition = Coord.xy 32 47 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 3
    , tileCollision =
        [ ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 24 44) (Coord.xy 12 8) ]
    }


dirtPathHorizontal : TileData units
dirtPathHorizontal =
    { texturePosition = Coord.xy 34 50 |> Coord.multiply Units.tileSize
    , size = Coord.xy 2 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


dirtPathVertical : TileData units
dirtPathVertical =
    { texturePosition = Coord.xy 34 51 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 2
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


bigText : Char -> TileData unit
bigText char =
    { texturePosition = Sprite.charTexturePosition char
    , size = Coord.xy 1 2
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


hyperlink : TileData unit
hyperlink =
    { texturePosition = Coord.xy 700 918
    , size = Coord.xy 1 2
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


benchDown : TileData unit
benchDown =
    { texturePosition = Coord.xy 640 738
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 11) (Coord.xy 16 6) ]
    }


benchLeft : TileData unit
benchLeft =
    { texturePosition = Coord.xy 660 720
    , size = Coord.xy 1 2
    , tileCollision = [ ( 0, 1 ) ] |> Set.fromList |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 1 3) (Coord.xy 7 13) ]
    }


benchRight : TileData unit
benchRight =
    { texturePosition = Coord.xy 680 720
    , size = Coord.xy 1 2
    , tileCollision = [ ( 0, 1 ) ] |> Set.fromList |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 12 3) (Coord.xy 7 13) ]
    }


benchUp : TileData unit
benchUp =
    { texturePosition = Coord.xy 700 738
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 0) (Coord.xy 16 8) ]
    }


parkingDown : TileData unit
parkingDown =
    { texturePosition = Coord.xy 640 666
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


parkingLeft : TileData unit
parkingLeft =
    { texturePosition = Coord.xy 700 720
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


parkingRight : TileData unit
parkingRight =
    { texturePosition = Coord.xy 640 720
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


parkingUp : TileData unit
parkingUp =
    { texturePosition = Coord.xy 640 702
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


parkingRoad : TileData unit
parkingRoad =
    { texturePosition = Coord.xy 640 684
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


parkingRoundabout : TileData unit
parkingRoundabout =
    { texturePosition = Coord.xy 660 648
    , size = Coord.xy 3 3
    , tileCollision =
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
    , movementCollision = []
    }


cornerHouseUpLeft : TileData units
cornerHouseUpLeft =
    { texturePosition = Coord.xy 660 576
    , size = Coord.xy 3 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 2, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 5 11) (Coord.xy 30 43)
        , Bounds.fromCoordAndSize (Coord.xy 0 11) (Coord.xy 60 25)
        ]
    }


cornerHouseUpRight : TileData units
cornerHouseUpRight =
    { texturePosition = Coord.xy 760 576
    , size = Coord.xy 3 3
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        , ( 2, 1 )
        , ( 1, 2 )
        , ( 2, 2 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 25 11) (Coord.xy 30 43)
        , Bounds.fromCoordAndSize (Coord.xy 0 11) (Coord.xy 60 25)
        ]
    }


cornerHouseDownLeft : TileData units
cornerHouseDownLeft =
    { texturePosition = Coord.xy 660 504
    , size = Coord.xy 3 4
    , tileCollision =
        [ ( 0, 2 )
        , ( 1, 2 )
        , ( 0, 3 )
        , ( 1, 3 )
        , ( 2, 3 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 5 33) (Coord.xy 30 39)
        , Bounds.fromCoordAndSize (Coord.xy 0 29) (Coord.xy 60 25)
        ]
    }


cornerHouseDownRight : TileData units
cornerHouseDownRight =
    { texturePosition = Coord.xy 760 504
    , size = Coord.xy 3 4
    , tileCollision =
        [ ( 1, 2 )
        , ( 2, 2 )
        , ( 0, 3 )
        , ( 1, 3 )
        , ( 2, 3 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 25 33) (Coord.xy 30 39)
        , Bounds.fromCoordAndSize (Coord.xy 0 29) (Coord.xy 60 25)
        ]
    }


dogHouseDown : TileData units
dogHouseDown =
    { texturePosition = Coord.xy 360 288
    , size = Coord.xy 1 2
    , tileCollision =
        [ ( 0, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 6 21) (Coord.xy 10 13) ]
    }


dogHouseUp : TileData units
dogHouseUp =
    { texturePosition = Coord.xy 380 288
    , size = Coord.xy 1 2
    , tileCollision =
        [ ( 0, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 6 21) (Coord.xy 10 13) ]
    }


dogHouseLeft : TileData units
dogHouseLeft =
    { texturePosition = Coord.xy 360 252
    , size = Coord.xy 1 2
    , tileCollision =
        [ ( 0, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 4 8) (Coord.xy 14 9) ]
    }


dogHouseRight : TileData units
dogHouseRight =
    { texturePosition = Coord.xy 380 252
    , size = Coord.xy 1 2
    , tileCollision =
        [ ( 0, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 6) (Coord.xy 14 9) ]
    }


mushroom : TileData units
mushroom =
    { texturePosition = Coord.xy 740 936
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


treeStump1 : TileData units
treeStump1 =
    { texturePosition = Coord.xy 720 936
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


treeStump2 : TileData units
treeStump2 =
    { texturePosition = Coord.xy 720 954
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


sunflowers : TileData units
sunflowers =
    { texturePosition = Coord.xy 720 900
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


railDeadEndLeft : TileData units
railDeadEndLeft =
    { texturePosition = Coord.xy 220 72
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 18) (Coord.xy 14 18) ]
    }


railDeadEndRight : TileData units
railDeadEndRight =
    { texturePosition = Coord.xy 220 108
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 6 18) (Coord.xy 14 18) ]
    }


railStrafeLeftToRight_SplitUp : TileData units
railStrafeLeftToRight_SplitUp =
    { texturePosition = Coord.xy 360 54
    , size = Coord.xy 5 3
    , tileCollision =
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
    , railPath =
        RailSplitPath
            { primary = RailPathHorizontal { offsetX = 0, offsetY = 2, length = 3 }
            , secondary = RailPathStrafeUp
            , texturePosition = Coord.xy 360 0
            }
    , movementCollision = []
    }


railStrafeLeftToRight_SplitDown : TileData units
railStrafeLeftToRight_SplitDown =
    { texturePosition = Coord.xy 260 108
    , size = Coord.xy 5 3
    , tileCollision =
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
    , railPath =
        RailSplitPath
            { primary = RailPathHorizontal { offsetX = 0, offsetY = 0, length = 3 }
            , secondary = RailPathStrafeDown
            , texturePosition = Coord.xy 260 162
            }
    , movementCollision = []
    }


railStrafeRightToLeft_SplitUp : TileData units
railStrafeRightToLeft_SplitUp =
    { texturePosition = Coord.xy 260 54
    , size = Coord.xy 5 3
    , tileCollision =
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
    , railPath =
        RailSplitPath
            { primary = RailPathHorizontal { offsetX = 2, offsetY = 2, length = 3 }
            , secondary = RailPathStrafeDown
            , texturePosition = Coord.xy 260 0
            }
    , movementCollision = []
    }


railStrafeRightToLeft_SplitDown : TileData units
railStrafeRightToLeft_SplitDown =
    { texturePosition = Coord.xy 360 108
    , size = Coord.xy 5 3
    , tileCollision =
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
    , railPath =
        RailSplitPath
            { primary = RailPathHorizontal { offsetX = 2, offsetY = 0, length = 3 }
            , secondary = RailPathStrafeUp
            , texturePosition = Coord.xy 360 162
            }
    , movementCollision = []
    }


railStrafeTopToBottom_SplitLeft : TileData units
railStrafeTopToBottom_SplitLeft =
    { texturePosition = Coord.xy 700 324
    , size = Coord.xy 3 5
    , tileCollision =
        [ ( 0, 0 )
        , ( 1, 0 )
        , ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 2 )
        , ( 1, 3 )
        , ( 2, 3 )
        , ( 1, 4 )
        , ( 2, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath =
        RailSplitPath
            { primary = RailPathVertical { offsetX = 0, offsetY = 0, length = 3 }
            , secondary = RailPathStrafeRight
            , texturePosition = Coord.xy 640 324
            }
    , movementCollision = []
    }


railStrafeTopToBottom_SplitRight : TileData units
railStrafeTopToBottom_SplitRight =
    { texturePosition = Coord.xy 640 144
    , size = Coord.xy 3 5
    , tileCollision =
        [ ( 1, 0 )
        , ( 2, 0 )
        , ( 1, 1 )
        , ( 2, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 2 )
        , ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath =
        RailSplitPath
            { primary = RailPathVertical { offsetX = 2, offsetY = 0, length = 3 }
            , secondary = RailPathStrafeLeft
            , texturePosition = Coord.xy 700 144
            }
    , movementCollision = []
    }


railStrafeBottomToTop_SplitLeft : TileData units
railStrafeBottomToTop_SplitLeft =
    { texturePosition = Coord.xy 640 234
    , size = Coord.xy 3 5
    , tileCollision =
        [ ( 0, 0 )
        , ( 1, 0 )
        , ( 0, 1 )
        , ( 1, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 2 )
        , ( 1, 3 )
        , ( 2, 3 )
        , ( 1, 4 )
        , ( 2, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath =
        RailSplitPath
            { primary = RailPathVertical { offsetX = 2, offsetY = 2, length = 3 }
            , secondary = RailPathStrafeRight
            , texturePosition = Coord.xy 700 234
            }
    , movementCollision = []
    }


railStrafeBottomToTop_SplitRight : TileData units
railStrafeBottomToTop_SplitRight =
    { texturePosition = Coord.xy 700 414
    , size = Coord.xy 3 5
    , tileCollision =
        [ ( 1, 0 )
        , ( 2, 0 )
        , ( 1, 1 )
        , ( 2, 1 )
        , ( 0, 2 )
        , ( 1, 2 )
        , ( 2, 2 )
        , ( 0, 3 )
        , ( 1, 3 )
        , ( 0, 4 )
        , ( 1, 4 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath =
        RailSplitPath
            { primary = RailPathVertical { offsetX = 0, offsetY = 2, length = 3 }
            , secondary = RailPathStrafeLeft
            , texturePosition = Coord.xy 640 414
            }
    , movementCollision = []
    }


roadManholeDown : TileData units
roadManholeDown =
    { texturePosition = Coord.xy 380 378
    , size = Coord.xy 1 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadManholeLeft : TileData units
roadManholeLeft =
    { texturePosition = Coord.xy 240 756
    , size = Coord.xy 3 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadManholeUp : TileData units
roadManholeUp =
    { texturePosition = Coord.xy 380 432
    , size = Coord.xy 1 3
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


roadManholeRight : TileData units
roadManholeRight =
    { texturePosition = Coord.xy 340 558
    , size = Coord.xy 3 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


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
