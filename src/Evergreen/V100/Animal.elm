module Evergreen.V100.Animal exposing (..)

import Effect.Time
import Evergreen.V100.Point2d
import Evergreen.V100.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    , animalType : AnimalType
    }
