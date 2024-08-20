module Evergreen.V134.Animal exposing (..)

import Effect.Time
import Evergreen.V134.Name
import Evergreen.V134.Point2d
import Evergreen.V134.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep
    | Pig


type alias Animal =
    { position : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , animalType : AnimalType
    , name : Evergreen.V134.Name.Name
    }
