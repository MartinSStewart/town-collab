module Evergreen.V111.Animal exposing (..)

import Effect.Time
import Evergreen.V111.Point2d
import Evergreen.V111.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    , animalType : AnimalType
    }
