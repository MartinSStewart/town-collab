module Train exposing
    ( Status(..)
    , Train
    , cancelTeleportingHome
    , carryingMail
    , coachPosition
    , defaultMaxSpeed
    , draw
    , getCoach
    , handleAddingTrain
    , home
    , isStuck
    , leaveHome
    , moveTrain
    , speed
    , startTeleportingHome
    , status
    , stoppedSpeed
    , trainPosition
    )

import Angle
import Array exposing (Array)
import AssocList
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import Duration exposing (Duration, Seconds)
import Grid exposing (Grid)
import GridCell
import Id exposing (Id, MailId, TrainId, UserId)
import List.Extra as List
import MailEditor exposing (FrontendMail, MailStatus(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2
import Math.Vector3 as Vec3
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Random
import Shaders exposing (Vertex)
import Tile exposing (Direction, RailData, RailPath, RailPathType(..), Tile(..))
import Time
import Units exposing (CellLocalUnit, CellUnit, TileLocalUnit, WorldUnit)
import WebGL
import WebGL.Settings.DepthTest
import WebGL.Texture exposing (Texture)


type Status
    = WaitingAtHome
    | TeleportingHome Time.Posix
    | Travelling
    | StoppedAtPostOffice { time : Time.Posix, userId : Id UserId }


type Train
    = Train
        { position : Coord WorldUnit
        , path : RailPath
        , previousPaths : List PreviousPath
        , t : Float
        , speed : Quantity Float (Rate TileLocalUnit Seconds)
        , home : Coord WorldUnit
        , homePath : RailPath
        , isStuck : Maybe Time.Posix
        , status : Status
        }


type alias PreviousPath =
    { position : Coord WorldUnit, path : RailPath, reversed : Bool }


type alias TrainData =
    { position : Coord WorldUnit
    , path : RailPath
    , t : Float
    , speed : Quantity Float (Rate TileLocalUnit Seconds)
    , stoppedAtPostOffice : Maybe { time : Time.Posix, userId : Id UserId }
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


trainPosition : Time.Posix -> Train -> Point2d WorldUnit WorldUnit
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


travellingPosition train =
    let
        railData =
            Tile.railPathData train.path
    in
    Grid.localTilePointPlusWorld train.position (railData.path train.t)


coachPosition : Coach -> Point2d WorldUnit WorldUnit
coachPosition coach =
    let
        railData =
            Tile.railPathData coach.path
    in
    Grid.localTilePointPlusWorld coach.position (railData.path coach.t)


status : Time.Posix -> Train -> Status
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


speed : Time.Posix -> Train -> Quantity Float (Rate TileLocalUnit Seconds)
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
    -> Time.Posix
    -> Time.Posix
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> Train
    -> Train
moveTrain trainId maxSpeed startTime endTime state (Train train) =
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
    -> Time.Posix
    -> Time.Posix
    -> Quantity Float TileLocalUnit
    -> Quantity Float TileLocalUnit
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId, to : Id UserId } }
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
                         , isStuck = Nothing
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
                         }
                            |> Train
                        )

                Nothing ->
                    Train
                        { train
                            | t = newTClamped
                            , isStuck =
                                case train.isStuck of
                                    Just _ ->
                                        train.isStuck

                                    Nothing ->
                                        Duration.from startTime endTime
                                            |> Quantity.multiplyBy (1 - Quantity.ratio distanceLeft initialDistance)
                                            |> Duration.addTo startTime
                                            |> Just
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
                            , isStuck = Nothing
                        }

            else
                Train { train | t = newTClamped }

        _ ->
            if newT < 0 || newT > 1 then
                reachedTileEnd ()

            else
                Train { train | t = newTClamped, isStuck = Nothing }


stoppedSpeed : Quantity Float units
stoppedSpeed =
    Quantity 0.1


home : Train -> Coord WorldUnit
home (Train train) =
    train.home


isStuck : Time.Posix -> Train -> Maybe Time.Posix
isStuck time (Train train) =
    case status time (Train train) of
        Travelling ->
            train.isStuck

        WaitingAtHome ->
            Nothing

        TeleportingHome _ ->
            train.isStuck

        StoppedAtPostOffice _ ->
            train.isStuck


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
    -> Time.Posix
    -> Point2d WorldUnit WorldUnit
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> List ( Coord CellUnit, Coord CellLocalUnit )
    -> Maybe TrainData
findNextTile trainId time position state speed_ direction list =
    case list of
        ( neighborCellPos, _ ) :: rest ->
            case Grid.getCell neighborCellPos state.grid of
                Just cell ->
                    case findNextTileHelper trainId time neighborCellPos position speed_ direction state (GridCell.flatten cell) of
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
    -> Time.Posix
    -> Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId, to : Id UserId } }
    -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> Maybe TrainData
