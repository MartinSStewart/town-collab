module Evergreen.V85.Animal exposing (..)

import Evergreen.V85.Point2d
import Evergreen.V85.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit
    , animalType : AnimalType
    }
