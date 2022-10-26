module Train exposing (Train, moveTrain)

import Angle
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import Grid exposing (Grid)
import GridCell
import Point2d exposing (Point2d)
import Quantity exposing (Quantity)
import Tile exposing (Direction, RailData, RailPath, RailPathType(..), Tile)
import Units exposing (CellLocalUnit, CellUnit, TileLocalUnit, WorldUnit)
import Vector2d


type alias Train =
    { position : Coord WorldUnit, path : RailPath, t : Float, speed : Quantity Float TileLocalUnit }


moveTrain : Grid -> Train -> Train
moveTrain grid train =
    moveTrainHelper train.speed grid train


moveTrainHelper : Quantity Float TileLocalUnit -> Grid -> Train -> Train
moveTrainHelper distanceLeft grid train =
    let
        { path, distanceToT, tToDistance, startExitDirection, endExitDirection } =
            Tile.railPathData train.path

        currentDistance =
            tToDistance train.t

        newT =
            Quantity.plus distanceLeft currentDistance |> distanceToT
    in
    if newT < 0 || newT > 1 then
        let
            newT2 =
                clamp 0 1 newT

            distanceTravelled : Quantity Float TileLocalUnit
            distanceTravelled =
                tToDistance newT2 |> Quantity.minus currentDistance

            position : Point2d WorldUnit WorldUnit
            position =
                path newT2 |> Grid.localTilePointPlusWorld train.position

            ( cellPos, localPos ) =
                Grid.worldToCellAndLocalPoint position
        in
        case
            findNextTile
                position
                grid
                train
                (if newT2 == 1 then
                    endExitDirection

                 else
                    startExitDirection
                )
                (( cellPos, Coord.floorPoint localPos )
                    :: Grid.closeNeighborCells cellPos (Coord.floorPoint localPos)
                )
        of
            Just newTrain ->
                moveTrainHelper (distanceLeft |> Quantity.minus distanceTravelled) grid newTrain

            Nothing ->
                { train | t = newT2 }

    else
        { train | t = newT }


findNextTile :
    Point2d WorldUnit WorldUnit
    -> Grid
    -> Train
    -> Direction
    -> List ( Coord CellUnit, Coord CellLocalUnit )
    -> Maybe Train
findNextTile position grid train direction list =
    case list of
        ( neighborCellPos, _ ) :: rest ->
            case Grid.getCell neighborCellPos grid of
                Just cell ->
                    case findNextTileHelper neighborCellPos position train direction (GridCell.flatten cell) of
                        Just newTrain ->
                            Just newTrain

                        Nothing ->
                            findNextTile position grid train direction rest

                Nothing ->
                    findNextTile position grid train direction rest

        [] ->
            Nothing


findNextTileHelper :
    Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Train
    -> Direction
    -> List { b | position : Coord CellLocalUnit, value : Tile }
    -> Maybe Train
findNextTileHelper neighborCellPos position train direction tiles =
    case tiles of
        tile :: rest ->
            let
                maybeNewTrain =
                    List.filterMap
                        (checkPath tile neighborCellPos position train.speed direction)
                        (case Tile.getData tile.value |> .railPath of
                            NoRailPath ->
                                []

                            SingleRailPath path1 ->
                                [ path1 ]

                            DoubleRailPath path1 path2 ->
                                [ path1, path2 ]
                        )
                        |> List.head
            in
            case maybeNewTrain of
                Just newTrain ->
                    Just newTrain

                Nothing ->
                    findNextTileHelper neighborCellPos position train direction rest

        [] ->
            Nothing


checkPath tile neighborCellPos position speed direction railPath =
    let
        railData : RailData
        railData =
            Tile.railPathData railPath

        worldPoint0 : Point2d WorldUnit WorldUnit
        worldPoint0 =
            Grid.cellAndLocalPointToWorld
                neighborCellPos
                (Grid.localTilePointPlusCellLocalCoord tile.position (railData.path 0))

        validDirection0 =
            Tile.reverseDirection direction == railData.startExitDirection

        worldPoint1 : Point2d WorldUnit WorldUnit
        worldPoint1 =
            Grid.cellAndLocalPointToWorld
                neighborCellPos
                (Grid.localTilePointPlusCellLocalCoord tile.position (railData.path 1))

        validDirection1 =
            Tile.reverseDirection direction == railData.endExitDirection
    in
    if (Point2d.distanceFrom worldPoint0 position |> Quantity.lessThan (Units.tileUnit 0.1)) && validDirection0 then
        { position =
            Grid.cellAndLocalCoordToAscii ( neighborCellPos, tile.position )
        , t = 0
        , speed = Quantity.abs speed
        , path = railPath
        }
            |> Just

    else if (Point2d.distanceFrom worldPoint1 position |> Quantity.lessThan (Units.tileUnit 0.1)) && validDirection1 then
        { position =
            Grid.cellAndLocalCoordToAscii ( neighborCellPos, tile.position )
        , t = 1
        , speed = Quantity.abs speed |> Quantity.negate
        , path = railPath
        }
            |> Just

    else
        Nothing
