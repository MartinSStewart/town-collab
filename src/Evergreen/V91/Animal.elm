module Evergreen.V91.Animal exposing (..)

import Evergreen.V91.Point2d
import Evergreen.V91.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit
    , animalType : AnimalType
    }
