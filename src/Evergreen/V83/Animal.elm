module Evergreen.V83.Animal exposing (..)

import Evergreen.V83.Point2d
import Evergreen.V83.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit
    , animalType : AnimalType
    }
