module Evergreen.V126.Animal exposing (..)

import Effect.Time
import Evergreen.V126.Name
import Evergreen.V126.Point2d
import Evergreen.V126.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep
    | Pig


type alias Animal =
    { position : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , animalType : AnimalType
    , name : Evergreen.V126.Name.Name
    }
