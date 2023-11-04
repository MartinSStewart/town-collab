module Evergreen.V106.Animal exposing (..)

import Effect.Time
import Evergreen.V106.Point2d
import Evergreen.V106.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    , animalType : AnimalType
    }
