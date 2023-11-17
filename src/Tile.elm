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
    , TileGroupData
    , aggregateMovementCollision
    , allCategories
    , allTileGroups
    , allTiles
    , buildingCategory
    , categoryToString
    , codec
    , decoder
    , defaultBerryBushColor
    , defaultIronFenceColor
    , defaultMushroomColor
    , defaultPineTreeColor
    , defaultPostOfficeColor
    , defaultRockColor
    , defaultStoreColor
    , defaultToPrimaryAndSecondary
    , encoder
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
    , worldMovementBounds
    )

import Angle
import Array
import Axis2d
import BoundingBox2d exposing (BoundingBox2d)
import Bounds exposing (Bounds)
import Bytes exposing (Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Codec exposing (Codec)
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Dict
import Direction2d exposing (Direction2d)
import Hyperlink exposing (Hyperlink)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Sprite
import String.Nonempty exposing (NonemptyString(..))
import Units exposing (CellLocalUnit, TileLocalUnit, WorldUnit)
import Vector2d exposing (Vector2d)


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
    | BerryBushGroup
    | SmallHouseGroup
    | OfficeGroup
    | FireTruckGarageGroup
    | TownHouseGroup
    | RowHouseGroup
    | WideParkingLotGroup
    | GazeboGroup
    | ConvenienceStoreGroup
    | BeautySalonGroup
    | CheckmartGroup
    | TreeStoreGroup
    | IronFenceGroup
    | IronGateGroup
    | DeadTreeGroup


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
        , ( "Bush", BerryBushGroup )
        , ( "SmallHouseGroup", SmallHouseGroup )
        , ( "OfficeGroup", OfficeGroup )
        , ( "FireTruckHouseGroup", FireTruckGarageGroup )
        , ( "BrickApartmentGroup", TownHouseGroup )
        , ( "RowHouseGroup", RowHouseGroup )
        , ( "WideParkingLotGroup", WideParkingLotGroup )
        , ( "GazeboGroup", GazeboGroup )
        , ( "ConvenienceStoreGroup", ConvenienceStoreGroup )
        , ( "BeautySalonGroup", BeautySalonGroup )
        , ( "CheckmartGroup", CheckmartGroup )
        , ( "TreeStoreGroup", TreeStoreGroup )
        , ( "IronFenceGroup", IronFenceGroup )
        , ( "IronGateGroup", IronGateGroup )
        , ( "DeadTreeGroup", DeadTreeGroup )
        ]


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
    , BigTextGroup
    , HyperlinkGroup
    , BenchGroup
    , ParkingLotGroup
    , ParkingRoadGroup
    , ParkingRoundaboutGroup
    , CornerHouseGroup
    , DogHouseGroup
    , MushroomGroup
    , TreeStumpGroup
    , SunflowersGroup
    , RailDeadendGroup
    , RailStrafeSplitGroup
    , RailStrafeSplitMirrorGroup
    , RoadStraightManholeGroup
    , BerryBushGroup
    , SmallHouseGroup
    , OfficeGroup
    , FireTruckGarageGroup
    , TownHouseGroup
    , RowHouseGroup
    , WideParkingLotGroup
    , GazeboGroup
    , ConvenienceStoreGroup
    , BeautySalonGroup
    , CheckmartGroup
    , TreeStoreGroup
    , IronFenceGroup
    , IronGateGroup
    , DeadTreeGroup
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
    , BerryBushGroup
    , GazeboGroup
    , IronFenceGroup
    , IronGateGroup
    , DeadTreeGroup
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
    , SmallHouseGroup
    , OfficeGroup
    , FireTruckGarageGroup
    , TownHouseGroup
    , RowHouseGroup
    , GazeboGroup
    , ConvenienceStoreGroup
    , BeautySalonGroup
    , CheckmartGroup
    , TreeStoreGroup
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
    , ParkingRoadGroup
    , ParkingRoundaboutGroup
    , WideParkingLotGroup
    ]


