module Evergreen.V107.Tile exposing (..)


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


type RailPath
    = RailPathHorizontal
        { offsetX : Int
        , offsetY : Int
        , length : Int
        }
    | RailPathVertical
        { offsetX : Int
        , offsetY : Int
        , length : Int
        }
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


type Category
    = Scenery
    | Buildings
    | Rail
    | Road
