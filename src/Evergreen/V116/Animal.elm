module Evergreen.V116.Animal exposing (..)

import Effect.Time
import Evergreen.V116.Point2d
import Evergreen.V116.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    , animalType : AnimalType
    }