tileToTileGroup : Tile -> Maybe { tileGroup : TileGroup, index : Int }
tileToTileGroup tile =
    case tile of
        HyperlinkTile _ ->
            Just { tileGroup = HyperlinkGroup, index = 0 }

        _ ->
            List.findMap
                (\tileGroup ->
                    case getTileGroupData tileGroup |> .tiles |> List.Nonempty.toList |> List.findIndex ((==) tile) of
                        Just index ->
                            Just { tileGroup = tileGroup, index = index }

                        Nothing ->
                            Nothing
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
            , tiles = Nonempty HospitalDown [ HospitalLeft, HospitalUp, HospitalRight ]
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
            , tiles = Nonempty (HyperlinkTile Hyperlink.exampleCom) []
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

        WideParkingLotGroup ->
            { defaultColors = OneDefaultColor (Color.rgb255 243 243 243)
            , tiles = Nonempty WideParkingDown [ WideParkingLeft, WideParkingUp, WideParkingRight ]
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
            , tiles = Nonempty Mushroom1 [ Mushroom2 ]
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

        BerryBushGroup ->
            { defaultColors = defaultBerryBushColor
            , tiles = Nonempty BerryBush1 [ BerryBush2 ]
            , name = "Berry bush"
            }

        SmallHouseGroup ->
            { defaultColors = defaultSmallHouseColor
            , tiles = Nonempty SmallHouseDown [ SmallHouseLeft, SmallHouseUp, SmallHouseRight ]
            , name = "Small house"
            }

        OfficeGroup ->
            { defaultColors = defaultOfficeColor
            , tiles = Nonempty OfficeDown [ OfficeUp ]
            , name = "Office"
            }

        FireTruckGarageGroup ->
            { defaultColors = defaultFireTruckHouseColor
            , tiles = Nonempty FireTruckGarage []
            , name = "Fire truck garage"
            }

        TownHouseGroup ->
            { defaultColors = defaultTownHouseColor
            , tiles = Nonempty TownHouse0 [ TownHouse1, TownHouse2, TownHouse3, TownHouse4 ]
            , name = "Town house"
            }

        RowHouseGroup ->
            { defaultColors = defaultRowHouseColor
            , tiles = Nonempty RowHouse0 [ RowHouse1, RowHouse2, RowHouse3 ]
            , name = "Row house"
            }

        GazeboGroup ->
            { defaultColors = defaultGazeboColor
            , tiles = Nonempty Gazebo []
            , name = "Gazebo"
            }

        ConvenienceStoreGroup ->
            { defaultColors = defaultStoreColor
            , tiles = Nonempty ConvenienceStoreDown [ ConvenienceStoreUp ]
            , name = "Convenience store"
            }

        BeautySalonGroup ->
            { defaultColors = defaultStoreColor
            , tiles = Nonempty BeautySalonDown [ BeautySalonUp ]
            , name = "Beauty salon"
            }

        CheckmartGroup ->
            { defaultColors = defaultStoreColor
            , tiles = Nonempty CheckmartDown [ CheckmartUp ]
            , name = "Checkmart"
            }

        TreeStoreGroup ->
            { defaultColors = defaultStoreColor
            , tiles = Nonempty TreeStoreDown [ TreeStoreUp ]
            , name = "Tree store"
            }

        IronFenceGroup ->
            { defaultColors = defaultIronFenceColor
            , tiles = Nonempty IronFenceHorizontal [ IronFenceDiagonal, IronFenceVertical, IronFenceAntidiagonal ]
            , name = "Iron fence"
            }

        IronGateGroup ->
            { defaultColors = defaultIronFenceColor
            , tiles = Nonempty IronGate []
            , name = "Iron gate"
            }

        DeadTreeGroup ->
            { defaultColors = deadTreeColor
            , tiles = Nonempty DeadTree []
            , name = "Dead tree"
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
    | HospitalDown
    | HospitalLeft
    | HospitalUp
    | HospitalRight
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
    | HyperlinkTile Hyperlink
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
    | Mushroom1
    | Mushroom2
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
    | BerryBush1
    | BerryBush2
    | SmallHouseDown
    | SmallHouseLeft
    | SmallHouseUp
    | SmallHouseRight
    | OfficeDown
    | OfficeUp
    | FireTruckGarage
    | TownHouse0
    | TownHouse1
    | TownHouse2
    | TownHouse3
    | TownHouse4
    | RowHouse0
    | RowHouse1
    | RowHouse2
    | RowHouse3
    | WideParkingDown
    | WideParkingLeft
    | WideParkingUp
    | WideParkingRight
    | Gazebo
    | ConvenienceStoreDown
    | ConvenienceStoreUp
    | BeautySalonDown
    | BeautySalonUp
    | CheckmartDown
    | CheckmartUp
    | TreeStoreDown
    | TreeStoreUp
    | IronFenceHorizontal
    | IronFenceDiagonal
    | IronFenceVertical
    | IronFenceAntidiagonal
    | IronGate
    | DeadTree


aggregateMovementCollision : BoundingBox2d WorldUnit WorldUnit
aggregateMovementCollision =
    let
        bounds =
            List.foldl
                (\tile bounds2 ->
                    Bounds.aggregate (Nonempty bounds2 (getData tile |> .movementCollision))
                )
                (Bounds.from2Coords Coord.origin Coord.origin)
                allTiles
    in
    BoundingBox2d.from
        (Bounds.minimum bounds |> Units.pixelToTilePoint)
        (Bounds.maximum bounds |> Units.pixelToTilePoint)


allTiles : List Tile
allTiles =
    [ EmptyTile
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
    , PostOffice
    , PineTree1
    , PineTree2
    , BigPineTree
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
    , FenceHorizontal
    , FenceVertical
    , FenceDiagonal
    , FenceAntidiagonal
    , RoadDeadendUp
    , RoadDeadendDown
    , BusStopDown
    , BusStopLeft
    , BusStopRight
    , BusStopUp
    , HospitalDown
    , Statue
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
    , ApartmentDown
    , ApartmentLeft
    , ApartmentRight
    , ApartmentUp
    , RockDown
    , RockLeft
    , RockRight
    , RockUp
    , Flowers1
    , Flowers2
    , ElmTree
    , DirtPathHorizontal
    , DirtPathVertical
    , HyperlinkTile Hyperlink.exampleCom
    , BenchDown
    , BenchLeft
    , BenchUp
    , BenchRight
    , ParkingDown
    , ParkingLeft
    , ParkingUp
    , ParkingRight
    , ParkingRoad
    , ParkingRoundabout
    , CornerHouseUpLeft
    , CornerHouseUpRight
    , CornerHouseDownLeft
    , CornerHouseDownRight
    , DogHouseDown
    , DogHouseRight
    , DogHouseUp
    , DogHouseLeft
    , Mushroom1
    , TreeStump1
    , TreeStump2
    , Sunflowers
    , RailDeadEndLeft
    , RailDeadEndRight
    , RailStrafeLeftToRight_SplitUp
    , RailStrafeLeftToRight_SplitDown
    , RailStrafeRightToLeft_SplitUp
    , RailStrafeRightToLeft_SplitDown
    , RailStrafeTopToBottom_SplitLeft
    , RailStrafeTopToBottom_SplitRight
    , RailStrafeBottomToTop_SplitLeft
    , RailStrafeBottomToTop_SplitRight
    , RoadManholeDown
    , RoadManholeLeft
    , RoadManholeUp
    , RoadManholeRight
    , BerryBush1
    , BerryBush2
    , SmallHouseDown
    , SmallHouseLeft
    , SmallHouseUp
    , SmallHouseRight
    , OfficeDown
    , OfficeUp
    , FireTruckGarage
    , TownHouse0
    , TownHouse1
    , TownHouse2
    , TownHouse3
    , TownHouse4
    , RowHouse0
    ]
        ++ List.map BigText (List.Nonempty.toList Sprite.asciiChars)


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


turnLength : Float
turnLength =
    trackTurnRadius * pi / 2


turnLengthLarge : Float
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
    , movementCollision : List (Bounds Pixels)
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
        tileDataA : TileData unit
        tileDataA =
            getData tileA

        tileDataB : TileData unit
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
    if isFence tileA && isFence tileB && (positionA /= positionB || tileDataA.size /= tileDataB.size) then
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


isFence : Tile -> Bool
isFence tile =
    (tile == FenceHorizontal)
        || (tile == FenceVertical)
        || (tile == FenceDiagonal)
        || (tile == FenceAntidiagonal)
        || (tile == DirtPathHorizontal)
        || (tile == DirtPathVertical)
        || (tile == IronFenceHorizontal)
        || (tile == IronFenceVertical)
        || (tile == IronFenceDiagonal)
        || (tile == IronFenceAntidiagonal)
        || (tile == IronGate)


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


sidewalkColor : Color
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


defaultBerryBushColor : DefaultColor
defaultBerryBushColor =
    TwoDefaultColors { primaryColor = Color.rgb255 44 148 54, secondaryColor = Color.rgb255 182 8 8 }


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


defaultHedgeBushColor : DefaultColor
defaultHedgeBushColor =
    OneDefaultColor (Color.rgb255 74 148 74)


defaultApartmentColor : DefaultColor
defaultApartmentColor =
    TwoDefaultColors { primaryColor = Color.rgb255 127 53 53, secondaryColor = Color.rgb255 202 170 105 }


defaultRockColor : DefaultColor
defaultRockColor =
    OneDefaultColor (Color.rgb255 160 160 160)


defaultFlowerColor : DefaultColor
defaultFlowerColor =
    TwoDefaultColors { primaryColor = Color.rgb255 242 210 81, secondaryColor = Color.rgb255 242 146 0 }


defaultElmTreeColor : DefaultColor
defaultElmTreeColor =
    TwoDefaultColors { primaryColor = Color.rgb255 39 171 82, secondaryColor = Color.rgb255 141 96 65 }


defaultDirtPathColor : DefaultColor
defaultDirtPathColor =
    OneDefaultColor (Color.rgb255 192 146 117)


defaultBenchColor : DefaultColor
defaultBenchColor =
    OneDefaultColor (Color.rgb255 162 115 83)


defaultCornerHouseColor : DefaultColor
defaultCornerHouseColor =
    TwoDefaultColors { primaryColor = Color.rgb255 101 108 124, secondaryColor = Color.rgb255 103 157 236 }


defaultSmallHouseColor : DefaultColor
defaultSmallHouseColor =
    TwoDefaultColors { primaryColor = Color.rgb255 113 201 139, secondaryColor = Color.rgb255 222 156 66 }


defaultOfficeColor : DefaultColor
defaultOfficeColor =
    TwoDefaultColors { primaryColor = Color.rgb255 162 168 216, secondaryColor = Color.rgb255 215 215 215 }


defaultTownHouseColor : DefaultColor
defaultTownHouseColor =
    TwoDefaultColors { primaryColor = Color.rgb255 231 120 91, secondaryColor = Color.rgb255 171 185 83 }


defaultFireTruckHouseColor : DefaultColor
defaultFireTruckHouseColor =
    TwoDefaultColors { primaryColor = Color.rgb255 234 183 106, secondaryColor = Color.rgb255 187 66 34 }


defaultRowHouseColor : DefaultColor
defaultRowHouseColor =
    TwoDefaultColors { primaryColor = Color.rgb255 171 111 40, secondaryColor = Color.rgb255 189 166 118 }


defaultGazeboColor : DefaultColor
defaultGazeboColor =
    TwoDefaultColors { primaryColor = Color.rgb255 77 124 86, secondaryColor = Color.rgb255 204 204 204 }


defaultStoreColor : DefaultColor
defaultStoreColor =
    TwoDefaultColors { primaryColor = Color.rgb255 219 210 197, secondaryColor = Color.rgb255 174 194 204 }


defaultIronFenceColor : DefaultColor
defaultIronFenceColor =
    TwoDefaultColors { primaryColor = Color.rgb255 65 65 65, secondaryColor = Color.rgb255 201 212 210 }


deadTreeColor : DefaultColor
deadTreeColor =
    OneDefaultColor (Color.rgb255 169 123 63)


worldMovementBounds : Vector2d WorldUnit WorldUnit -> Tile -> Coord WorldUnit -> List (BoundingBox2d WorldUnit WorldUnit)
worldMovementBounds expandBoundsBy tile worldPos =
    List.map
        (\a ->
            BoundingBox2d.from
                (Bounds.minimum a |> Units.pixelToTilePoint |> Point2d.translateBy (Vector2d.reverse expandBoundsBy))
                (Bounds.maximum a |> Units.pixelToTilePoint |> Point2d.translateBy expandBoundsBy)
                |> BoundingBox2d.translateBy (Coord.toVector2d worldPos)
        )
        (getData tile).movementCollision


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

        HospitalDown ->
            hospitalDown

        HospitalLeft ->
            hospitalLeft

        HospitalUp ->
            hospitalUp

        HospitalRight ->
            hospitalRight

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

        HyperlinkTile _ ->
            hyperlinkTile

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

        Mushroom1 ->
            mushroom1

        Mushroom2 ->
            mushroom2

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

        BerryBush1 ->
            berryBush1

        BerryBush2 ->
            berryBush2

        SmallHouseDown ->
            smallHouseDown

        SmallHouseLeft ->
            smallHouseLeft

        SmallHouseUp ->
            smallHouseUp

        SmallHouseRight ->
            smallHouseRight

        OfficeDown ->
            officeDown

        OfficeUp ->
            officeUp

        FireTruckGarage ->
            fireTruckGarage

        TownHouse0 ->
            townHouse0

        TownHouse1 ->
            townHouse1

        TownHouse2 ->
            townHouse2

        TownHouse3 ->
            townHouse3

        TownHouse4 ->
            townHouse4

        RowHouse0 ->
            rowHouse0

        RowHouse1 ->
            rowHouse1

        RowHouse2 ->
            rowHouse2

        RowHouse3 ->
            rowHouse3

        WideParkingDown ->
            wideParkingDown

        WideParkingLeft ->
            wideParkingLeft

        WideParkingUp ->
            wideParkingUp

        WideParkingRight ->
            wideParkingRight

        Gazebo ->
            gazebo

        ConvenienceStoreDown ->
            convenienceStoreDown

        ConvenienceStoreUp ->
            convenienceStoreUp

        BeautySalonDown ->
            beautySalonDown

        BeautySalonUp ->
            beautySalonUp

        CheckmartDown ->
            checkmartDown

        CheckmartUp ->
            checkmartUp

        TreeStoreDown ->
            treeStoreDown

        TreeStoreUp ->
            treeStoreUp

        IronFenceHorizontal ->
            ironFenceHorizontal

        IronFenceDiagonal ->
            ironFenceDiagonal

        IronFenceVertical ->
            ironFenceVertical

        IronFenceAntidiagonal ->
            ironFenceAntidiagonal

        IronGate ->
            ironGate

        DeadTree ->
            deadTree


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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 7 24) (Coord.xy 48 24) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 3 23) (Coord.xy 27 46) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 24) (Coord.xy 48 27) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 10 23) (Coord.xy 27 46) ]
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


