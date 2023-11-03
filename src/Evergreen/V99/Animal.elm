module Evergreen.V99.Animal exposing (..)

import Effect.Time
import Evergreen.V99.Point2d
import Evergreen.V99.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    , animalType : AnimalType
    }
