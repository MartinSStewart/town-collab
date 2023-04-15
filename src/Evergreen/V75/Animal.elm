module Evergreen.V75.Animal exposing (..)

import Evergreen.V75.Point2d
import Evergreen.V75.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit
    , animalType : AnimalType
    }
