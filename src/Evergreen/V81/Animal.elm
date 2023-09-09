module Evergreen.V81.Animal exposing (..)

import Evergreen.V81.Point2d
import Evergreen.V81.Units


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias Animal =
    { position : Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit
    , animalType : AnimalType
    }
