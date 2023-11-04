module Train exposing
    ( Coach
    , FieldChanged(..)
    , IsStuckOrDerailed(..)
    , PreviousPath
    , Status(..)
    , Train(..)
    , TrainDiff(..)
    , applyDiff
    , canRemoveTiles
    , carryingMail
    , defaultMaxSpeed
    , diff
    , draw
    , drawSpeechBubble
    , handleAddingTrain
    , home
    , homePath
    , instancedMesh
    , leaveHome
    , moveTrains
    , nextId
    , owner
    , speed
    , startTeleportingHome
    , status
    , stoppedSpeed
    , stuckMessageDelay
    , stuckOrDerailed
    , trainPosition
    )

import Angle
import Array exposing (Array)
import AssocSet
import BoundingBox2d exposing (BoundingBox2d)
import CollisionLookup exposing (CollisionLookup)
import Color exposing (Color)
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import Duration exposing (Duration, Seconds)
import Effect.Time
import Effect.WebGL
import Effect.WebGL.Settings.DepthTest
import Grid exposing (Grid)
import GridCell
import Id exposing (Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import List.Extra as List
import MailEditor exposing (FrontendMail, MailStatus(..))
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Shaders exposing (InstancedVertex, RenderData)
import Sprite exposing (Vertex)
import Tile exposing (Direction, RailData, RailPath, RailPathType(..), Tile(..))
import Units exposing (CellLocalUnit, CellUnit, TileLocalUnit, WorldUnit)
import WebGL.Texture


type Status
    = WaitingAtHome
    | TeleportingHome Effect.Time.Posix
    | Travelling
    | StoppedAtPostOffice { time : Effect.Time.Posix, userId : Id UserId }


type Train
    = Train
        { position : Coord WorldUnit
        , path : RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity Float (Rate TileLocalUnit Seconds)
        , home : Coord WorldUnit
        , homePath : RailPath
        , isStuckOrDerailed : IsStuckOrDerailed
        , status : Status
        , owner : Id UserId
        , color : Color
        }


type IsStuckOrDerailed
    = IsStuck Effect.Time.Posix
    | IsDerailed Effect.Time.Posix (Id TrainId)
    | IsNotStuckOrDerailed


type TrainDiff
    = NewTrain Train
    | TrainChanged
        { position :
            FieldChanged
                { position : Coord WorldUnit
                , path : RailPath
                , previousPaths : List PreviousPath
                , t : Float
                , speed : Quantity Float (Rate TileLocalUnit Seconds)
                }
        , isStuckOrDerailed : FieldChanged IsStuckOrDerailed
        , status : FieldChanged Status
        }


diff : Train -> Train -> TrainDiff
diff (Train trainOld) (Train trainNew) =
    TrainChanged
        { position =
            diffField
                { position = trainOld.position
                , path = trainOld.path
                , previousPaths = trainOld.previousPaths
                , t = trainOld.t
                , speed = trainOld.speed
                }
                { position = trainNew.position
                , path = trainNew.path
                , previousPaths = trainNew.previousPaths
                , t = trainNew.t
                , speed = trainNew.speed
                }
        , isStuckOrDerailed = diffField trainOld.isStuckOrDerailed trainNew.isStuckOrDerailed
        , status = diffField trainOld.status trainNew.status
        }


trainColor : Train -> Color
trainColor (Train train) =
    train.color


applyDiff : TrainDiff -> Maybe Train -> Maybe Train
applyDiff trainDiff maybeTrain =
    case ( trainDiff, maybeTrain ) of
        ( NewTrain newTrain, _ ) ->
            Just newTrain

        ( TrainChanged diff_, Just (Train train) ) ->
            let
                position =
                    applyDiffField
                        diff_.position
                        { position = train.position
                        , path = train.path
                        , previousPaths = train.previousPaths
                        , t = train.t
                        , speed = train.speed
                        }
            in
            { train
                | position = position.position
                , path = position.path
                , previousPaths = position.previousPaths
                , t = position.t
                , speed = position.speed
                , isStuckOrDerailed = applyDiffField diff_.isStuckOrDerailed train.isStuckOrDerailed
                , status = applyDiffField diff_.status train.status
            }
                |> Train
                |> Just

        ( TrainChanged _, Nothing ) ->
            Nothing


diffField : a -> a -> FieldChanged a
diffField old new =
    --if old == new then
    --    Unchanged
    --
    --else
    FieldChanged new


applyDiffField : FieldChanged a -> a -> a
applyDiffField fieldChanged old =
    case fieldChanged of
        FieldChanged new ->
            new


type FieldChanged a
    = FieldChanged a


type alias PreviousPath =
    { position : Coord WorldUnit, path : RailPath, reversed : Bool }


type alias TrainData =
    { position : Coord WorldUnit
    , path : RailPath
    , t : Float
    , speed : Quantity Float (Rate TileLocalUnit Seconds)
    , stoppedAtPostOffice : Maybe { time : Effect.Time.Posix, userId : Id UserId }
    }


type alias CoachData =
    { position : Coord WorldUnit
    , path : RailPath
    , previousPaths : List PreviousPath
    , t : Float
    , speed : Quantity Float (Rate TileLocalUnit Seconds)
    }


type alias Coach =
    { position : Point2d WorldUnit WorldUnit
    , direction : Direction2d WorldUnit
    }


getCoach : Effect.Time.Posix -> Train -> Coach
getCoach time (Train train) =
    let
        coach : CoachData
        coach =
            moveCoachHelper
                (Quantity 1.9)
                False
                { position = train.position
                , path = train.path
                , previousPaths = train.previousPaths
                , t = train.t
                , speed = Quantity.negate train.speed
                }

        railData =
            Tile.railPathData coach.path

        position =
            Grid.localTilePointPlusWorld coach.position (railData.path coach.t)

        direction =
            Tile.pathDirection railData.path coach.t
                |> (if Quantity.lessThanZero (speed time (Train train)) then
                        Direction2d.reverse

                    else
                        identity
                   )
                |> Direction2d.unwrap
                |> Direction2d.unsafe
    in
    { position =
        case train.isStuckOrDerailed of
            IsDerailed derailTime _ ->
                derailOffset derailTime time direction position

            IsStuck _ ->
                position

            IsNotStuckOrDerailed ->
                position
    , direction = direction
    }


derail : Effect.Time.Posix -> Id TrainId -> Train -> Train
derail time otherTrainId (Train train) =
    (case train.isStuckOrDerailed of
        IsDerailed _ _ ->
            train

        _ ->
            { train | isStuckOrDerailed = IsDerailed time otherTrainId }
    )
        |> Train


trainPosition : Effect.Time.Posix -> Train -> Point2d WorldUnit WorldUnit
trainPosition time (Train train) =
    case status time (Train train) of
        Travelling ->
            travellingPosition time (Train train)

        WaitingAtHome ->
            let
                railPath =
                    Tile.railPathData train.homePath
            in
            Grid.localTilePointPlusWorld train.home (railPath.path 0.5)

        TeleportingHome _ ->
            travellingPosition time (Train train)

        StoppedAtPostOffice _ ->
            travellingPosition time (Train train)


travellingPosition :
    Effect.Time.Posix
    -> Train
    -> Point2d WorldUnit WorldUnit
travellingPosition time (Train train) =
    let
        railData : RailData
        railData =
            Tile.railPathData train.path

        position =
            Grid.localTilePointPlusWorld train.position (railData.path train.t)
    in
    case train.isStuckOrDerailed of
        IsDerailed derailTime _ ->
            derailOffset
                derailTime
                time
                (trainDirection time (Train train) |> Direction2d.unwrap |> Direction2d.unsafe)
                position

        _ ->
            position


derailOffset :
    Effect.Time.Posix
    -> Effect.Time.Posix
    -> Direction2d WorldUnit
    -> Point2d WorldUnit WorldUnit
    -> Point2d WorldUnit WorldUnit
derailOffset derailTime time direction position =
    let
        timeElapsed =
            Duration.from derailTime time |> Duration.inSeconds

        derailDuration =
            0.4

        t =
            timeElapsed / derailDuration |> clamp 0 1
    in
    Point2d.translateIn
        (Direction2d.rotateBy (Angle.degrees -45) direction)
        (Units.tileUnit (1 * t))
        position


status : Effect.Time.Posix -> Train -> Status
status time (Train train) =
    case train.status of
        WaitingAtHome ->
            WaitingAtHome

        TeleportingHome teleportTime ->
            if Duration.from teleportTime time |> Quantity.lessThan teleportLength then
                TeleportingHome teleportTime

            else
                WaitingAtHome

        Travelling ->
            Travelling

        StoppedAtPostOffice stoppedAtPostOffice ->
            StoppedAtPostOffice stoppedAtPostOffice


speed : Effect.Time.Posix -> Train -> Quantity Float (Rate TileLocalUnit Seconds)
speed time (Train train) =
    case status time (Train train) of
        WaitingAtHome ->
            stoppedSpeed

        TeleportingHome _ ->
            train.speed

        Travelling ->
            train.speed

        StoppedAtPostOffice _ ->
            train.speed


acceleration =
    1


defaultMaxSpeed : number
defaultMaxSpeed =
    5


moveTrains :
    Effect.Time.Posix
    -> Effect.Time.Posix
    -> IdDict TrainId Train
    ->
        { a
            | grid : Grid c
            , mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId }
        }
    -> IdDict TrainId Train
