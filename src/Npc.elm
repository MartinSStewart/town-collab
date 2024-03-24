module Npc exposing
    ( Npc
    , actualPositionWithoutCursor
    , moveCollisionThreshold
    , moveEndTime
    , offset
    , size
    , walkingRightTexturePosition
    , walkingUpTexturePosition
    )

import Coord exposing (Coord)
import Duration exposing (Duration, Seconds)
import Effect.Time
import NpcName exposing (NpcName)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity, Rate)
import Units exposing (WorldUnit)


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


size : Coord Pixels
size =
    Coord.xy 10 17


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