pineTree1 : TileData units
pineTree1 =
    { texturePosition = Coord.xy 11 24 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 2
    , tileCollision = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 6 25) (Coord.xy 10 8) ]
    }


pineTree2 : TileData units
pineTree2 =
    { texturePosition = Coord.xy 12 24 |> Coord.multiply Units.tileSize
    , size = Coord.xy 1 2
    , tileCollision = Set.fromList [ ( 0, 1 ) ] |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 26) (Coord.xy 9 9) ]
    }


bigPineTree : TileData units
bigPineTree =
    { texturePosition = Coord.xy 640 756
    , size = Coord.xy 3 3
    , tileCollision = Set.fromList [ ( 1, 2 ) ] |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 25 41) (Coord.xy 10 10) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 49) (Coord.xy 3 3) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 3 20) (Coord.xy 12 29) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 20) (Coord.xy 12 29) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 5 18) (Coord.xy 31 13) ]
    }


hospitalDown : TileData units
hospitalDown =
    { texturePosition = Coord.xy 14 46 |> Coord.multiply Units.tileSize
    , size = Coord.xy 3 5
    , tileCollision = collisionRectangle 0 2 3 3
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 54) ]
    }


hospitalLeft : TileData units
hospitalLeft =
    { texturePosition = Coord.xy 820 846
    , size = Coord.xy 2 6
    , tileCollision = collisionRectangle 0 3 2 3
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 54) ]
    }


hospitalUp : TileData units
hospitalUp =
    { texturePosition = Coord.xy 860 846
    , size = Coord.xy 3 6
    , tileCollision = collisionRectangle 0 3 3 3
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 54) ]
    }


hospitalRight : TileData units
hospitalRight =
    { texturePosition = Coord.xy 920 846
    , size = Coord.xy 2 6
    , tileCollision = collisionRectangle 0 3 2 3
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 14 27) (Coord.xy 12 9) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 52) (Coord.xy 40 38) ]
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
    , movementCollision = []
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
    , movementCollision = []
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


hyperlinkTile : TileData unit
hyperlinkTile =
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 1 21) (Coord.xy 7 13) ]
    }


benchRight : TileData unit
benchRight =
    { texturePosition = Coord.xy 680 720
    , size = Coord.xy 1 2
    , tileCollision = [ ( 0, 1 ) ] |> Set.fromList |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 12 21) (Coord.xy 7 13) ]
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


wideParkingDown : TileData unit
wideParkingDown =
    { texturePosition = Coord.xy 720 648
    , size = Coord.xy 2 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


wideParkingLeft : TileData unit
wideParkingLeft =
    { texturePosition = Coord.xy 720 666
    , size = Coord.xy 1 2
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


wideParkingRight : TileData unit
wideParkingRight =
    { texturePosition = Coord.xy 740 666
    , size = Coord.xy 1 2
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


wideParkingUp : TileData unit
wideParkingUp =
    { texturePosition = Coord.xy 720 630
    , size = Coord.xy 2 1
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
        , Bounds.fromCoordAndSize (Coord.xy 0 47) (Coord.xy 60 25)
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
        , Bounds.fromCoordAndSize (Coord.xy 0 47) (Coord.xy 60 25)
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 4 21) (Coord.xy 10 13) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 4 26) (Coord.xy 14 9) ]
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
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 2 24) (Coord.xy 14 9) ]
    }


