module Evergreen.V82.Animal exposing (..)

import Evergreen.V82.Point2d
import Evergreen.V82.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit
    , animalType : AnimalType
    }
