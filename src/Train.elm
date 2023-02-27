module Train exposing
    ( FieldChanged(..)
    , IsStuckOrDerailed(..)
    , PreviousPath
    , Status(..)
    , Train(..)
    , TrainDiff(..)
    , applyDiff
    , canRemoveTiles
    , carryingMail
    , coachPosition
    , defaultMaxSpeed
    , derail
    , diff
    , draw
    , getCoach
    , handleAddingTrain
    , home
    , homePath
    , leaveHome
    , moveTrain
    , nextId
    , owner
    , speed
    , startTeleportingHome
    , status
    , stoppedSpeed
    , stuckOrDerailed
    , trainPosition
    )

import Angle
import Array exposing (Array)
import AssocList
import AssocSet
import BoundingBox2d exposing (BoundingBox2d)
import Color exposing (Color)
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import Duration exposing (Duration, Seconds)
import Effect.Time
import Effect.WebGL
import Effect.WebGL.Settings.DepthTest
import Effect.WebGL.Texture exposing (Texture)
import Grid exposing (Grid)
import GridCell
import Id exposing (Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import List.Extra as List
import MailEditor exposing (FrontendMail, MailStatus(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Shaders exposing (InstancedVertex, Vertex)
import Sprite
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
    | IsDerailed Effect.Time.Posix
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
        Unchanged ->
            old

        FieldChanged new ->
            new


type FieldChanged a
    = FieldChanged a
    | Unchanged


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
    { position : Coord WorldUnit
    , path : RailPath
    , t : Float
    }


getCoach : Train -> Coach
getCoach (Train train) =
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
    in
    { position = coach.position
    , path = coach.path
    , t = coach.t
    }


derail : Effect.Time.Posix -> Train -> Train
derail time (Train train) =
    Train { train | isStuckOrDerailed = IsDerailed time }


trainPosition : Effect.Time.Posix -> Train -> Point2d WorldUnit WorldUnit
trainPosition time (Train train) =
    case status time (Train train) of
        Travelling ->
            travellingPosition train

        WaitingAtHome ->
            let
                railPath =
                    Tile.railPathData train.homePath
            in
            Grid.localTilePointPlusWorld train.home (railPath.path 0.5)

        TeleportingHome _ ->
            travellingPosition train

        StoppedAtPostOffice _ ->
            travellingPosition train


travellingPosition :
    { a
        | path : RailPath
        , position : Coord WorldUnit
        , t : Float
        , isStuckOrDerailed : IsStuckOrDerailed
    }
    -> Point2d WorldUnit WorldUnit
travellingPosition train =
    let
        railData : RailData
        railData =
            Tile.railPathData train.path

        position =
            Grid.localTilePointPlusWorld train.position (railData.path train.t)
    in
    case train.isStuckOrDerailed of
        IsDerailed _ ->
            Point2d.translateIn
                (Tile.pathDirection railData.path train.t
                    |> Direction2d.perpendicularTo
                    |> Direction2d.unwrap
                    |> Direction2d.unsafe
                )
                (Units.tileUnit 1)
                position

        _ ->
            position


coachPosition : Coach -> Point2d WorldUnit WorldUnit
coachPosition coach =
    let
        railData =
            Tile.railPathData coach.path
    in
    Grid.localTilePointPlusWorld coach.position (railData.path coach.t)


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


moveTrain :
    Id TrainId
    -> Float
    -> Effect.Time.Posix
    -> Effect.Time.Posix
    -> { a | grid : Grid, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> Train
    -> Train
moveTrain trainId maxSpeed startTime endTime state (Train train) =
    case train.isStuckOrDerailed of
        IsDerailed _ ->
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
    -> { a | grid : Grid, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
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
    -> { a | grid : Grid, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
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
    -> { a | grid : Grid, mail : IdDict MailId { b | status : MailStatus, from : Id UserId, to : Id UserId } }
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


draw :
    Maybe (Id UserId)
    -> Effect.Time.Posix
    -> IdDict MailId FrontendMail
    -> IdDict TrainId Train
    -> Mat4
    -> WebGL.Texture.Texture
    -> BoundingBox2d WorldUnit WorldUnit
    -> Float
    -> List Effect.WebGL.Entity
draw maybeSelectedUserId time mail trains viewMatrix trainTexture viewBounds shaderTime =
    let
        trainViewBounds =
            BoundingBox2d.expandBy (Coord.maxComponent trainSize |> Quantity.toFloatQuantity) viewBounds
    in
    List.concatMap
        (\( trainId, train ) ->
            let
                isSelected =
                    maybeSelectedUserId == Just (owner train)

                railData : RailData
                railData =
                    Tile.railPathData (path time train)

                trainPosition2 =
                    trainPosition time train

                { x, y } =
                    Point2d.unwrap trainPosition2

                trainFrame : Int
                trainFrame =
                    Direction2d.angleFrom
                        Direction2d.x
                        (Tile.pathDirection railData.path (trainT time train)
                            |> (if Quantity.lessThanZero (speed time train) then
                                    Direction2d.reverse

                                else
                                    identity
                               )
                        )
                        |> Angle.inTurns
                        |> (*) trainFrames
                        |> round
                        |> modBy trainFrames

                trainMesh : List Effect.WebGL.Entity
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
                                [ trainEntity
                                    maybeSelectedUserId
                                    trainTexture
                                    t
                                    trainFrame
                                    viewMatrix
                                    x
                                    y
                                    shaderTime
                                , trainEntity
                                    maybeSelectedUserId
                                    trainTexture
                                    (1 - t)
                                    trainFrame2
                                    viewMatrix
                                    homePosition.x
                                    homePosition.y
                                    shaderTime
                                ]

                        _ ->
                            [ trainEntity maybeSelectedUserId trainTexture 0 trainFrame viewMatrix x y shaderTime ]
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
                                    getCoach train

                                railData_ : RailData
                                railData_ =
                                    Tile.railPathData coach.path

                                coachPosition2 : Point2d WorldUnit WorldUnit
                                coachPosition2 =
                                    coachPosition coach

                                coachPosition_ : { x : Float, y : Float }
                                coachPosition_ =
                                    Point2d.unwrap coachPosition2

                                coachFrame : Int
                                coachFrame =
                                    Direction2d.angleFrom
                                        Direction2d.x
                                        (Tile.pathDirection railData_.path coach.t
                                            |> (if Quantity.lessThanZero (speed time train) then
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
                            if BoundingBox2d.contains coachPosition2 trainViewBounds then
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
                                            [ trainEntity
                                                maybeSelectedUserId
                                                trainTexture
                                                t
                                                coachFrame
                                                viewMatrix
                                                coachPosition_.x
                                                coachPosition_.y
                                                shaderTime
                                            ]

                                    _ ->
                                        [ trainEntity
                                            maybeSelectedUserId
                                            trainTexture
                                            1
                                            trainFrame
                                            viewMatrix
                                            coachPosition_.x
                                            coachPosition_.y
                                            shaderTime
                                        ]

                            else
                                []

                        Nothing ->
                            []
                   )
        )
        (IdDict.toList trains)


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
    }


trainEntity :
    Maybe (Id UserId)
    -> WebGL.Texture.Texture
    -> Float
    -> Int
    -> Mat4
    -> Float
    -> Float
    -> Float
    -> Effect.WebGL.Entity
trainEntity maybeUserId trainTexture teleportAmount trainFrame viewMatrix x y shaderTime =
    let
        ( tileW, tileH ) =
            Coord.toTuple Units.tileSize

        ( trainW, trainH ) =
            Coord.toTuple trainSize

        ( textureWidth, textureHeight ) =
            WebGL.Texture.size trainTexture

        offsetX =
            sin (100 * teleportAmount) * min 1 (teleportAmount * 3)

        y2 =
            toFloat trainH - (teleportAmount * toFloat trainH) |> round |> toFloat
    in
    Effect.WebGL.entityWith
        [ Effect.WebGL.Settings.DepthTest.default, Shaders.blend ]
        Shaders.instancedVertexShader
        Shaders.fragmentShader
        instancedMesh
        { view = viewMatrix
        , texture = trainTexture
        , textureSize = Vec2.vec2 (toFloat textureWidth) (toFloat textureHeight)
        , color = Vec4.vec4 1 1 1 1
        , userId =
            case maybeUserId of
                Just userId ->
                    Id.toInt userId |> toFloat

                Nothing ->
                    -3
        , time = shaderTime
        , opacityAndUserId0 = Shaders.opaque
        , position0 =
            Vec3.vec3
                (toFloat tileW * x - (toFloat trainW / 2) + offsetX)
                (toFloat tileH * y - (toFloat trainH / 2) - 5)
                (Grid.tileZ True y 0)
        , size0 = Vec2.vec2 (toFloat trainW) y2
        , texturePosition0 = 0 + toFloat (trainFrame * trainH * textureWidth)
        , primaryColor0 = Color.rgb255 255 100 100 |> Color.toInt |> toFloat
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


trainEngineMeshes : Array (Effect.WebGL.Mesh Vertex)
trainEngineMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map (trainEngineMesh 0)
        |> Array.fromList


trainCoachMeshes : Array (Effect.WebGL.Mesh Vertex)
trainCoachMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map (trainCoachMesh 0)
        |> Array.fromList


trainSize =
    Coord.xy 36 36


opacityAndUserId =
    Shaders.opacityAndUserId 1 (Id.fromInt 0)


defaultTrainColor =
    Color.rgb255 200 255 100


trainEngineMesh : Float -> Int -> Effect.WebGL.Mesh Vertex
trainEngineMesh teleportAmount frame =
    let
        offsetX =
            sin (100 * teleportAmount) * min 1 (teleportAmount * 3)

        offsetY =
            -5

        y =
            toFloat frame * h |> round |> toFloat

        y2 =
            y + h - (teleportAmount * h) |> round |> toFloat

        ( w, h ) =
            Coord.toTuple trainSize |> Tuple.mapBoth toFloat toFloat

        ( tileSizeW, tileSizeH ) =
            Coord.toTuple Units.tileSize |> Tuple.mapBoth toFloat toFloat

        primaryColor : Float
        primaryColor =
            Color.toInt defaultTrainColor |> toFloat
    in
    Shaders.triangleFan
        [ { x = -tileSizeW + offsetX
          , y = -tileSizeH + offsetY
          , z = 0
          , texturePosition = trainTextureWidth * y
          , opacityAndUserId = opacityAndUserId
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        , { x = tileSizeW + offsetX
          , y = -tileSizeH + offsetY
          , z = 0
          , texturePosition = w + trainTextureWidth * y
          , opacityAndUserId = opacityAndUserId
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        , { x = tileSizeW + offsetX
          , y = tileSizeH + offsetY - (teleportAmount * h)
          , z = 0
          , texturePosition = w + trainTextureWidth * y2
          , opacityAndUserId = opacityAndUserId
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        , { x = -tileSizeW + offsetX
          , y = tileSizeH + offsetY - (teleportAmount * h)
          , z = 0
          , texturePosition = trainTextureWidth * y2
          , opacityAndUserId = opacityAndUserId
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        ]


trainTextureWidth =
    1728


trainCoachMesh : Float -> Int -> Effect.WebGL.Mesh Vertex
trainCoachMesh teleportAmount frame =
    let
        offsetX =
            sin (100 * teleportAmount) * min 1 (teleportAmount * 3)

        offsetY =
            -5

        y =
            toFloat frame * h

        y2 =
            y + h - (teleportAmount * h)

        ( w, h ) =
            Coord.toTuple trainSize |> Tuple.mapBoth toFloat toFloat

        ( tileSizeW, tileSizeH ) =
            Coord.toTuple Units.tileSize |> Tuple.mapBoth toFloat toFloat

        primaryColor : Float
        primaryColor =
            Color.toInt defaultTrainColor |> toFloat
    in
    Shaders.triangleFan
        [ { x = -tileSizeW + offsetX
          , y = -tileSizeH + offsetY
          , z = 0
          , texturePosition = w + trainTextureWidth * y
          , opacityAndUserId = Shaders.opaque
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        , { x = tileSizeW + offsetX
          , y = -tileSizeH + offsetY
          , z = 0
          , texturePosition = (w * 2) + trainTextureWidth * y
          , opacityAndUserId = Shaders.opaque
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        , { x = tileSizeW + offsetX
          , y = tileSizeH + offsetY - (teleportAmount * h)
          , z = 0
          , texturePosition = (w * 2) + trainTextureWidth * y2
          , opacityAndUserId = Shaders.opaque
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        , { x = -tileSizeW + offsetX
          , y = tileSizeH + offsetY - (teleportAmount * h)
          , z = 0
          , texturePosition = w + trainTextureWidth * y2
          , opacityAndUserId = Shaders.opaque
          , primaryColor = primaryColor
          , secondaryColor = 0
          }
        ]


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
        in
        ( nextId trains
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
            , color = defaultTrainColor
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