mushroom1 : TileData units
mushroom1 =
    { texturePosition = Coord.xy 740 936
    , size = Coord.xy 1 1
    , tileCollision = DefaultCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


mushroom2 : TileData units
mushroom2 =
    { texturePosition = Coord.xy 740 954
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


berryBush1 : TileData units
berryBush1 =
    { texturePosition = Coord.xy 680 972
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


berryBush2 : TileData units
berryBush2 =
    { texturePosition = Coord.xy 740 972
    , size = Coord.xy 3 2
    , tileCollision =
        [ ( 1, 1 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision = []
    }


smallHouseDown : TileData units
smallHouseDown =
    { texturePosition = Coord.xy 820 504
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 11 26) (Coord.xy 29 28) ]
    }


smallHouseLeft : TileData units
smallHouseLeft =
    { texturePosition = Coord.xy 940 648
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 11 26) (Coord.xy 29 28) ]
    }


smallHouseUp : TileData units
smallHouseUp =
    { texturePosition = Coord.xy 940 504
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 1 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 26) (Coord.xy 29 28) ]
    }


smallHouseRight : TileData units
smallHouseRight =
    { texturePosition = Coord.xy 880 504
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 1 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 20 26) (Coord.xy 29 28) ]
    }


officeDown : TileData units
officeDown =
    { texturePosition = Coord.xy 820 558
    , size = Coord.xy 4 5
    , tileCollision = collisionRectangle 0 3 4 2
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 0 54) (Coord.xy 30 36)
        , Bounds.fromCoordAndSize (Coord.xy 50 54) (Coord.xy 30 36)
        , Bounds.fromCoordAndSize (Coord.xy 30 54) (Coord.xy 20 29)
        ]
    }


officeUp : TileData units
officeUp =
    { texturePosition = Coord.xy 900 558
    , size = Coord.xy 4 5
    , tileCollision = collisionRectangle 0 3 4 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 54) (Coord.xy 80 36) ]
    }


fireTruckGarage : TileData units
fireTruckGarage =
    { texturePosition = Coord.xy 820 648
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 31) (Coord.xy 60 23) ]
    }


townHouse0 : TileData units
townHouse0 =
    { texturePosition = Coord.xy 880 648
    , size = Coord.xy 2 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 28) (Coord.xy 40 26) ]
    }


townHouse1 : TileData units
townHouse1 =
    { texturePosition = Coord.xy 840 702
    , size = Coord.xy 2 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 28) (Coord.xy 40 26) ]
    }


townHouse2 : TileData units
townHouse2 =
    { texturePosition = Coord.xy 880 702
    , size = Coord.xy 2 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 28) (Coord.xy 40 26) ]
    }


townHouse3 : TileData units
townHouse3 =
    { texturePosition = Coord.xy 920 702
    , size = Coord.xy 2 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 28) (Coord.xy 40 26) ]
    }


townHouse4 : TileData units
townHouse4 =
    { texturePosition = Coord.xy 960 702
    , size = Coord.xy 2 3
    , tileCollision = collisionRectangle 0 1 2 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 28) (Coord.xy 40 26) ]
    }


rowHouse0 : TileData units
rowHouse0 =
    { texturePosition = Coord.xy 920 648
    , size = Coord.xy 1 3
    , tileCollision = collisionRectangle 0 1 1 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 31) (Coord.xy 20 23) ]
    }


rowHouse1 : TileData units
rowHouse1 =
    { texturePosition = Coord.xy 760 648
    , size = Coord.xy 1 3
    , tileCollision = collisionRectangle 0 1 1 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 31) (Coord.xy 20 23) ]
    }


rowHouse2 : TileData units
rowHouse2 =
    { texturePosition = Coord.xy 780 648
    , size = Coord.xy 1 3
    , tileCollision = collisionRectangle 0 1 1 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 31) (Coord.xy 20 23) ]
    }


rowHouse3 : TileData units
rowHouse3 =
    { texturePosition = Coord.xy 800 648
    , size = Coord.xy 1 3
    , tileCollision = collisionRectangle 0 1 1 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 31) (Coord.xy 20 23) ]
    }


gazebo : TileData units
gazebo =
    { texturePosition = Coord.xy 760 702
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 1 2 1 1
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 14 31) (Coord.xy 32 21) ]
    }


convenienceStoreDown : TileData units
convenienceStoreDown =
    { texturePosition = Coord.xy 140 1008
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 25) (Coord.xy 60 29) ]
    }


convenienceStoreUp : TileData units
convenienceStoreUp =
    { texturePosition = Coord.xy 140 1080
    , size = Coord.xy 3 4
    , tileCollision = collisionRectangle 0 2 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 29) ]
    }


beautySalonDown : TileData units
beautySalonDown =
    { texturePosition = Coord.xy 200 1008
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 25) (Coord.xy 60 29) ]
    }


beautySalonUp : TileData units
beautySalonUp =
    { texturePosition = Coord.xy 200 1080
    , size = Coord.xy 3 4
    , tileCollision = collisionRectangle 0 2 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 29) ]
    }


checkmartDown : TileData units
checkmartDown =
    { texturePosition = Coord.xy 260 1008
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 25) (Coord.xy 60 29) ]
    }


checkmartUp : TileData units
checkmartUp =
    { texturePosition = Coord.xy 260 1080
    , size = Coord.xy 3 4
    , tileCollision = collisionRectangle 0 2 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 29) ]
    }


treeStoreDown : TileData units
treeStoreDown =
    { texturePosition = Coord.xy 320 1008
    , size = Coord.xy 3 3
    , tileCollision = collisionRectangle 0 1 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 25) (Coord.xy 60 29) ]
    }


treeStoreUp : TileData units
treeStoreUp =
    { texturePosition = Coord.xy 320 1080
    , size = Coord.xy 3 4
    , tileCollision = collisionRectangle 0 2 3 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 0 36) (Coord.xy 60 29) ]
    }


ironFenceHorizontal : TileData units
ironFenceHorizontal =
    { texturePosition = Coord.xy 0 1026
    , size = Coord.xy 2 1
    , tileCollision = collisionRectangle 0 0 2 1
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 8 7) (Coord.xy 24 5) ]
    }


ironFenceDiagonal : TileData units
ironFenceDiagonal =
    { texturePosition = Coord.xy 0 1080
    , size = Coord.xy 2 2
    , tileCollision =
        [ ( 0, 1 )
        , ( 1, 0 )
        ]
            |> Set.fromList
            |> CustomCollision
    , railPath = NoRailPath
    , movementCollision =
        [ Bounds.fromCoordAndSize (Coord.xy 8 16) (Coord.xy 14 14)
        , Bounds.fromCoordAndSize (Coord.xy 18 7) (Coord.xy 14 14)
        ]
    }


ironFenceVertical : TileData units
ironFenceVertical =
    { texturePosition = Coord.xy 40 1026
    , size = Coord.xy 1 2
    , tileCollision = collisionRectangle 0 0 1 2
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 8 7) (Coord.xy 4 23) ]
    }


ironFenceAntidiagonal : TileData units
ironFenceAntidiagonal =
    { texturePosition = Coord.xy 0 1044
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


ironGate : TileData units
ironGate =
    { texturePosition = Coord.xy 40 1062
    , size = Coord.xy 3 2
    , tileCollision = collisionRectangle 0 1 3 1
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 8 25) (Coord.xy 44 5) ]
    }


