module Evergreen.V126.Npc exposing (..)

import Effect.Time
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.Name
import Evergreen.V126.Point2d
import Evergreen.V126.Units
import List.Nonempty


type Voice
    = OldMan
    | OldWoman
    | Man
    | Woman
    | DistinguishedMan
    | DistinguishedWoman
    | EdgyTeenBoy
    | CoolKid
    | Nonbinary


type alias Npc =
    { name : Evergreen.V126.Name.Name
    , home : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , position : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , createdAt : Effect.Time.Posix
    , visitedPositions : List.Nonempty.Nonempty (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit)
    , skinColor : Evergreen.V126.Color.Color
    , clothColor : Evergreen.V126.Color.Color
    , voice : Voice
    }