moveTrains targetTime time trains model =
    if Duration.from time targetTime |> Quantity.lessThanOrEqualToZero then
        trains

    else
        let
            nextTime =
                if Duration.from time targetTime |> Quantity.lessThan (Duration.milliseconds 50) then
                    targetTime

                else
                    Duration.addTo time (Duration.milliseconds 50)

            newTrains : IdDict TrainId Train
            newTrains =
                IdDict.map
                    (\trainId train ->
                        moveTrain trainId defaultMaxSpeed time nextTime model train
                    )
                    trains

            lookup : CollisionLookup WorldUnit ( Id TrainId, Train )
            lookup =
                List.foldl
                    (\( trainId, train ) lookup2 ->
                        case stuckOrDerailed nextTime train of
                            IsDerailed _ _ ->
                                lookup2

                            _ ->
                                CollisionLookup.addItem (trainPosition nextTime train) ( trainId, train ) lookup2
                    )
                    (CollisionLookup.init (Units.tileUnit 3))
                    (IdDict.toList newTrains)

            newTrains2 : IdDict TrainId Train
            newTrains2 =
                IdDict.map
                    (\trainId train ->
                        let
                            collisions =
                                CollisionLookup.collisionCandidates (trainPosition nextTime train) lookup
                                    |> List.filterMap
                                        (\( trainId2, train2 ) ->
                                            if trainId == trainId2 then
                                                Nothing

                                            else if
                                                Point2d.distanceFrom
                                                    (trainPosition nextTime train)
                                                    (trainPosition nextTime train2)
                                                    |> Quantity.lessThan (Units.tileUnit 1)
                                            then
                                                Just trainId2

                                            else
                                                Nothing
                                        )
                        in
                        case collisions of
                            first :: _ ->
                                derail nextTime first train

                            [] ->
                                train
                    )
                    newTrains
        in
        moveTrains targetTime nextTime newTrains2 model


