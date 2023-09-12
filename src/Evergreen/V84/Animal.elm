module Evergreen.V84.Animal exposing (..)

import Evergreen.V84.Point2d
import Evergreen.V84.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit
    , animalType : AnimalType
    }
