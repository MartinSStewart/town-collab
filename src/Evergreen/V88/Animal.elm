module Evergreen.V88.Animal exposing (..)

import Evergreen.V88.Point2d
import Evergreen.V88.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit
    , animalType : AnimalType
    }