findNextTileHelper trainId time neighborCellPos position speed_ direction state tiles =
    case tiles of
        tile :: rest ->
            let
                maybeNewTrain : Maybe TrainData
                maybeNewTrain =
                    case
                        List.filterMap
                            (checkPath trainId time tile state.mail neighborCellPos position speed_ direction)
                            (case Tile.getData tile.value |> .railPath of
                                NoRailPath ->
                                    []

                                SingleRailPath path1 ->
                                    [ path1 ]

                                DoubleRailPath path1 path2 ->
                                    [ path1, path2 ]
                            )
                    of
                        firstPath :: restOfPaths ->
                            Random.step
                                (Random.uniform firstPath restOfPaths)
                                (Time.posixToMillis time + Id.toInt trainId |> Random.initialSeed)
                                |> Tuple.first
                                |> Just

                        [] ->
                            Nothing
            in
            case maybeNewTrain of
                Just newTrain ->
                    Just newTrain

                Nothing ->
                    findNextTileHelper trainId time neighborCellPos position speed_ direction state rest

        [] ->
            Nothing


checkPath :
    Id TrainId
    -> Time.Posix
    -> { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> AssocList.Dict (Id MailId) { a | status : MailStatus, from : Id UserId, to : Id UserId }
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
                            (AssocList.values mail)
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


path : Time.Posix -> Train -> RailPath
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


trainT : Time.Posix -> Train -> Float
trainT time (Train train) =
    case status time (Train train) of
        WaitingAtHome ->
            0.5

        _ ->
            train.t


draw : Time.Posix -> AssocList.Dict (Id MailId) FrontendMail -> AssocList.Dict (Id TrainId) Train -> Mat4 -> Texture -> List WebGL.Entity
draw time mail trains viewMatrix trainTexture =
    List.concatMap
        (\( trainId, train ) ->
            let
                railData : RailData
                railData =
                    Tile.railPathData (path time train)

                { x, y } =
                    trainPosition time train |> Point2d.unwrap

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

                trainMesh : List WebGL.Entity
                trainMesh =
                    case status time train of
                        TeleportingHome teleportTime ->
                            let
                                t =
                                    Quantity.ratio (Duration.from teleportTime time) teleportLength

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
                                [ trainEntity trainTexture (trainEngineMesh t trainFrame) viewMatrix x y
                                , trainEntity
                                    trainTexture
                                    (trainEngineMesh (1 - t) trainFrame2)
                                    viewMatrix
                                    homePosition.x
                                    homePosition.y
                                ]

                        _ ->
                            case Array.get trainFrame trainEngineMeshes of
                                Just mesh ->
                                    [ trainEntity trainTexture mesh viewMatrix x y ]

                                Nothing ->
                                    []
            in
            trainMesh
                ++ (case carryingMail mail trainId of
                        Just _ ->
                            let
                                coach : Coach
                                coach =
                                    getCoach train

                                railData_ : RailData
                                railData_ =
                                    Tile.railPathData coach.path

                                coachPosition_ : { x : Float, y : Float }
                                coachPosition_ =
                                    coachPosition coach |> Point2d.unwrap

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
                            case status time train of
                                WaitingAtHome ->
                                    []

                                TeleportingHome teleportTime ->
                                    let
                                        t =
                                            Quantity.ratio (Duration.from teleportTime time) teleportLength
                                    in
                                    if t >= 1 then
                                        []

                                    else
                                        [ trainEntity
                                            trainTexture
                                            (trainCoachMesh t coachFrame)
                                            viewMatrix
                                            coachPosition_.x
                                            coachPosition_.y
                                        ]

                                _ ->
                                    case Array.get coachFrame trainCoachMeshes of
                                        Just trainMesh_ ->
                                            [ trainEntity
                                                trainTexture
                                                trainMesh_
                                                viewMatrix
                                                coachPosition_.x
                                                coachPosition_.y
                                            ]

                                        Nothing ->
                                            []

                        Nothing ->
                            []
                   )
        )
        (AssocList.toList trains)


startTeleportingHome : Time.Posix -> Train -> Train
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
                        train.status
        }


cancelTeleportingHome : Time.Posix -> Train -> Train
cancelTeleportingHome time (Train train) =
    Train
        { train
            | status =
                case status time (Train train) of
                    Travelling ->
                        train.status

                    TeleportingHome _ ->
                        Travelling

                    WaitingAtHome ->
                        train.status

                    StoppedAtPostOffice _ ->
                        train.status
        }


leaveHome : Time.Posix -> Train -> Train
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
                    , isStuck = Nothing
                    , speed = stoppedSpeed
                }

        StoppedAtPostOffice _ ->
            Train train


