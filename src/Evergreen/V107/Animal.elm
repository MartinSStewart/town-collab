module Evergreen.V107.Animal exposing (..)

import Effect.Time
import Evergreen.V107.Point2d
import Evergreen.V107.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    , animalType : AnimalType
    }
