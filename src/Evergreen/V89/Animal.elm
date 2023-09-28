module Evergreen.V89.Animal exposing (..)

import Evergreen.V89.Point2d
import Evergreen.V89.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit
    , animalType : AnimalType
    }
