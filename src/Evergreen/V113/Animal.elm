module Evergreen.V113.Animal exposing (..)

import Effect.Time
import Evergreen.V113.Point2d
import Evergreen.V113.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    , animalType : AnimalType
    }