deadTree : TileData units
deadTree =
    { texturePosition = Coord.xy 100 990
    , size = Coord.xy 2 3
    , tileCollision = collisionRectangle 0 2 1 1
    , railPath = NoRailPath
    , movementCollision = [ Bounds.fromCoordAndSize (Coord.xy 14 45) (Coord.xy 5 5) ]
    }


collisionRectangle : Int -> Int -> Int -> Int -> CollisionMask
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


encoder : Tile -> Bytes.Encode.Encoder
encoder tile =
    case tile of
        BigText char ->
            maxTileValue
                - Maybe.withDefault 0 (Dict.get char Sprite.charToInt)
                |> Bytes.Encode.unsignedInt16 BE

        EmptyTile ->
            Bytes.Encode.unsignedInt16 BE 0

        HouseDown ->
            Bytes.Encode.unsignedInt16 BE 1

        HouseRight ->
            Bytes.Encode.unsignedInt16 BE 2

        HouseUp ->
            Bytes.Encode.unsignedInt16 BE 3

        HouseLeft ->
            Bytes.Encode.unsignedInt16 BE 4

        RailHorizontal ->
            Bytes.Encode.unsignedInt16 BE 5

        RailVertical ->
            Bytes.Encode.unsignedInt16 BE 6

        RailBottomToRight ->
            Bytes.Encode.unsignedInt16 BE 7

        RailBottomToLeft ->
            Bytes.Encode.unsignedInt16 BE 8

        RailTopToRight ->
            Bytes.Encode.unsignedInt16 BE 9

        RailTopToLeft ->
            Bytes.Encode.unsignedInt16 BE 10

        RailBottomToRightLarge ->
            Bytes.Encode.unsignedInt16 BE 11

        RailBottomToLeftLarge ->
            Bytes.Encode.unsignedInt16 BE 12

        RailTopToRightLarge ->
            Bytes.Encode.unsignedInt16 BE 13

        RailTopToLeftLarge ->
            Bytes.Encode.unsignedInt16 BE 14

        RailCrossing ->
            Bytes.Encode.unsignedInt16 BE 15

        RailStrafeDown ->
            Bytes.Encode.unsignedInt16 BE 16

        RailStrafeUp ->
            Bytes.Encode.unsignedInt16 BE 17

        RailStrafeLeft ->
            Bytes.Encode.unsignedInt16 BE 18

        RailStrafeRight ->
            Bytes.Encode.unsignedInt16 BE 19

        TrainHouseRight ->
            Bytes.Encode.unsignedInt16 BE 20

        TrainHouseLeft ->
            Bytes.Encode.unsignedInt16 BE 21

        RailStrafeDownSmall ->
            Bytes.Encode.unsignedInt16 BE 22

        RailStrafeUpSmall ->
            Bytes.Encode.unsignedInt16 BE 23

        RailStrafeLeftSmall ->
            Bytes.Encode.unsignedInt16 BE 24

        RailStrafeRightSmall ->
            Bytes.Encode.unsignedInt16 BE 25

        Sidewalk ->
            Bytes.Encode.unsignedInt16 BE 26

        SidewalkHorizontalRailCrossing ->
            Bytes.Encode.unsignedInt16 BE 27

        SidewalkVerticalRailCrossing ->
            Bytes.Encode.unsignedInt16 BE 28

        RailBottomToRight_SplitLeft ->
            Bytes.Encode.unsignedInt16 BE 29

        RailBottomToLeft_SplitUp ->
            Bytes.Encode.unsignedInt16 BE 30

        RailTopToRight_SplitDown ->
            Bytes.Encode.unsignedInt16 BE 31

        RailTopToLeft_SplitRight ->
            Bytes.Encode.unsignedInt16 BE 32

        RailBottomToRight_SplitUp ->
            Bytes.Encode.unsignedInt16 BE 33

        RailBottomToLeft_SplitRight ->
            Bytes.Encode.unsignedInt16 BE 34

        RailTopToRight_SplitLeft ->
            Bytes.Encode.unsignedInt16 BE 35

        RailTopToLeft_SplitDown ->
            Bytes.Encode.unsignedInt16 BE 36

        PostOffice ->
            Bytes.Encode.unsignedInt16 BE 37

        PineTree1 ->
            Bytes.Encode.unsignedInt16 BE 38

        PineTree2 ->
            Bytes.Encode.unsignedInt16 BE 39

        BigPineTree ->
            Bytes.Encode.unsignedInt16 BE 40

        LogCabinDown ->
            Bytes.Encode.unsignedInt16 BE 41

        LogCabinRight ->
            Bytes.Encode.unsignedInt16 BE 42

        LogCabinUp ->
            Bytes.Encode.unsignedInt16 BE 43

        LogCabinLeft ->
            Bytes.Encode.unsignedInt16 BE 44

        RoadHorizontal ->
            Bytes.Encode.unsignedInt16 BE 45

        RoadVertical ->
            Bytes.Encode.unsignedInt16 BE 46

        RoadBottomToLeft ->
            Bytes.Encode.unsignedInt16 BE 47

        RoadTopToLeft ->
            Bytes.Encode.unsignedInt16 BE 48

        RoadTopToRight ->
            Bytes.Encode.unsignedInt16 BE 49

        RoadBottomToRight ->
            Bytes.Encode.unsignedInt16 BE 50

        Road4Way ->
            Bytes.Encode.unsignedInt16 BE 51

        RoadSidewalkCrossingHorizontal ->
            Bytes.Encode.unsignedInt16 BE 52

        RoadSidewalkCrossingVertical ->
            Bytes.Encode.unsignedInt16 BE 53

        Road3WayDown ->
            Bytes.Encode.unsignedInt16 BE 54

        Road3WayLeft ->
            Bytes.Encode.unsignedInt16 BE 55

        Road3WayUp ->
            Bytes.Encode.unsignedInt16 BE 56

        Road3WayRight ->
            Bytes.Encode.unsignedInt16 BE 57

        RoadRailCrossingHorizontal ->
            Bytes.Encode.unsignedInt16 BE 58

        RoadRailCrossingVertical ->
            Bytes.Encode.unsignedInt16 BE 59

        FenceHorizontal ->
            Bytes.Encode.unsignedInt16 BE 60

        FenceVertical ->
            Bytes.Encode.unsignedInt16 BE 61

        FenceDiagonal ->
            Bytes.Encode.unsignedInt16 BE 62

        FenceAntidiagonal ->
            Bytes.Encode.unsignedInt16 BE 63

        RoadDeadendUp ->
            Bytes.Encode.unsignedInt16 BE 64

        RoadDeadendDown ->
            Bytes.Encode.unsignedInt16 BE 65

        BusStopDown ->
            Bytes.Encode.unsignedInt16 BE 66

        BusStopLeft ->
            Bytes.Encode.unsignedInt16 BE 67

        BusStopRight ->
            Bytes.Encode.unsignedInt16 BE 68

        BusStopUp ->
            Bytes.Encode.unsignedInt16 BE 69

        HospitalDown ->
            Bytes.Encode.unsignedInt16 BE 70

        Statue ->
            Bytes.Encode.unsignedInt16 BE 71

        HedgeRowDown ->
            Bytes.Encode.unsignedInt16 BE 72

        HedgeRowLeft ->
            Bytes.Encode.unsignedInt16 BE 73

        HedgeRowRight ->
            Bytes.Encode.unsignedInt16 BE 74

        HedgeRowUp ->
            Bytes.Encode.unsignedInt16 BE 75

        HedgeCornerDownLeft ->
            Bytes.Encode.unsignedInt16 BE 76

        HedgeCornerDownRight ->
            Bytes.Encode.unsignedInt16 BE 77

        HedgeCornerUpLeft ->
            Bytes.Encode.unsignedInt16 BE 78

        HedgeCornerUpRight ->
            Bytes.Encode.unsignedInt16 BE 79

        HedgePillarDownLeft ->
            Bytes.Encode.unsignedInt16 BE 80

        HedgePillarDownRight ->
            Bytes.Encode.unsignedInt16 BE 81

        HedgePillarUpLeft ->
            Bytes.Encode.unsignedInt16 BE 82

        HedgePillarUpRight ->
            Bytes.Encode.unsignedInt16 BE 83

        ApartmentDown ->
            Bytes.Encode.unsignedInt16 BE 84

        ApartmentLeft ->
            Bytes.Encode.unsignedInt16 BE 85

        ApartmentRight ->
            Bytes.Encode.unsignedInt16 BE 86

        ApartmentUp ->
            Bytes.Encode.unsignedInt16 BE 87

        RockDown ->
            Bytes.Encode.unsignedInt16 BE 88

        RockLeft ->
            Bytes.Encode.unsignedInt16 BE 89

        RockRight ->
            Bytes.Encode.unsignedInt16 BE 90

        RockUp ->
            Bytes.Encode.unsignedInt16 BE 91

        Flowers1 ->
            Bytes.Encode.unsignedInt16 BE 92

        Flowers2 ->
            Bytes.Encode.unsignedInt16 BE 93

        ElmTree ->
            Bytes.Encode.unsignedInt16 BE 94

        DirtPathHorizontal ->
            Bytes.Encode.unsignedInt16 BE 95

        DirtPathVertical ->
            Bytes.Encode.unsignedInt16 BE 96

        HyperlinkTile hyperlink ->
            Bytes.Encode.sequence
                [ Bytes.Encode.unsignedInt16 BE 97
                , Hyperlink.encoder hyperlink
                ]

        BenchDown ->
            Bytes.Encode.unsignedInt16 BE 98

        BenchLeft ->
            Bytes.Encode.unsignedInt16 BE 99

        BenchUp ->
            Bytes.Encode.unsignedInt16 BE 100

        BenchRight ->
            Bytes.Encode.unsignedInt16 BE 101

        ParkingDown ->
            Bytes.Encode.unsignedInt16 BE 102

        ParkingLeft ->
            Bytes.Encode.unsignedInt16 BE 103

        ParkingUp ->
            Bytes.Encode.unsignedInt16 BE 104

        ParkingRight ->
            Bytes.Encode.unsignedInt16 BE 105

        ParkingRoad ->
            Bytes.Encode.unsignedInt16 BE 106

        ParkingRoundabout ->
            Bytes.Encode.unsignedInt16 BE 107

        CornerHouseUpLeft ->
            Bytes.Encode.unsignedInt16 BE 108

        CornerHouseUpRight ->
            Bytes.Encode.unsignedInt16 BE 109

        CornerHouseDownLeft ->
            Bytes.Encode.unsignedInt16 BE 110

        CornerHouseDownRight ->
            Bytes.Encode.unsignedInt16 BE 111

        DogHouseDown ->
            Bytes.Encode.unsignedInt16 BE 112

        DogHouseRight ->
            Bytes.Encode.unsignedInt16 BE 113

        DogHouseUp ->
            Bytes.Encode.unsignedInt16 BE 114

        DogHouseLeft ->
            Bytes.Encode.unsignedInt16 BE 115

        Mushroom1 ->
            Bytes.Encode.unsignedInt16 BE 116

        Mushroom2 ->
            Bytes.Encode.unsignedInt16 BE 117

        TreeStump1 ->
            Bytes.Encode.unsignedInt16 BE 118

        TreeStump2 ->
            Bytes.Encode.unsignedInt16 BE 119

        Sunflowers ->
            Bytes.Encode.unsignedInt16 BE 120

        RailDeadEndLeft ->
            Bytes.Encode.unsignedInt16 BE 121

        RailDeadEndRight ->
            Bytes.Encode.unsignedInt16 BE 122

        RailStrafeLeftToRight_SplitUp ->
            Bytes.Encode.unsignedInt16 BE 123

        RailStrafeLeftToRight_SplitDown ->
            Bytes.Encode.unsignedInt16 BE 124

        RailStrafeRightToLeft_SplitUp ->
            Bytes.Encode.unsignedInt16 BE 125

        RailStrafeRightToLeft_SplitDown ->
            Bytes.Encode.unsignedInt16 BE 126

        RailStrafeTopToBottom_SplitLeft ->
            Bytes.Encode.unsignedInt16 BE 127

        RailStrafeTopToBottom_SplitRight ->
            Bytes.Encode.unsignedInt16 BE 128

        RailStrafeBottomToTop_SplitLeft ->
            Bytes.Encode.unsignedInt16 BE 129

        RailStrafeBottomToTop_SplitRight ->
            Bytes.Encode.unsignedInt16 BE 130

        RoadManholeDown ->
            Bytes.Encode.unsignedInt16 BE 131

        RoadManholeLeft ->
            Bytes.Encode.unsignedInt16 BE 132

        RoadManholeUp ->
            Bytes.Encode.unsignedInt16 BE 133

        RoadManholeRight ->
            Bytes.Encode.unsignedInt16 BE 134

        BerryBush1 ->
            Bytes.Encode.unsignedInt16 BE 135

        BerryBush2 ->
            Bytes.Encode.unsignedInt16 BE 136

        SmallHouseDown ->
            Bytes.Encode.unsignedInt16 BE 137

        SmallHouseLeft ->
            Bytes.Encode.unsignedInt16 BE 138

        SmallHouseUp ->
            Bytes.Encode.unsignedInt16 BE 139

        SmallHouseRight ->
            Bytes.Encode.unsignedInt16 BE 140

        OfficeDown ->
            Bytes.Encode.unsignedInt16 BE 141

        OfficeUp ->
            Bytes.Encode.unsignedInt16 BE 142

        FireTruckGarage ->
            Bytes.Encode.unsignedInt16 BE 143

        TownHouse0 ->
            Bytes.Encode.unsignedInt16 BE 144

        RowHouse0 ->
            Bytes.Encode.unsignedInt16 BE 145

        TownHouse1 ->
            Bytes.Encode.unsignedInt16 BE 146

        TownHouse2 ->
            Bytes.Encode.unsignedInt16 BE 147

        TownHouse3 ->
            Bytes.Encode.unsignedInt16 BE 148

        TownHouse4 ->
            Bytes.Encode.unsignedInt16 BE 149

        HospitalLeft ->
            Bytes.Encode.unsignedInt16 BE 150

        HospitalUp ->
            Bytes.Encode.unsignedInt16 BE 151

        HospitalRight ->
            Bytes.Encode.unsignedInt16 BE 152

        RowHouse1 ->
            Bytes.Encode.unsignedInt16 BE 153

        RowHouse2 ->
            Bytes.Encode.unsignedInt16 BE 154

        RowHouse3 ->
            Bytes.Encode.unsignedInt16 BE 155

        WideParkingDown ->
            Bytes.Encode.unsignedInt16 BE 156

        WideParkingLeft ->
            Bytes.Encode.unsignedInt16 BE 157

        WideParkingUp ->
            Bytes.Encode.unsignedInt16 BE 158

        WideParkingRight ->
            Bytes.Encode.unsignedInt16 BE 159

        Gazebo ->
            Bytes.Encode.unsignedInt16 BE 160

        ConvenienceStoreDown ->
            Bytes.Encode.unsignedInt16 BE 161

        ConvenienceStoreUp ->
            Bytes.Encode.unsignedInt16 BE 162

        BeautySalonDown ->
            Bytes.Encode.unsignedInt16 BE 163

        BeautySalonUp ->
            Bytes.Encode.unsignedInt16 BE 164

        CheckmartDown ->
            Bytes.Encode.unsignedInt16 BE 165

        CheckmartUp ->
            Bytes.Encode.unsignedInt16 BE 166

        TreeStoreDown ->
            Bytes.Encode.unsignedInt16 BE 167

        TreeStoreUp ->
            Bytes.Encode.unsignedInt16 BE 168

        IronFenceHorizontal ->
            Bytes.Encode.unsignedInt16 BE 169

        IronFenceDiagonal ->
            Bytes.Encode.unsignedInt16 BE 170

        IronFenceVertical ->
            Bytes.Encode.unsignedInt16 BE 171

        IronFenceAntidiagonal ->
            Bytes.Encode.unsignedInt16 BE 172

        IronGate ->
            Bytes.Encode.unsignedInt16 BE 173

        DeadTree ->
            Bytes.Encode.unsignedInt16 BE 174


