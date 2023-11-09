module Evergreen.V109.Animal exposing (..)

import Effect.Time
import Evergreen.V109.Point2d
import Evergreen.V109.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    , animalType : AnimalType
    }
