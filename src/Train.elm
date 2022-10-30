module Train exposing (Train, actualPosition, maxSpeed, moveTrain)

import AssocList
import Coord exposing (Coord)
import Duration exposing (Duration, Seconds)
import Grid exposing (Grid)
import GridCell
import Id exposing (Id, MailId, UserId)
import Mail exposing (MailStatus(..))
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Tile exposing (Direction, RailData, RailPath, RailPathType(..), Tile(..))
import Time
import Units exposing (CellLocalUnit, CellUnit, TileLocalUnit, WorldUnit)


type alias Train =
    { position : Coord WorldUnit
    , path : RailPath
    , t : Float
    , speed : Quantity Float (Rate TileLocalUnit Seconds)
    , stoppedAtPostOffice : Maybe { time : Time.Posix, userId : Id UserId }
    }


actualPosition : Train -> Point2d WorldUnit WorldUnit
actualPosition train =
    let
        { path } =
            Tile.railPathData train.path
    in
    Grid.localTilePointPlusWorld train.position (path train.t)


acceleration =
    1


maxSpeed =
    5


moveTrain :
    Time.Posix
    -> Time.Posix
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, sender : Id UserId } }
    -> Train
    -> Train
moveTrain startTime endTime state train =
    let
        timeElapsed_ =
            Duration.inSeconds (Duration.from startTime endTime)

        trainSpeed =
            Quantity.unwrap train.speed

        newSpeed =
            (if trainSpeed > 0 then
                trainSpeed + acceleration * timeElapsed_

             else
                trainSpeed - acceleration * timeElapsed_
            )
                |> clamp -maxSpeed maxSpeed

        timeUntilMaxSpeed =
            (maxSpeed - abs trainSpeed) / acceleration

        distance =
            (if timeUntilMaxSpeed > timeElapsed_ then
                abs (trainSpeed * timeElapsed_)
                    + (0.5 * acceleration * timeElapsed_ ^ 2)

             else
                abs (trainSpeed * timeUntilMaxSpeed)
                    + (0.5 * acceleration * timeUntilMaxSpeed ^ 2)
                    + ((timeElapsed_ - timeUntilMaxSpeed) * maxSpeed)
            )
                |> Quantity
    in
    moveTrainHelper startTime distance state { train | speed = Quantity newSpeed }


moveTrainHelper :
    Time.Posix
    -> Quantity Float TileLocalUnit
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, sender : Id UserId } }
    -> Train
    -> Train
moveTrainHelper time distanceLeft state train =
    let
        { path, distanceToT, tToDistance, startExitDirection, endExitDirection } =
            Tile.railPathData train.path

        currentDistance =
            tToDistance train.t

        newT =
            Quantity.plus
                (if Quantity.lessThanZero train.speed then
                    Quantity.negate distanceLeft

                 else
                    distanceLeft
                )
                currentDistance
                |> distanceToT

        newTClamped =
            clamp 0 1 newT

        reachedTileEnd () =
            let
                distanceTravelled : Quantity Float TileLocalUnit
                distanceTravelled =
                    tToDistance newTClamped |> Quantity.minus currentDistance |> Quantity.abs

                position : Point2d WorldUnit WorldUnit
                position =
                    path newTClamped |> Grid.localTilePointPlusWorld train.position

                ( cellPos, localPos ) =
                    Grid.worldToCellAndLocalPoint position
            in
            case
                findNextTile
                    time
                    position
                    state
                    train.speed
                    (if newTClamped == 1 then
                        endExitDirection

                     else
                        startExitDirection
                    )
                    (( cellPos, Coord.floorPoint localPos )
                        :: Grid.closeNeighborCells cellPos (Coord.floorPoint localPos)
                    )
            of
                Just newTrain ->
                    moveTrainHelper time (distanceLeft |> Quantity.minus distanceTravelled) state newTrain

                Nothing ->
                    { train
                        | t = newTClamped
                        , speed =
                            if Quantity.lessThanZero train.speed then
                                Quantity -0.1

                            else
                                Quantity 0.1
                    }
    in
    case train.stoppedAtPostOffice of
        Just stoppedAtPostOffice ->
            if newT < 0 || newT > 1 then
                if Duration.from stoppedAtPostOffice.time time |> Quantity.greaterThan (Duration.seconds 3) then
                    reachedTileEnd ()

                else
                    { train
                        | t = newTClamped
                        , speed =
                            if Quantity.lessThanZero train.speed then
                                Quantity -0.1

                            else
                                Quantity 0.1
                    }

            else
                { train | t = newTClamped }

        Nothing ->
            if newT < 0 || newT > 1 then
                reachedTileEnd ()

            else
                { train | t = newTClamped }


findNextTile :
    Time.Posix
    -> Point2d WorldUnit WorldUnit
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, sender : Id UserId } }
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> List ( Coord CellUnit, Coord CellLocalUnit )
    -> Maybe Train
findNextTile time position state speed direction list =
    case list of
        ( neighborCellPos, _ ) :: rest ->
            case Grid.getCell neighborCellPos state.grid of
                Just cell ->
                    case findNextTileHelper time neighborCellPos position speed direction state (GridCell.flatten cell) of
                        Just newTrain ->
                            Just newTrain

                        Nothing ->
                            findNextTile time position state speed direction rest

                Nothing ->
                    findNextTile time position state speed direction rest

        [] ->
            Nothing


findNextTileHelper :
    Time.Posix
    -> Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, sender : Id UserId } }
    -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> Maybe Train
findNextTileHelper time neighborCellPos position speed direction state tiles =
    case tiles of
        tile :: rest ->
            let
                maybeNewTrain =
                    List.filterMap
                        (checkPath time tile state.mail neighborCellPos position speed direction)
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
                    findNextTileHelper time neighborCellPos position speed direction state rest

        [] ->
            Nothing


checkPath :
    Time.Posix
    -> { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> AssocList.Dict (Id MailId) { a | status : MailStatus, sender : Id UserId }
    -> Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> RailPath
    -> Maybe Train
checkPath time tile mail neighborCellPos position speed direction railPath =
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

        stoppedAtPostOffice () =
            if
                (tile.value == PostOffice)
                    && List.any
                        (\mail_ -> tile.userId == mail_.sender && mail_.status == MailWaitingPickup)
                        (AssocList.values mail)
            then
                Just { time = time, userId = tile.userId }

            else
                Nothing
    in
    if (Point2d.distanceFrom worldPoint0 position |> Quantity.lessThan (Units.tileUnit 0.1)) && validDirection0 then
        { position =
            Grid.cellAndLocalCoordToAscii ( neighborCellPos, tile.position )
        , t = 0
        , speed = Quantity.abs speed
        , path = railPath
        , stoppedAtPostOffice = stoppedAtPostOffice ()
        }
            |> Just

    else if (Point2d.distanceFrom worldPoint1 position |> Quantity.lessThan (Units.tileUnit 0.1)) && validDirection1 then
        { position =
            Grid.cellAndLocalCoordToAscii ( neighborCellPos, tile.position )
        , t = 1
        , speed = Quantity.abs speed |> Quantity.negate
        , path = railPath
        , stoppedAtPostOffice = stoppedAtPostOffice ()
        }
            |> Just

    else
        Nothing
