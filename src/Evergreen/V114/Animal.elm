module Evergreen.V114.Animal exposing (..)

import Effect.Time
import Evergreen.V114.Point2d
import Evergreen.V114.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    , animalType : AnimalType
    }
