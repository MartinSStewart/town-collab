module Evergreen.V110.Animal exposing (..)

import Effect.Time
import Evergreen.V110.Point2d
import Evergreen.V110.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit
    , animalType : AnimalType
    }
