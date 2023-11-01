module Evergreen.V95.Animal exposing (..)

import Effect.Time
import Evergreen.V95.Point2d
import Evergreen.V95.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
    , animalType : AnimalType
    }
