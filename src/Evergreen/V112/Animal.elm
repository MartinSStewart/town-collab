module Evergreen.V112.Animal exposing (..)

import Effect.Time
import Evergreen.V112.Point2d
import Evergreen.V112.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    , animalType : AnimalType
    }
