module Evergreen.V77.Animal exposing (..)

import Evergreen.V77.Point2d
import Evergreen.V77.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit
    , animalType : AnimalType
    }
