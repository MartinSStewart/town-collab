module Npc exposing
    ( Npc
    , actualPositionWithoutCursor
    , idleTexturePosition
    , moveCollisionThreshold
    , moveEndTime
    , offset
    , randomMovement
    , size
    , textureSize
    , updateNpcPath
    , walkingRightTexturePosition
    , walkingUpTexturePosition
    )

import Angle
import Bounds exposing (Bounds)
import Coord exposing (Coord)
import Direction2d
import Direction4 exposing (Direction4(..), Turn(..))
import Duration exposing (Duration, Seconds)
import Effect.Time
import Grid exposing (Grid)
import GridCell
import Id exposing (Id, NpcId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import NpcName exposing (NpcName)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity, Rate)
import Random
import Tile exposing (Tile(..))
import Units exposing (CellUnit, WorldUnit)
import Vector2d exposing (Vector2d)


type alias Npc =
    { name : NpcName
    , home : Coord WorldUnit
    , position : Point2d WorldUnit WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Point2d WorldUnit WorldUnit
    , createdAt : Effect.Time.Posix
    , visitedPositions : Nonempty (Point2d WorldUnit WorldUnit)
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


navPoints : Tile -> List (Coord Pixels)
navPoints tile =
    case tile of
        Sidewalk ->
            [ Coord.xy 5 4, Coord.xy 15 4, Coord.xy 5 13, Coord.xy 15 13 ]

        DirtPathHorizontal ->
            [ Coord.xy 12 9, Coord.xy 12 27 ]

        DirtPathVertical ->
            [ Coord.xy 10 10, Coord.xy 10 26 ]

        _ ->
            []


maxNavPointDistance : Quantity Float WorldUnit
maxNavPointDistance =
    Units.tileUnit 1.5


maxNavPointVector : Vector2d WorldUnit coordinates
maxNavPointVector =
    Vector2d.xy maxNavPointDistance maxNavPointDistance


getNavPoints : Point2d WorldUnit WorldUnit -> Grid a -> List (Point2d WorldUnit WorldUnit)
getNavPoints npcPosition grid =
    let
        minPoint : Point2d WorldUnit WorldUnit
        minPoint =
            Point2d.translateBy (Vector2d.reverse maxNavPointVector) npcPosition

        maxPoint : Point2d WorldUnit WorldUnit
        maxPoint =
            Point2d.translateBy maxNavPointVector npcPosition

        cellBounds : Bounds CellUnit
        cellBounds =
            Bounds.fromCoords
                (Nonempty
                    (maxPoint |> Grid.worldToCellPoint |> Coord.floorPoint)
                    [ minPoint |> Grid.worldToCellPoint |> Coord.floorPoint ]
                )
    in
    Bounds.coordRangeFold
        (\cellCoord list ->
            case Grid.getCell cellCoord grid of
                Just cell ->
                    GridCell.flatten cell
                        |> List.concatMap
                            (\{ tile, position } ->
                                List.filterMap
                                    (\tileCoord ->
                                        let
                                            navPoint : Point2d WorldUnit WorldUnit
                                            navPoint =
                                                Units.pixelToTilePoint tileCoord
                                                    |> Point2d.translateBy (Grid.cellAndLocalCoordToWorld ( cellCoord, position ) |> Coord.toVector2d)

                                            distance : Quantity Float WorldUnit
                                            distance =
                                                Point2d.distanceFrom navPoint npcPosition
                                        in
                                        if (distance |> Quantity.lessThan maxNavPointDistance) && (distance |> Quantity.greaterThan (Quantity.unsafe 0.01)) then
                                            Just navPoint

                                        else
                                            Nothing
                                    )
                                    (navPoints tile)
                            )
                        |> (\a -> a ++ list)

                Nothing ->
                    list
        )
        identity
        cellBounds
        []


updateNpcPath : Effect.Time.Posix -> Grid a -> Id NpcId -> Npc -> Npc
updateNpcPath time grid npcId npc =
    if Duration.from time (moveEndTime npc) |> Quantity.lessThanOrEqualToZero then
        case getNavPoints npc.endPosition grid |> List.Extra.minimumBy (navPointWeighting npc) of
            Just head ->
                { npc
                    | position = npc.endPosition
                    , endPosition = head
                    , startTime = time
                    , visitedPositions = List.Nonempty.take 5 npc.visitedPositions |> List.Nonempty.cons npc.endPosition
                }

            Nothing ->
                npc

    else
        npc


navPointWeighting : Npc -> Point2d WorldUnit WorldUnit -> Float
navPointWeighting npc navPoint =
    List.Nonempty.foldl
        (\visited total ->
            2 / max (Quantity.unwrap (Point2d.distanceFrom navPoint visited)) 0.1
        )
        0
        npc.visitedPositions


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