moveTrain :
    Id TrainId
    -> Float
    -> Effect.Time.Posix
    -> Effect.Time.Posix
    -> { a | grid : Grid c, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> Train
    -> Train
moveTrain trainId maxSpeed startTime endTime state (Train train) =
    case train.isStuckOrDerailed of
        IsDerailed _ _ ->
            Train train

        _ ->
            let
                timeElapsed_ =
                    Duration.inSeconds (Duration.from startTime endTime) |> min 10

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
            case status startTime (Train train) of
                WaitingAtHome ->
                    Train train

                TeleportingHome _ ->
                    moveTrainHelper trainId startTime endTime distance distance state (Train { train | speed = Quantity newSpeed })

                Travelling ->
                    moveTrainHelper trainId startTime endTime distance distance state (Train { train | speed = Quantity newSpeed })

                StoppedAtPostOffice _ ->
                    moveTrainHelper trainId startTime endTime distance distance state (Train { train | speed = Quantity newSpeed })


moveTrainHelper :
    Id TrainId
    -> Effect.Time.Posix
    -> Effect.Time.Posix
    -> Quantity Float TileLocalUnit
    -> Quantity Float TileLocalUnit
    -> { a | grid : Grid c, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> Train
    -> Train
moveTrainHelper trainId startTime endTime initialDistance distanceLeft state (Train train) =
    let
        railPath =
            Tile.railPathData train.path

        currentDistance =
            railPath.tToDistance train.t

        newT =
            Quantity.plus
                (if Quantity.lessThanZero train.speed then
                    Quantity.negate distanceLeft

                 else
                    distanceLeft
                )
                currentDistance
                |> railPath.distanceToT

        newTClamped =
            clamp 0 1 newT

        reachedTileEnd () =
            let
                distanceTravelled : Quantity Float TileLocalUnit
                distanceTravelled =
                    railPath.tToDistance newTClamped |> Quantity.minus currentDistance |> Quantity.abs

                position : Point2d WorldUnit WorldUnit
                position =
                    railPath.path newTClamped |> Grid.localTilePointPlusWorld train.position

                ( cellPos, localPos ) =
                    Grid.worldToCellAndLocalPoint position

                newDistanceLeft =
                    distanceLeft |> Quantity.minus distanceTravelled
            in
            case
                findNextTile
                    trainId
                    startTime
                    position
                    state
                    train.speed
                    (if newTClamped == 1 then
                        railPath.endExitDirection

                     else
                        railPath.startExitDirection
                    )
                    (( cellPos, Coord.floorPoint localPos )
                        :: Grid.closeNeighborCells cellPos (Coord.floorPoint localPos)
                    )
            of
                Just newTrain ->
                    moveTrainHelper
                        trainId
                        startTime
                        endTime
                        initialDistance
                        newDistanceLeft
                        state
                        ({ position = newTrain.position
                         , path = newTrain.path
                         , previousPaths =
                            { position = train.position, path = train.path, reversed = newT > 0.5 }
                                :: List.take 3 train.previousPaths
                         , t = newTrain.t
                         , speed = newTrain.speed
                         , home = train.home
                         , homePath = train.homePath
                         , isStuckOrDerailed = IsNotStuckOrDerailed
                         , status =
                            case newTrain.stoppedAtPostOffice of
                                Just stoppedAtPostOffice ->
                                    StoppedAtPostOffice stoppedAtPostOffice

                                Nothing ->
                                    case train.status of
                                        StoppedAtPostOffice _ ->
                                            Travelling

                                        _ ->
                                            train.status
                         , owner = train.owner
                         , color = train.color
                         }
                            |> Train
                        )

                Nothing ->
                    Train
                        { train
                            | t = newTClamped
                            , isStuckOrDerailed =
                                case train.isStuckOrDerailed of
                                    IsNotStuckOrDerailed ->
                                        Duration.from startTime endTime
                                            |> Quantity.multiplyBy (1 - Quantity.ratio distanceLeft initialDistance)
                                            |> Duration.addTo startTime
                                            |> IsStuck

                                    _ ->
                                        train.isStuckOrDerailed
                            , speed =
                                if Quantity.lessThanZero train.speed then
                                    Quantity.negate stoppedSpeed

                                else
                                    stoppedSpeed
                        }
    in
    case train.status of
        StoppedAtPostOffice stoppedAtPostOffice ->
            if newT < 0 || newT > 1 then
                if Duration.from stoppedAtPostOffice.time startTime |> Quantity.greaterThan (Duration.seconds 3) then
                    reachedTileEnd ()

                else
                    Train
                        { train
                            | t = newTClamped
                            , speed =
                                if Quantity.lessThanZero train.speed then
                                    Quantity.negate stoppedSpeed

                                else
                                    stoppedSpeed
                            , isStuckOrDerailed = IsNotStuckOrDerailed
                        }

            else
                Train { train | t = newTClamped }

        _ ->
            if newT < 0 || newT > 1 then
                reachedTileEnd ()

            else
                Train { train | t = newTClamped, isStuckOrDerailed = IsNotStuckOrDerailed }


stoppedSpeed : Quantity Float units
stoppedSpeed =
    Quantity 0.1


home : Train -> Coord WorldUnit
home (Train train) =
    train.home


homePath : Train -> RailPath
homePath (Train train) =
    train.homePath


owner : Train -> Id UserId
owner (Train train) =
    train.owner


stuckOrDerailed : Effect.Time.Posix -> Train -> IsStuckOrDerailed
stuckOrDerailed time (Train train) =
    case status time (Train train) of
        Travelling ->
            train.isStuckOrDerailed

        WaitingAtHome ->
            IsNotStuckOrDerailed

        TeleportingHome _ ->
            train.isStuckOrDerailed

        StoppedAtPostOffice _ ->
            train.isStuckOrDerailed


moveCoachHelper :
    Quantity Float TileLocalUnit
    -> Bool
    -> CoachData
    -> CoachData
moveCoachHelper distanceLeft pathIsReversed coach =
    let
        { distanceToT, tToDistance } =
            Tile.railPathData coach.path
                |> (if pathIsReversed then
                        Tile.railDataReverse

                    else
                        identity
                   )

        currentDistance =
            tToDistance coach.t

        newT =
            Quantity.plus
                (if Quantity.lessThanZero coach.speed then
                    Quantity.negate distanceLeft

                 else
                    distanceLeft
                )
                currentDistance
                |> distanceToT

        newTClamped =
            clamp 0 1 newT
    in
    if newT < 0 || newT > 1 then
        let
            distanceTravelled : Quantity Float TileLocalUnit
            distanceTravelled =
                tToDistance newTClamped |> Quantity.minus currentDistance |> Quantity.abs
        in
        case coach.previousPaths of
            nextPath :: restOfPath ->
                moveCoachHelper
                    (distanceLeft |> Quantity.minus distanceTravelled)
                    nextPath.reversed
                    { position = nextPath.position
                    , path = nextPath.path
                    , previousPaths = restOfPath
                    , t = 0
                    , speed = Quantity.abs coach.speed
                    }

            [] ->
                { coach
                    | t = newTClamped
                    , speed =
                        if Quantity.lessThanZero coach.speed then
                            Quantity -0.1

                        else
                            Quantity 0.1
                }

    else
        { coach
            | t =
                if pathIsReversed then
                    1 - newTClamped

                else
                    newTClamped
        }


findNextTile :
    Id TrainId
    -> Effect.Time.Posix
    -> Point2d WorldUnit WorldUnit
    -> { a | grid : Grid c, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> List ( Coord CellUnit, Coord CellLocalUnit )
    -> Maybe TrainData
findNextTile trainId time position state speed_ direction list =
    case list of
        ( neighborCellPos, _ ) :: rest ->
            case Grid.getCell neighborCellPos state.grid of
                Just cell ->
                    case
                        findNextTileHelper
                            trainId
                            time
                            neighborCellPos
                            position
                            speed_
                            direction
                            state
                            (GridCell.getToggledRailSplit cell)
                            (GridCell.flatten cell)
                    of
                        Just newTrain ->
                            Just newTrain

                        Nothing ->
                            findNextTile trainId time position state speed_ direction rest

                Nothing ->
                    findNextTile trainId time position state speed_ direction rest

        [] ->
            Nothing


findNextTileHelper :
    Id TrainId
    -> Effect.Time.Posix
    -> Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> { a | grid : Grid c, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> AssocSet.Set (Coord CellLocalUnit)
    -> List GridCell.Value
    -> Maybe TrainData
findNextTileHelper trainId time neighborCellPos position speed_ direction state toggledRailPaths tiles =
    case tiles of
        tile :: rest ->
            let
                checkPath2 =
                    checkPath trainId time tile state.mail neighborCellPos position speed_ direction

                maybeNewTrain : Maybe TrainData
                maybeNewTrain =
                    case Tile.getData tile.value |> .railPath of
                        NoRailPath ->
                            Nothing

                        SingleRailPath path1 ->
                            checkPath2 path1

                        DoubleRailPath path1 path2 ->
                            List.filterMap checkPath2 [ path1, path2 ]
                                |> List.head

                        RailSplitPath { primary, secondary } ->
                            case ( checkPath2 primary, checkPath2 secondary ) of
                                ( Just primary2, Just secondary2 ) ->
                                    if AssocSet.member tile.position toggledRailPaths then
                                        Just secondary2

                                    else
                                        Just primary2

                                ( Nothing, Just secondary2 ) ->
                                    Just secondary2

                                ( Just primary2, _ ) ->
                                    Just primary2

                                ( Nothing, Nothing ) ->
                                    Nothing
            in
            case maybeNewTrain of
                Just newTrain ->
                    Just newTrain

                Nothing ->
                    findNextTileHelper trainId time neighborCellPos position speed_ direction state toggledRailPaths rest

        [] ->
            Nothing


checkPath :
    Id TrainId
    -> Effect.Time.Posix
    -> GridCell.Value
    -> IdDict MailId { a | status : MailStatus, from : Id UserId, to : Id UserId }
    -> Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> RailPath
    -> Maybe TrainData
checkPath trainId time tile mail neighborCellPos position speed_ direction railPath =
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
            case ( tile.value, carryingMail mail trainId ) of
                ( PostOffice, Nothing ) ->
                    if
                        List.any
                            (\mail_ -> tile.userId == mail_.from && mail_.status == MailWaitingPickup)
                            (IdDict.values mail)
                    then
                        Just { time = time, userId = tile.userId }

                    else
                        Nothing

                ( PostOffice, Just ( _, mailCarried ) ) ->
                    if mailCarried.to == tile.userId then
                        Just { time = time, userId = tile.userId }

                    else
                        Nothing

                _ ->
                    Nothing
    in
    if (Point2d.distanceFrom worldPoint0 position |> Quantity.lessThan (Units.tileUnit 0.1)) && validDirection0 then
        { position =
            Grid.cellAndLocalCoordToWorld ( neighborCellPos, tile.position )
        , t = 0
        , speed = Quantity.abs speed_
        , path = railPath
        , stoppedAtPostOffice = stoppedAtPostOffice ()
        }
            |> Just

    else if (Point2d.distanceFrom worldPoint1 position |> Quantity.lessThan (Units.tileUnit 0.1)) && validDirection1 then
        { position =
            Grid.cellAndLocalCoordToWorld ( neighborCellPos, tile.position )
        , t = 1
        , speed = Quantity.abs speed_ |> Quantity.negate
        , path = railPath
        , stoppedAtPostOffice = stoppedAtPostOffice ()
        }
            |> Just

    else
        Nothing


teleportLength : Duration
teleportLength =
    Duration.seconds 1


path : Effect.Time.Posix -> Train -> RailPath
path time (Train train) =
    case status time (Train train) of
        WaitingAtHome ->
            train.homePath

        TeleportingHome _ ->
            train.path

        Travelling ->
            train.path

        StoppedAtPostOffice _ ->
            train.path


trainT : Effect.Time.Posix -> Train -> Float
trainT time (Train train) =
    case status time (Train train) of
        WaitingAtHome ->
            0.5

        _ ->
            train.t


trainDirection : Effect.Time.Posix -> Train -> Direction2d TileLocalUnit
trainDirection time train =
    let
        railData : RailData
        railData =
            Tile.railPathData (path time train)
    in
    Tile.pathDirection railData.path (trainT time train)
        |> (if Quantity.lessThanZero (speed time train) then
                Direction2d.reverse

            else
                identity
           )


draw :
    RenderData
    -> Maybe (Id UserId)
    -> Effect.Time.Posix
    -> IdDict MailId FrontendMail
    -> IdDict TrainId Train
    -> BoundingBox2d WorldUnit WorldUnit
    -> List Effect.WebGL.Entity
draw renderData maybeSelectedUserId time mail trains viewBounds =
    let
        trainViewBounds =
            BoundingBox2d.expandBy (Coord.maxComponent trainSize |> Quantity.toFloatQuantity) viewBounds
    in
    List.concatMap
        (\( trainId, train ) ->
            let
                trainPosition2 =
                    trainPosition time train

                { x, y } =
                    Point2d.unwrap trainPosition2

                isDerailed =
                    case stuckOrDerailed time train of
                        IsDerailed time2 _ ->
                            Just time2

                        IsStuck _ ->
                            Nothing

                        IsNotStuckOrDerailed ->
                            Nothing

                trainFrame : Int
                trainFrame =
                    trainDirection time train
                        |> Direction2d.angleFrom Direction2d.x
                        |> Angle.inTurns
                        |> (*) trainFrames
                        |> round
                        |> modBy trainFrames

                trainMesh : List TrainEntity
                trainMesh =
                    case status time train of
                        TeleportingHome teleportTime ->
                            let
                                t =
                                    Quantity.ratio (Duration.from teleportTime time) teleportLength |> max 0

                                homePosition =
                                    trainPosition time2 train |> Point2d.unwrap

                                time2 =
                                    Duration.addTo time teleportLength

                                trainFrame2 : Int
                                trainFrame2 =
                                    Direction2d.angleFrom
                                        Direction2d.x
                                        (Tile.pathDirection
                                            (Tile.railPathData (path time2 train)).path
                                            0.5
                                            |> (if Quantity.lessThanZero (speed time2 train) then
                                                    Direction2d.reverse

                                                else
                                                    identity
                                               )
                                        )
                                        |> Angle.inTurns
                                        |> (*) trainFrames
                                        |> round
                                        |> modBy trainFrames
                            in
                            if t >= 1 then
                                []

                            else
                                [ { x = x
                                  , y = y
                                  , rotationFrame = trainFrame
                                  , teleportAmount = t
                                  , userId = owner train
                                  , trainType = 0
                                  , color = trainColor train
                                  , isDerailed = isDerailed
                                  }
                                , { x = homePosition.x
                                  , y = homePosition.y
                                  , rotationFrame = trainFrame2
                                  , teleportAmount = 1 - t
                                  , userId = owner train
                                  , trainType = 0
                                  , color = trainColor train
                                  , isDerailed = Nothing
                                  }
                                ]

                        _ ->
                            [ { x = x
                              , y = y
                              , rotationFrame = trainFrame
                              , teleportAmount = 0
                              , userId = owner train
                              , trainType = 0
                              , color = trainColor train
                              , isDerailed = isDerailed
                              }
                            ]
            in
            (if BoundingBox2d.contains trainPosition2 trainViewBounds then
                trainMesh

             else
                []
            )
                ++ (case carryingMail mail trainId of
                        Just _ ->
                            let
                                coach : Coach
                                coach =
                                    getCoach time train

                                coachPosition_ : { x : Float, y : Float }
                                coachPosition_ =
                                    Point2d.unwrap coach.position

                                coachFrame : Int
                                coachFrame =
                                    Direction2d.angleFrom Direction2d.x coach.direction
                                        |> Angle.inTurns
                                        |> (*) trainFrames
                                        |> round
                                        |> modBy trainFrames
                            in
                            if BoundingBox2d.contains coach.position trainViewBounds then
                                case status time train of
                                    WaitingAtHome ->
                                        []

                                    TeleportingHome teleportTime ->
                                        let
                                            t =
                                                Quantity.ratio (Duration.from teleportTime time) teleportLength |> max 0
                                        in
                                        if t >= 1 then
                                            []

                                        else
                                            [ { x = coachPosition_.x
                                              , y = coachPosition_.y
                                              , rotationFrame = coachFrame
                                              , teleportAmount = t
                                              , userId = owner train
                                              , trainType = 1
                                              , color = trainColor train
                                              , isDerailed = isDerailed
                                              }
                                            ]

                                    _ ->
                                        [ { x = coachPosition_.x
                                          , y = coachPosition_.y
                                          , rotationFrame = coachFrame
                                          , teleportAmount = 0
                                          , userId = owner train
                                          , trainType = 1
                                          , color = trainColor train
                                          , isDerailed = isDerailed
                                          }
                                        ]

                            else
                                []

                        Nothing ->
                            []
                   )
        )
        (IdDict.toList trains)
        |> List.map (trainEntity renderData maybeSelectedUserId)


startTeleportingHome : Effect.Time.Posix -> Train -> Train
startTeleportingHome time (Train train) =
    Train
        { train
            | status =
                case status time (Train train) of
                    Travelling ->
                        TeleportingHome time

                    TeleportingHome _ ->
                        train.status

                    WaitingAtHome ->
                        train.status

                    StoppedAtPostOffice _ ->
                        TeleportingHome time
        }


leaveHome : Effect.Time.Posix -> Train -> Train
leaveHome time (Train train) =
    case status time (Train train) of
        Travelling ->
            Train train

        TeleportingHome _ ->
            Train train

        WaitingAtHome ->
            Train
                { train
                    | status = Travelling
                    , t = 0.5
                    , position = train.home
                    , path = train.homePath
                    , isStuckOrDerailed = IsNotStuckOrDerailed
                    , speed = stoppedSpeed
                }

        StoppedAtPostOffice _ ->
            Train train


type alias TrainEntity =
    { x : Float
    , y : Float
    , rotationFrame : Int
    , teleportAmount : Float
    , color : Color
    , trainType : Int
    , userId : Id UserId
    , isDerailed : Maybe Effect.Time.Posix
    }


trainEntity : RenderData -> Maybe (Id UserId) -> TrainEntity -> Effect.WebGL.Entity
trainEntity { nightFactor, viewMatrix, texture, lights, depth, time, scissors } maybeUserId trainData =
    let
        ( tileW, tileH ) =
            Coord.toTuple Units.tileSize

        ( trainW, trainH ) =
            Coord.toTuple trainSize

        ( textureWidth, textureHeight ) =
            WebGL.Texture.size texture

        offsetX =
            sin (100 * trainData.teleportAmount) * min 1 (trainData.teleportAmount * 3)

        y2 =
            toFloat trainH - (trainData.teleportAmount * toFloat trainH) |> round |> toFloat

        textureX =
            (trainData.trainType
                + (case trainData.isDerailed of
                    Just _ ->
                        2

                    Nothing ->
                        0
                  )
            )
                * trainW
    in
    Effect.WebGL.entityWith
        [ Effect.WebGL.Settings.DepthTest.default, Shaders.blend, Shaders.scissorBox scissors ]
        Shaders.instancedVertexShader
        Shaders.fragmentShader
        instancedMesh
        { view = viewMatrix
        , texture = texture
        , lights = lights
        , depth = depth
        , textureSize = Vec2.vec2 (toFloat textureWidth) (toFloat textureHeight)
        , color = Vec4.vec4 1 1 1 1
        , userId =
            case maybeUserId of
                Just userId ->
                    Id.toInt userId |> toFloat

                Nothing ->
                    -3
        , time = time
        , opacityAndUserId0 = Shaders.opacityAndUserId 1 trainData.userId
        , position0 =
            Vec3.vec3
                (toFloat tileW * trainData.x - (toFloat trainW / 2) + offsetX)
                (toFloat tileH * trainData.y - (toFloat trainH / 2) - 5)
                0
        , size0 = Vec2.vec2 (toFloat trainW) y2
        , texturePosition0 = textureX + (trainData.rotationFrame * trainH * textureWidth) |> toFloat
        , primaryColor0 = Color.unwrap trainData.color |> toFloat
        , secondaryColor0 = 0
        , night = nightFactor
        }


carryingMail :
    IdDict MailId { a | status : MailStatus }
    -> Id TrainId
    -> Maybe ( Id MailId, { a | status : MailStatus } )
carryingMail mail trainId =
    IdDict.toList mail
        |> List.find
            (\( _, mail_ ) ->
                case mail_.status of
                    MailInTransit mailTrainId ->
                        mailTrainId == trainId

                    _ ->
                        False
            )


trainFrames =
    48


trainSize =
    Coord.xy 36 36


nextId : IdDict a b -> Id a
nextId ids =
    IdDict.toList ids
        |> List.map (Tuple.first >> Id.toInt)
        |> List.maximum
        |> Maybe.withDefault 0
        |> (+) 1
        |> Id.fromInt


handleAddingTrain : IdDict TrainId Train -> Id UserId -> Tile -> Coord WorldUnit -> Maybe ( Id TrainId, Train )
handleAddingTrain trains owner_ tile position =
    if tile == TrainHouseLeft || tile == TrainHouseRight then
        let
            ( railPath, homePath_ ) =
                if tile == TrainHouseLeft then
                    ( Tile.trainHouseLeftRailPath, Tile.trainHouseLeftRailPath )

                else
                    ( Tile.trainHouseRightRailPath, Tile.trainHouseRightRailPath )

            id =
                nextId trains
        in
        ( id
        , Train
            { position = position
            , path = railPath
            , previousPaths = []
            , t = 0.5
            , speed = stoppedSpeed
            , home = position
            , homePath = homePath_
            , isStuckOrDerailed = IsNotStuckOrDerailed
            , status = WaitingAtHome
            , owner = owner_
            , color =
                Random.step
                    (Random.uniform
                        (Color.rgb255 200 200 200)
                        [ Color.rgb255 80 80 80
                        , Color.rgb255 240 100 100
                        , Color.rgb255 250 230 90
                        , Color.rgb255 0 240 100
                        , Color.rgb255 140 80 255
                        ]
                    )
                    (Random.initialSeed (Id.toInt id))
                    |> Tuple.first
            }
        )
            |> Just

    else
        Nothing


canRemoveTiles : Effect.Time.Posix -> List { a | tile : Tile, position : Coord WorldUnit } -> IdDict TrainId Train -> Result (List ( Id TrainId, Train )) (List ( Id TrainId, Train ))
canRemoveTiles time removed trains =
    let
        trainsToRemove : List ( Id TrainId, Train )
        trainsToRemove =
            List.concatMap
                (\remove ->
                    if remove.tile == TrainHouseLeft || remove.tile == TrainHouseRight then
                        IdDict.toList trains
                            |> List.filterMap
                                (\( trainId, train ) ->
                                    if home train == remove.position then
                                        Just ( trainId, train )

                                    else
                                        Nothing
                                )

                    else
                        []
                )
                removed

        canRemoveAllTrains : Bool
        canRemoveAllTrains =
            List.all
                (\( _, train ) ->
                    case status time train of
                        WaitingAtHome ->
                            True

                        _ ->
                            False
                )
                trainsToRemove
    in
    if canRemoveAllTrains then
        Ok trainsToRemove

    else
        Err trainsToRemove


instancedMesh : Effect.WebGL.Mesh InstancedVertex
instancedMesh =
    List.concatMap
        (\index ->
            [ { localPosition = Vec2.vec2 0 0, index = toFloat index }
            , { localPosition = Vec2.vec2 1 0, index = toFloat index }
            , { localPosition = Vec2.vec2 1 1, index = toFloat index }
            , { localPosition = Vec2.vec2 0 1, index = toFloat index }
            ]
        )
        (List.range 0 0)
        |> Sprite.toMesh


stuckMessageDelay : Duration
stuckMessageDelay =
    Duration.seconds 2


derailedMessageDelay : Duration
derailedMessageDelay =
    Duration.seconds 1


getSpeechBubbles : Effect.Time.Posix -> IdDict TrainId Train -> List { position : Point2d WorldUnit WorldUnit, isRadio : Bool }
getSpeechBubbles currentTime trains =
    IdDict.toList trains
        |> List.concatMap
            (\( _, train ) ->
                case ( status currentTime train, stuckOrDerailed currentTime train ) of
                    ( TeleportingHome _, _ ) ->
                        []

                    ( _, IsStuck time ) ->
                        if Duration.from time currentTime |> Quantity.lessThan stuckMessageDelay then
                            []

                        else
                            [ { position = trainPosition currentTime train, isRadio = False }
                            , { position = Coord.toPoint2d (home train), isRadio = True }
                            ]

                    ( _, IsDerailed time otherTrainId ) ->
                        if Duration.from time currentTime |> Quantity.lessThan derailedMessageDelay then
                            []

                        else
                            case IdDict.get otherTrainId trains of
                                Just otherTrain ->
                                    let
                                        position =
                                            trainPosition currentTime train

                                        otherPosition =
                                            trainPosition currentTime otherTrain
                                    in
                                    if Point2d.yCoordinate position |> Quantity.lessThan (Point2d.yCoordinate otherPosition) then
                                        [ { position = position, isRadio = False }
                                        , { position = Coord.toPoint2d (home train), isRadio = True }
                                        ]

                                    else
                                        [ { position = Coord.toPoint2d (home train), isRadio = True } ]

                                Nothing ->
                                    [ { position = trainPosition currentTime train, isRadio = False }
                                    , { position = Coord.toPoint2d (home train), isRadio = True }
                                    ]

                    ( _, IsNotStuckOrDerailed ) ->
                        []
            )


speechBubbleMesh : Array (Effect.WebGL.Mesh Vertex)
speechBubbleMesh =
    List.range 0 (speechBubbleFrames - 1)
        |> List.map (\frame -> speechBubbleMeshHelper frame (Coord.xy 517 29) (Coord.xy 8 12))
        |> Array.fromList


speechBubbleRadioMesh : Array (Effect.WebGL.Mesh Vertex)
speechBubbleRadioMesh =
    List.range 0 (speechBubbleFrames - 1)
        |> List.map (\frame -> speechBubbleMeshHelper frame (Coord.xy 525 29) (Coord.xy 8 13))
        |> Array.fromList


speechBubbleFrames =
    3


speechBubbleMeshHelper : Int -> Coord a -> Coord a -> Effect.WebGL.Mesh Vertex
speechBubbleMeshHelper frame bubbleTailTexturePosition bubbleTailTextureSize =
    let
        text =
            "Help!"

        padding =
            Coord.xy 6 5

        colors =
            { primaryColor = Color.white
            , secondaryColor = Color.black
            }
    in
    Sprite.nineSlice
        { topLeft = Coord.xy 504 29
        , top = Coord.xy 510 29
        , topRight = Coord.xy 511 29
        , left = Coord.xy 504 35
        , center = Coord.xy 510 35
        , right = Coord.xy 511 35
        , bottomLeft = Coord.xy 504 36
        , bottom = Coord.xy 510 36
        , bottomRight = Coord.xy 511 36
        , cornerSize = Coord.xy 6 6
        , position = Coord.xy 0 0
        , size = Sprite.textSize 1 text |> Coord.plus (Coord.multiplyTuple ( 2, 2 ) padding)
        , scale = 1
        }
        colors
        ++ Sprite.shiverText frame 1 "Help!" padding
        ++ Sprite.spriteWithTwoColors colors (Coord.xy 7 27) (Coord.xy 8 12) bubbleTailTexturePosition bubbleTailTextureSize
        |> Sprite.toMesh


drawSpeechBubble :
    RenderData
    -> Effect.Time.Posix
    -> IdDict TrainId Train
    -> List Effect.WebGL.Entity
drawSpeechBubble { nightFactor, lights, texture, depth, viewMatrix, time, scissors } time2 trains =
    List.filterMap
        (\{ position, isRadio } ->
            let
                point =
                    Point2d.unwrap position

                ( xOffset, yOffset ) =
                    if isRadio then
                        ( 6, -8 )

                    else
                        ( -8, -48 )

                meshArray =
                    if isRadio then
                        speechBubbleRadioMesh

                    else
                        speechBubbleMesh
            in
            case
                Array.get
                    (Effect.Time.posixToMillis time2
                        |> toFloat
                        |> (*) 0.01
                        |> round
                        |> modBy speechBubbleFrames
                    )
                    meshArray
            of
                Just mesh ->
                    Effect.WebGL.entityWith
                        [ Shaders.blend, Shaders.scissorBox scissors ]
                        Shaders.vertexShader
                        Shaders.fragmentShader
                        mesh
                        { view =
                            Mat4.makeTranslate3
                                (round (point.x * toFloat Units.tileWidth) + xOffset |> toFloat)
                                (round (point.y * toFloat Units.tileHeight) + yOffset |> toFloat)
                                0
                                |> Mat4.mul viewMatrix
                        , texture = texture
                        , lights = lights
                        , depth = depth
                        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                        , color = Vec4.vec4 1 1 1 1
                        , userId = Shaders.noUserIdSelected
                        , time = time
                        , night = nightFactor
                        }
                        |> Just

                Nothing ->
                    Nothing
        )
        (getSpeechBubbles time2 trains)
