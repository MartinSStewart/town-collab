module Train exposing (Train, actualPosition, defaultMaxSpeed, draw, getCoach, moveTrain)

import Angle
import Array exposing (Array)
import AssocList
import Coord exposing (Coord)
import Direction2d exposing (Direction2d)
import Duration exposing (Duration, Seconds)
import Grid exposing (Grid, Vertex)
import GridCell
import Id exposing (Id, MailId, TrainId, UserId)
import MailEditor exposing (FrontendMail, MailStatus(..))
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector3 as Vec3
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Shaders
import Tile exposing (Direction, RailData, RailPath, RailPathType(..), Tile(..))
import Time
import Units exposing (CellLocalUnit, CellUnit, TileLocalUnit, WorldUnit)
import WebGL
import WebGL.Settings.DepthTest
import WebGL.Texture exposing (Texture)


type alias Train =
    { position : Coord WorldUnit
    , path : RailPath
    , previousPaths : List PreviousPath
    , t : Float
    , speed : Quantity Float (Rate TileLocalUnit Seconds)
    , stoppedAtPostOffice : Maybe { time : Time.Posix, userId : Id UserId }
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
getCoach train =
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

        { path } =
            Tile.railPathData train.path
    in
    { position = coach.position
    , path = coach.path
    , t = coach.t
    }


actualPosition : { a | position : Coord WorldUnit, path : RailPath, t : Float } -> Point2d WorldUnit WorldUnit
actualPosition train =
    let
        { path } =
            Tile.railPathData train.path
    in
    Grid.localTilePointPlusWorld train.position (path train.t)


acceleration =
    1


defaultMaxSpeed : number
defaultMaxSpeed =
    5


moveTrain :
    Float
    -> Time.Posix
    -> Time.Posix
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId } }
    -> Train
    -> Train
moveTrain maxSpeed startTime endTime state train =
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
    moveTrainHelper startTime distance state { train | speed = Quantity newSpeed }


moveTrainHelper :
    Time.Posix
    -> Quantity Float TileLocalUnit
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId } }
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
                    moveTrainHelper
                        time
                        (distanceLeft |> Quantity.minus distanceTravelled)
                        state
                        { position = newTrain.position
                        , path = newTrain.path
                        , previousPaths =
                            { position = train.position, path = train.path, reversed = newT > 0.5 }
                                :: List.take 3 train.previousPaths
                        , t = newTrain.t
                        , speed = newTrain.speed
                        , stoppedAtPostOffice = newTrain.stoppedAtPostOffice
                        }

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
    Time.Posix
    -> Point2d WorldUnit WorldUnit
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId } }
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> List ( Coord CellUnit, Coord CellLocalUnit )
    -> Maybe TrainData
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
    -> { a | grid : Grid, mail : AssocList.Dict (Id MailId) { b | status : MailStatus, from : Id UserId } }
    -> List { userId : Id UserId, position : Coord CellLocalUnit, value : Tile }
    -> Maybe TrainData
findNextTileHelper time neighborCellPos position speed direction state tiles =
    case tiles of
        tile :: rest ->
            let
                maybeNewTrain : Maybe TrainData
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
    -> AssocList.Dict (Id MailId) { a | status : MailStatus, from : Id UserId }
    -> Coord CellUnit
    -> Point2d WorldUnit WorldUnit
    -> Quantity Float (Rate TileLocalUnit Seconds)
    -> Direction
    -> RailPath
    -> Maybe TrainData
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
                        (\mail_ -> tile.userId == mail_.from && mail_.status == MailWaitingPickup)
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