trainEntity : Texture -> WebGL.Mesh Vertex -> Mat4 -> Float -> Float -> WebGL.Entity
trainEntity trainTexture trainMesh viewMatrix x y =
    WebGL.entityWith
        [ WebGL.Settings.DepthTest.default, Shaders.blend ]
        Shaders.vertexShader
        Shaders.fragmentShader
        trainMesh
        { view =
            Mat4.makeTranslate3
                (x * Units.tileSize |> round |> toFloat)
                (y * Units.tileSize |> round |> toFloat)
                (Grid.tileZ True y 0)
                |> Mat4.mul viewMatrix
        , texture = trainTexture
        , textureSize = WebGL.Texture.size trainTexture |> Coord.tuple |> Coord.toVec2
        }


carryingMail :
    AssocList.Dict (Id MailId) { a | status : MailStatus }
    -> Id TrainId
    -> Maybe ( Id MailId, { a | status : MailStatus } )
carryingMail mail trainId =
    AssocList.toList mail
        |> List.find
            (\( _, mail_ ) ->
                case mail_.status of
                    MailInTransit mailTrainId ->
                        mailTrainId == trainId

                    _ ->
                        False
            )


trainFrames =
    32


trainEngineMeshes : Array (WebGL.Mesh Vertex)
trainEngineMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map (trainEngineMesh 0)
        |> Array.fromList


trainCoachMeshes : Array (WebGL.Mesh Vertex)
trainCoachMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map (trainCoachMesh 0)
        |> Array.fromList


trainEngineMesh : Float -> Int -> WebGL.Mesh Vertex
trainEngineMesh teleportAmount frame =
    let
        offsetX =
            sin (100 * teleportAmount) * min 1 (teleportAmount * 3)

        offsetY =
            -5

        y =
            toFloat frame * 36

        y2 =
            y + h - (teleportAmount * h)

        w =
            36

        h =
            36
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 (-Units.tileSize + offsetX) (-Units.tileSize + offsetY) 0
          , texturePosition = Vec2.vec2 0 y
          , opacity = 1
          }
        , { position = Vec3.vec3 (Units.tileSize + offsetX) (-Units.tileSize + offsetY) 0
          , texturePosition = Vec2.vec2 w y
          , opacity = 1
          }
        , { position = Vec3.vec3 (Units.tileSize + offsetX) (Units.tileSize + offsetY - (teleportAmount * h)) 0
          , texturePosition = Vec2.vec2 w y2
          , opacity = 1
          }
        , { position = Vec3.vec3 (-Units.tileSize + offsetX) (Units.tileSize + offsetY - (teleportAmount * h)) 0
          , texturePosition = Vec2.vec2 0 y2
          , opacity = 1
          }
        ]


trainCoachMesh : Float -> Int -> WebGL.Mesh Vertex
trainCoachMesh teleportAmount frame =
    let
        offsetX =
            sin (100 * teleportAmount) * min 1 (teleportAmount * 3)

        offsetY =
            -5

        y =
            toFloat frame * 36

        y2 =
            y + h - (teleportAmount * h)

        w =
            36

        h =
            36
    in
    Shaders.triangleFan
        [ { position = Vec3.vec3 (-Units.tileSize + offsetX) (-Units.tileSize + offsetY) 0
          , texturePosition = Vec2.vec2 w y
          , opacity = 1
          }
        , { position = Vec3.vec3 (Units.tileSize + offsetX) (-Units.tileSize + offsetY) 0
          , texturePosition = Vec2.vec2 (w * 2) y
          , opacity = 1
          }
        , { position = Vec3.vec3 (Units.tileSize + offsetX) (Units.tileSize + offsetY - (teleportAmount * h)) 0
          , texturePosition = Vec2.vec2 (w * 2) y2
          , opacity = 1
          }
        , { position = Vec3.vec3 (-Units.tileSize + offsetX) (Units.tileSize + offsetY - (teleportAmount * h)) 0
          , texturePosition = Vec2.vec2 w y2
          , opacity = 1
          }
        ]


handleAddingTrain : AssocList.Dict (Id TrainId) Train -> Tile -> Coord WorldUnit -> Maybe ( Id TrainId, Train )
handleAddingTrain trains tile position =
    if tile == TrainHouseLeft || tile == TrainHouseRight then
        let
            ( railPath, homePath ) =
                if tile == TrainHouseLeft then
                    ( Tile.trainHouseLeftRailPath, Tile.trainHouseLeftRailPath )

                else
                    ( Tile.trainHouseRightRailPath, Tile.trainHouseRightRailPath )
        in
        ( AssocList.toList trains
            |> List.map (Tuple.first >> Id.toInt)
            |> List.maximum
            |> Maybe.withDefault 0
            |> (+) 1
            |> Id.fromInt
        , Train
            { position = position
            , path = railPath
            , previousPaths = []
            , t = 0.5
            , speed = stoppedSpeed
            , home = position
            , homePath = homePath
            , isStuck = Nothing
            , status = WaitingAtHome
            }
        )
            |> Just

    else
        Nothing
