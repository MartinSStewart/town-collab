module Evergreen.V97.Animal exposing (..)

import Effect.Time
import Evergreen.V97.Point2d
import Evergreen.V97.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
    , animalType : AnimalType
    }