draw : AssocList.Dict (Id MailId) FrontendMail -> AssocList.Dict (Id TrainId) Train -> Mat4 -> Texture -> List WebGL.Entity
draw mail trains viewMatrix trainTexture =
    List.concatMap
        (\( trainId, train ) ->
            let
                railData =
                    Tile.railPathData train.path

                { x, y } =
                    actualPosition train |> Point2d.unwrap

                trainFrame =
                    Direction2d.angleFrom
                        Direction2d.x
                        (Tile.pathDirection railData.path train.t
                            |> (if Quantity.lessThanZero train.speed then
                                    Direction2d.reverse

                                else
                                    identity
                               )
                        )
                        |> Angle.inTurns
                        |> (*) trainFrames
                        |> round
                        |> modBy trainFrames

                drawCoach =
                    AssocList.values mail
                        |> List.any
                            (\mail_ ->
                                case mail_.status of
                                    MailInTransit mailTrainId ->
                                        mailTrainId == trainId

                                    _ ->
                                        False
                            )
            in
            (case Array.get trainFrame trainEngineMeshes of
                Just trainMesh_ ->
                    [ WebGL.entityWith
                        [ WebGL.Settings.DepthTest.default, Shaders.blend ]
                        Shaders.vertexShader
                        Shaders.fragmentShader
                        trainMesh_
                        { view = Mat4.makeTranslate3 (x * Units.tileSize) (y * Units.tileSize) (Grid.tileZ True y 0) |> Mat4.mul viewMatrix
                        , texture = trainTexture
                        , textureSize = WebGL.Texture.size trainTexture |> Coord.fromTuple |> Coord.toVec2
                        }
                    ]

                Nothing ->
                    []
            )
                ++ (if drawCoach then
                        let
                            coach =
                                getCoach train

                            railData_ =
                                Tile.railPathData coach.path

                            coachPosition =
                                actualPosition coach |> Point2d.unwrap

                            coachFrame =
                                Direction2d.angleFrom
                                    Direction2d.x
                                    (Tile.pathDirection railData_.path coach.t
                                        |> (if Quantity.lessThanZero train.speed then
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
                        case Array.get coachFrame trainCoachMeshes of
                            Just trainMesh_ ->
                                [ WebGL.entityWith
                                    [ WebGL.Settings.DepthTest.default, Shaders.blend ]
                                    Shaders.vertexShader
                                    Shaders.fragmentShader
                                    trainMesh_
                                    { view =
                                        Mat4.makeTranslate3
                                            (coachPosition.x * Units.tileSize)
                                            (coachPosition.y * Units.tileSize)
                                            (Grid.tileZ True coachPosition.y 0)
                                            |> Mat4.mul viewMatrix
                                    , texture = trainTexture
                                    , textureSize = WebGL.Texture.size trainTexture |> Coord.fromTuple |> Coord.toVec2
                                    }
                                ]

                            Nothing ->
                                []

                    else
                        []
                   )
        )
        (AssocList.toList trains)


trainFrames =
    32


trainEngineMeshes : Array (WebGL.Mesh Vertex)
trainEngineMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map trainEngineMesh
        |> Array.fromList


trainCoachMeshes : Array (WebGL.Mesh Vertex)
trainCoachMeshes =
    List.range 0 (trainFrames - 1)
        |> List.map trainCoachMesh
        |> Array.fromList


trainEngineMesh : Int -> WebGL.Mesh Vertex
trainEngineMesh frame =
    let
        offsetY =
            -5

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePosition_ ( 0, frame * 2 ) ( 2, 2 )
    in
    WebGL.triangleFan
        [ { position = Vec3.vec3 -Units.tileSize (-Units.tileSize + offsetY) 0, texturePosition = topLeft }
        , { position = Vec3.vec3 Units.tileSize (-Units.tileSize + offsetY) 0, texturePosition = topRight }
        , { position = Vec3.vec3 Units.tileSize (Units.tileSize + offsetY) 0, texturePosition = bottomRight }
        , { position = Vec3.vec3 -Units.tileSize (Units.tileSize + offsetY) 0, texturePosition = bottomLeft }
        ]


trainCoachMesh : Int -> WebGL.Mesh Vertex
trainCoachMesh frame =
    let
        offsetY =
            -5

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePosition_ ( 2, frame * 2 ) ( 2, 2 )
    in
    WebGL.triangleFan
        [ { position = Vec3.vec3 -Units.tileSize (-Units.tileSize + offsetY) 0, texturePosition = topLeft }
        , { position = Vec3.vec3 Units.tileSize (-Units.tileSize + offsetY) 0, texturePosition = topRight }
        , { position = Vec3.vec3 Units.tileSize (Units.tileSize + offsetY) 0, texturePosition = bottomRight }
        , { position = Vec3.vec3 -Units.tileSize (Units.tileSize + offsetY) 0, texturePosition = bottomLeft }
        ]
