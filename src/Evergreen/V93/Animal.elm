module Evergreen.V93.Animal exposing (..)

import Evergreen.V93.Point2d
import Evergreen.V93.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit
    , animalType : AnimalType
    }
