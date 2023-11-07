module Evergreen.V108.Animal exposing (..)

import Effect.Time
import Evergreen.V108.Point2d
import Evergreen.V108.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    , animalType : AnimalType
    }
