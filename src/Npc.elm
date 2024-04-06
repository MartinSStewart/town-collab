module Npc exposing
    ( Npc
    , actualPositionWithoutCursor
    , getNpcPath
    , idleTexturePosition
    , moveCollisionThreshold
    , moveEndTime
    , offset
    , randomMovement
    , size
    , textureSize
    , walkingRightTexturePosition
    , walkingUpTexturePosition
    )

import Angle
import Coord exposing (Coord)
import Direction2d
import Direction4 exposing (Direction4(..), Turn(..))
import Duration exposing (Duration, Seconds)
import Effect.Time
import Grid exposing (Grid)
import Id exposing (Id, NpcId)
import NpcName exposing (NpcName)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity, Rate)
import Random
import Tile exposing (Tile(..))
import Units exposing (WorldUnit)
import Vector2d


type alias Npc =
    { name : NpcName
    , home : Coord WorldUnit
    , position : Point2d WorldUnit WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Point2d WorldUnit WorldUnit
    , createdAt : Effect.Time.Posix
    }


moveCollisionThreshold : Quantity Float WorldUnit
moveCollisionThreshold =
    Units.tileUnit 0.01


walkSpeed : Quantity Float (Rate WorldUnit Seconds)
walkSpeed =
    Quantity.per Duration.second (Units.tileUnit 2)


walkingUpTexturePosition : Int -> Coord Pixels
walkingUpTexturePosition frameNumber =
    Coord.xy 484 (modBy 5 frameNumber * 17)


idleTexturePosition : Coord Pixels
idleTexturePosition =
    Coord.xy 494 0


offset : Coord Pixels
offset =
    Coord.xy -5 -15


textureSize : Coord Pixels
textureSize =
    Coord.xy 10 17


size : Coord Pixels
size =
    Coord.xy 8 5


walkingRightTexturePosition : Int -> Coord Pixels
walkingRightTexturePosition frameNumber =
    Coord.xy 494 (modBy 6 frameNumber * 17 + 17)


moveEndTime : Npc -> Effect.Time.Posix
moveEndTime animal =
    let
        travelTime : Duration
        travelTime =
            Point2d.distanceFrom animal.position animal.endPosition
                |> Quantity.at_ walkSpeed
    in
    Duration.addTo animal.startTime travelTime


actualPositionWithoutCursor : Effect.Time.Posix -> Npc -> Point2d WorldUnit WorldUnit
actualPositionWithoutCursor time npc =
    let
        currentDistance : Quantity Float WorldUnit
        currentDistance =
            Duration.from npc.startTime time
                |> Quantity.at walkSpeed

        distance : Quantity Float WorldUnit
        distance =
            Point2d.distanceFrom npc.position npc.endPosition
    in
    Quantity.ratio currentDistance distance
        |> clamp 0 1
        |> Point2d.interpolateFrom npc.position npc.endPosition


isNpcWalkable : Grid a -> Coord WorldUnit -> Bool
isNpcWalkable grid npcPosition =
    case Grid.getTile npcPosition grid of
        Just { tile } ->
            case tile of
                Tile.Sidewalk ->
                    True

                Tile.DirtPathHorizontal ->
                    True

                Tile.DirtPathVertical ->
                    True

                Tile.SidewalkHorizontalRailCrossing ->
                    True

                Tile.SidewalkVerticalRailCrossing ->
                    True

                Tile.RoadSidewalkCrossingHorizontal ->
                    True

                Tile.RoadSidewalkCrossingVertical ->
                    True

                _ ->
                    False

        Nothing ->
            False


walkablePoints : Tile -> List (Coord Pixels)
walkablePoints tile =
    case tile of
        Sidewalk ->
            [ Coord.xy 5 4, Coord.xy 15 4, Coord.xy 5 13, Coord.xy 15 13 ]

        DirtPathHorizontal ->
            [ Coord.xy 12 9, Coord.xy 12 27 ]

        DirtPathVertical ->
            [ Coord.xy 10 10, Coord.xy 10 26 ]

        _ ->
            []


getNpcPath :
    Id NpcId
    -> Effect.Time.Posix
    -> Grid a
    -> Point2d WorldUnit WorldUnit
    -> Maybe Direction4
    -> Maybe { endPosition : Point2d WorldUnit WorldUnit, delay : Duration }
getNpcPath npcId time grid position maybePreviousDirection =
    let
        gridPosition =
            Coord.floorPoint position

        seed =
            Random.initialSeed (Id.toInt npcId + Effect.Time.posixToMillis time)

        choices : List ( Float, Direction4 )
        choices =
            (case maybePreviousDirection of
                Just previousDirection ->
                    [ ( 0.33, previousDirection )
                    , ( 0.33, Direction4.turn TurnLeft previousDirection )
                    , ( 0.33, Direction4.turn TurnRight previousDirection )
                    , ( 0.01, Direction4.turn TurnAround previousDirection )
                    ]

                Nothing ->
                    [ ( 0.25, North ), ( 0.25, South ), ( 0.25, East ), ( 0.25, West ) ]
            )
                |> List.filter (\( _, direction ) -> isNpcWalkable grid (Coord.translateIn direction 1 gridPosition))
    in
    case choices of
        head :: rest ->
            let
                maybeNewPosition : Maybe (Coord WorldUnit)
                maybeNewPosition =
                    Random.step
                        (Random.weighted head rest
                            |> Random.andThen
                                (\direction ->
                                    getNpcPathHelper grid (Coord.translateIn direction 1 gridPosition) direction 10
                                )
                            |> Random.map Just
                        )
                        seed
                        |> Tuple.first
            in
            case maybeNewPosition of
                Just newPosition ->
                    { endPosition =
                        Coord.toPoint2d newPosition
                            |> Point2d.translateBy (Vector2d.fromTuple Units.tileUnit ( 0.5, 0.5 ))
                    , delay = Quantity.zero
                    }
                        |> Just

                Nothing ->
                    Nothing

        [] ->
            Random.step (randomMovement position) seed |> Tuple.first


getNpcPathHelper : Grid a -> Coord WorldUnit -> Direction4 -> Int -> Random.Generator (Coord WorldUnit)
getNpcPathHelper grid position direction stepsLeft =
    let
        forwardPosition : Coord WorldUnit
        forwardPosition =
            Coord.translateIn direction 1 position
    in
    if stepsLeft > 0 && isNpcWalkable grid forwardPosition then
        Random.weighted
            ( 0.8, True )
            (if
                isNpcWalkable grid (Coord.translateIn (Direction4.turn TurnRight direction) 1 position)
                    || isNpcWalkable grid (Coord.translateIn (Direction4.turn TurnLeft direction) 1 position)
             then
                [ ( 0.2, False ) ]

             else
                []
            )
            |> Random.andThen
                (\moveForward ->
                    if moveForward then
                        getNpcPathHelper grid forwardPosition direction (stepsLeft - 1)

                    else
                        Random.constant position
                )

    else
        Random.constant position


randomMovement :
    Point2d WorldUnit WorldUnit
    -> Random.Generator (Maybe { endPosition : Point2d WorldUnit WorldUnit, delay : Duration })
randomMovement position =
    Random.map4
        (\shouldMove direction distance delay ->
            if shouldMove == 0 then
                { endPosition =
                    Point2d.translateIn
                        (Direction2d.fromAngle (Angle.degrees direction))
                        (Units.tileUnit distance)
                        position
                , delay = Duration.seconds delay
                }
                    |> Just

            else
                Nothing
        )
        (Random.int 0 2)
        (Random.float 0 360)
        (Random.float 2 10)
        (Random.float 1 1.5)
