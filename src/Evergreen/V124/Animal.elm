module Evergreen.V124.Animal exposing (..)

import Effect.Time
import Evergreen.V124.Point2d
import Evergreen.V124.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    , animalType : AnimalType
    }
