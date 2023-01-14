module Evergreen.V45.Tile exposing (..)


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