decoder : Bytes.Decode.Decoder Tile
decoder =
    Bytes.Decode.andThen
        (\int ->
            case int of
                0 ->
                    Bytes.Decode.succeed EmptyTile

                1 ->
                    Bytes.Decode.succeed HouseDown

                2 ->
                    Bytes.Decode.succeed HouseRight

                3 ->
                    Bytes.Decode.succeed HouseUp

                4 ->
                    Bytes.Decode.succeed HouseLeft

                5 ->
                    Bytes.Decode.succeed RailHorizontal

                6 ->
                    Bytes.Decode.succeed RailVertical

                7 ->
                    Bytes.Decode.succeed RailBottomToRight

                8 ->
                    Bytes.Decode.succeed RailBottomToLeft

                9 ->
                    Bytes.Decode.succeed RailTopToRight

                10 ->
                    Bytes.Decode.succeed RailTopToLeft

                11 ->
                    Bytes.Decode.succeed RailBottomToRightLarge

                12 ->
                    Bytes.Decode.succeed RailBottomToLeftLarge

                13 ->
                    Bytes.Decode.succeed RailTopToRightLarge

                14 ->
                    Bytes.Decode.succeed RailTopToLeftLarge

                15 ->
                    Bytes.Decode.succeed RailCrossing

                16 ->
                    Bytes.Decode.succeed RailStrafeDown

                17 ->
                    Bytes.Decode.succeed RailStrafeUp

                18 ->
                    Bytes.Decode.succeed RailStrafeLeft

                19 ->
                    Bytes.Decode.succeed RailStrafeRight

                20 ->
                    Bytes.Decode.succeed TrainHouseRight

                21 ->
                    Bytes.Decode.succeed TrainHouseLeft

                22 ->
                    Bytes.Decode.succeed RailStrafeDownSmall

                23 ->
                    Bytes.Decode.succeed RailStrafeUpSmall

                24 ->
                    Bytes.Decode.succeed RailStrafeLeftSmall

                25 ->
                    Bytes.Decode.succeed RailStrafeRightSmall

                26 ->
                    Bytes.Decode.succeed Sidewalk

                27 ->
                    Bytes.Decode.succeed SidewalkHorizontalRailCrossing

                28 ->
                    Bytes.Decode.succeed SidewalkVerticalRailCrossing

                29 ->
                    Bytes.Decode.succeed RailBottomToRight_SplitLeft

                30 ->
                    Bytes.Decode.succeed RailBottomToLeft_SplitUp

                31 ->
                    Bytes.Decode.succeed RailTopToRight_SplitDown

                32 ->
                    Bytes.Decode.succeed RailTopToLeft_SplitRight

                33 ->
                    Bytes.Decode.succeed RailBottomToRight_SplitUp

                34 ->
                    Bytes.Decode.succeed RailBottomToLeft_SplitRight

                35 ->
                    Bytes.Decode.succeed RailTopToRight_SplitLeft

                36 ->
                    Bytes.Decode.succeed RailTopToLeft_SplitDown

                37 ->
                    Bytes.Decode.succeed PostOffice

                38 ->
                    Bytes.Decode.succeed PineTree1

                39 ->
                    Bytes.Decode.succeed PineTree2

                40 ->
                    Bytes.Decode.succeed BigPineTree

                41 ->
                    Bytes.Decode.succeed LogCabinDown

                42 ->
                    Bytes.Decode.succeed LogCabinRight

                43 ->
                    Bytes.Decode.succeed LogCabinUp

                44 ->
                    Bytes.Decode.succeed LogCabinLeft

                45 ->
                    Bytes.Decode.succeed RoadHorizontal

                46 ->
                    Bytes.Decode.succeed RoadVertical

                47 ->
                    Bytes.Decode.succeed RoadBottomToLeft

                48 ->
                    Bytes.Decode.succeed RoadTopToLeft

                49 ->
                    Bytes.Decode.succeed RoadTopToRight

                50 ->
                    Bytes.Decode.succeed RoadBottomToRight

                51 ->
                    Bytes.Decode.succeed Road4Way

                52 ->
                    Bytes.Decode.succeed RoadSidewalkCrossingHorizontal

                53 ->
                    Bytes.Decode.succeed RoadSidewalkCrossingVertical

                54 ->
                    Bytes.Decode.succeed Road3WayDown

                55 ->
                    Bytes.Decode.succeed Road3WayLeft

                56 ->
                    Bytes.Decode.succeed Road3WayUp

                57 ->
                    Bytes.Decode.succeed Road3WayRight

                58 ->
                    Bytes.Decode.succeed RoadRailCrossingHorizontal

                59 ->
                    Bytes.Decode.succeed RoadRailCrossingVertical

                60 ->
                    Bytes.Decode.succeed FenceHorizontal

                61 ->
                    Bytes.Decode.succeed FenceVertical

                62 ->
                    Bytes.Decode.succeed FenceDiagonal

                63 ->
                    Bytes.Decode.succeed FenceAntidiagonal

                64 ->
                    Bytes.Decode.succeed RoadDeadendUp

                65 ->
                    Bytes.Decode.succeed RoadDeadendDown

                66 ->
                    Bytes.Decode.succeed BusStopDown

                67 ->
                    Bytes.Decode.succeed BusStopLeft

                68 ->
                    Bytes.Decode.succeed BusStopRight

                69 ->
                    Bytes.Decode.succeed BusStopUp

                70 ->
                    Bytes.Decode.succeed HospitalDown

                71 ->
                    Bytes.Decode.succeed Statue

                72 ->
                    Bytes.Decode.succeed HedgeRowDown

                73 ->
                    Bytes.Decode.succeed HedgeRowLeft

                74 ->
                    Bytes.Decode.succeed HedgeRowRight

                75 ->
                    Bytes.Decode.succeed HedgeRowUp

                76 ->
                    Bytes.Decode.succeed HedgeCornerDownLeft

                77 ->
                    Bytes.Decode.succeed HedgeCornerDownRight

                78 ->
                    Bytes.Decode.succeed HedgeCornerUpLeft

                79 ->
                    Bytes.Decode.succeed HedgeCornerUpRight

                80 ->
                    Bytes.Decode.succeed HedgePillarDownLeft

                81 ->
                    Bytes.Decode.succeed HedgePillarDownRight

                82 ->
                    Bytes.Decode.succeed HedgePillarUpLeft

                83 ->
                    Bytes.Decode.succeed HedgePillarUpRight

                84 ->
                    Bytes.Decode.succeed ApartmentDown

                85 ->
                    Bytes.Decode.succeed ApartmentLeft

                86 ->
                    Bytes.Decode.succeed ApartmentRight

                87 ->
                    Bytes.Decode.succeed ApartmentUp

                88 ->
                    Bytes.Decode.succeed RockDown

                89 ->
                    Bytes.Decode.succeed RockLeft

                90 ->
                    Bytes.Decode.succeed RockRight

                91 ->
                    Bytes.Decode.succeed RockUp

                92 ->
                    Bytes.Decode.succeed Flowers1

                93 ->
                    Bytes.Decode.succeed Flowers2

                94 ->
                    Bytes.Decode.succeed ElmTree

                95 ->
                    Bytes.Decode.succeed DirtPathHorizontal

                96 ->
                    Bytes.Decode.succeed DirtPathVertical

                97 ->
                    Bytes.Decode.map HyperlinkTile Hyperlink.decoder

                98 ->
                    Bytes.Decode.succeed BenchDown

                99 ->
                    Bytes.Decode.succeed BenchLeft

                100 ->
                    Bytes.Decode.succeed BenchUp

                101 ->
                    Bytes.Decode.succeed BenchRight

                102 ->
                    Bytes.Decode.succeed ParkingDown

                103 ->
                    Bytes.Decode.succeed ParkingLeft

                104 ->
                    Bytes.Decode.succeed ParkingUp

                105 ->
                    Bytes.Decode.succeed ParkingRight

                106 ->
                    Bytes.Decode.succeed ParkingRoad

                107 ->
                    Bytes.Decode.succeed ParkingRoundabout

                108 ->
                    Bytes.Decode.succeed CornerHouseUpLeft

                109 ->
                    Bytes.Decode.succeed CornerHouseUpRight

                110 ->
                    Bytes.Decode.succeed CornerHouseDownLeft

                111 ->
                    Bytes.Decode.succeed CornerHouseDownRight

                112 ->
                    Bytes.Decode.succeed DogHouseDown

                113 ->
                    Bytes.Decode.succeed DogHouseRight

                114 ->
                    Bytes.Decode.succeed DogHouseUp

                115 ->
                    Bytes.Decode.succeed DogHouseLeft

                116 ->
                    Bytes.Decode.succeed Mushroom1

                117 ->
                    Bytes.Decode.succeed Mushroom2

                118 ->
                    Bytes.Decode.succeed TreeStump1

                119 ->
                    Bytes.Decode.succeed TreeStump2

                120 ->
                    Bytes.Decode.succeed Sunflowers

                121 ->
                    Bytes.Decode.succeed RailDeadEndLeft

                122 ->
                    Bytes.Decode.succeed RailDeadEndRight

                123 ->
                    Bytes.Decode.succeed RailStrafeLeftToRight_SplitUp

                124 ->
                    Bytes.Decode.succeed RailStrafeLeftToRight_SplitDown

                125 ->
                    Bytes.Decode.succeed RailStrafeRightToLeft_SplitUp

                126 ->
                    Bytes.Decode.succeed RailStrafeRightToLeft_SplitDown

                127 ->
                    Bytes.Decode.succeed RailStrafeTopToBottom_SplitLeft

                128 ->
                    Bytes.Decode.succeed RailStrafeTopToBottom_SplitRight

                129 ->
                    Bytes.Decode.succeed RailStrafeBottomToTop_SplitLeft

                130 ->
                    Bytes.Decode.succeed RailStrafeBottomToTop_SplitRight

                131 ->
                    Bytes.Decode.succeed RoadManholeDown

                132 ->
                    Bytes.Decode.succeed RoadManholeLeft

                133 ->
                    Bytes.Decode.succeed RoadManholeUp

                134 ->
                    Bytes.Decode.succeed RoadManholeRight

                135 ->
                    Bytes.Decode.succeed BerryBush1

                136 ->
                    Bytes.Decode.succeed BerryBush2

                137 ->
                    Bytes.Decode.succeed SmallHouseDown

                138 ->
                    Bytes.Decode.succeed SmallHouseLeft

                139 ->
                    Bytes.Decode.succeed SmallHouseUp

                140 ->
                    Bytes.Decode.succeed SmallHouseRight

                141 ->
                    Bytes.Decode.succeed OfficeDown

                142 ->
                    Bytes.Decode.succeed OfficeUp

                143 ->
                    Bytes.Decode.succeed FireTruckGarage

                144 ->
                    Bytes.Decode.succeed TownHouse0

                145 ->
                    Bytes.Decode.succeed RowHouse0

                146 ->
                    Bytes.Decode.succeed TownHouse1

                147 ->
                    Bytes.Decode.succeed TownHouse2

                148 ->
                    Bytes.Decode.succeed TownHouse3

                149 ->
                    Bytes.Decode.succeed TownHouse4

                150 ->
                    Bytes.Decode.succeed HospitalLeft

                151 ->
                    Bytes.Decode.succeed HospitalUp

                152 ->
                    Bytes.Decode.succeed HospitalRight

                153 ->
                    Bytes.Decode.succeed RowHouse1

                154 ->
                    Bytes.Decode.succeed RowHouse2

                155 ->
                    Bytes.Decode.succeed RowHouse3

                156 ->
                    Bytes.Decode.succeed WideParkingDown

                157 ->
                    Bytes.Decode.succeed WideParkingLeft

                158 ->
                    Bytes.Decode.succeed WideParkingUp

                159 ->
                    Bytes.Decode.succeed WideParkingRight

                160 ->
                    Bytes.Decode.succeed Gazebo

                161 ->
                    Bytes.Decode.succeed ConvenienceStoreDown

                162 ->
                    Bytes.Decode.succeed ConvenienceStoreUp

                163 ->
                    Bytes.Decode.succeed BeautySalonDown

                164 ->
                    Bytes.Decode.succeed BeautySalonUp

                165 ->
                    Bytes.Decode.succeed CheckmartDown

                166 ->
                    Bytes.Decode.succeed CheckmartUp

                167 ->
                    Bytes.Decode.succeed TreeStoreDown

                168 ->
                    Bytes.Decode.succeed TreeStoreUp

                169 ->
                    Bytes.Decode.succeed IronFenceHorizontal

                170 ->
                    Bytes.Decode.succeed IronFenceDiagonal

                171 ->
                    Bytes.Decode.succeed IronFenceVertical

                172 ->
                    Bytes.Decode.succeed IronFenceAntidiagonal

                173 ->
                    Bytes.Decode.succeed IronGate

                174 ->
                    Bytes.Decode.succeed DeadTree

                _ ->
                    case Array.get (maxTileValue - int) Sprite.intToChar of
                        Just char ->
                            BigText char |> Bytes.Decode.succeed

                        Nothing ->
                            BigText '?' |> Bytes.Decode.succeed
        )
        (Bytes.Decode.unsignedInt16 BE)


maxTileValue : number
maxTileValue =
    (2 ^ 16) - 1
