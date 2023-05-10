module Evergreen.V76.Animal exposing (..)

import Evergreen.V76.Point2d
import Evergreen.V76.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit
    , animalType : AnimalType
    }
