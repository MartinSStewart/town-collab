module Evergreen.V134.Npc exposing (..)

import Effect.Time
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.Name
import Evergreen.V134.Point2d
import Evergreen.V134.Units
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
    { name : Evergreen.V134.Name.Name
    , home : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , position : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , createdAt : Effect.Time.Posix
    , visitedPositions : List.Nonempty.Nonempty (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit)
    , skinColor : Evergreen.V134.Color.Color
    , clothColor : Evergreen.V134.Color.Color
    , voice : Voice
    }
