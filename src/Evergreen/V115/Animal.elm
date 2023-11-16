module Evergreen.V115.Animal exposing (..)

import Effect.Time
import Evergreen.V115.Point2d
import Evergreen.V115.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    , animalType : AnimalType
    }
