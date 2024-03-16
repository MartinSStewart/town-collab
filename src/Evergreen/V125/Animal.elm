module Evergreen.V125.Animal exposing (..)

import Effect.Time
import Evergreen.V125.Point2d
import Evergreen.V125.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    , animalType : AnimalType
    }
