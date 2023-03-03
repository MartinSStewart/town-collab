module Evergreen.V74.Animal exposing (..)

import Evergreen.V74.Point2d
import Evergreen.V74.Units


type AnimalType
    = Cow
    | Hamster


type alias Animal =
    { position : Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit
    , animalType : AnimalType
    }
