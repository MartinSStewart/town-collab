module Evergreen.V123.Animal exposing (..)

import Effect.Time
import Evergreen.V123.Point2d
import Evergreen.V123.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    , animalType : AnimalType
    }
