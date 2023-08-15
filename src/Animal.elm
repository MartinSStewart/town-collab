module Animal exposing
    ( Animal
    , AnimalData
    , AnimalType(..)
    , all
    , defaultColors
    , getData
    , inside
    )

import BoundingBox2d
import Color exposing (Colors)
import Coord exposing (Coord)
import List.Nonempty exposing (Nonempty(..))
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Sound exposing (Sound(..))
import Units exposing (WorldUnit)
import Vector2d


type alias Animal =
    { position : Point2d WorldUnit WorldUnit
    , animalType : AnimalType
    }


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias AnimalData =
    { size : Coord Pixels
    , texturePosition : Coord Pixels
    , sounds : Nonempty ( Float, Sound )
    }


all : List AnimalType
all =
    [ Cow, Hamster, Sheep ]


getData : AnimalType -> AnimalData
getData animal =
    case animal of
        Cow ->
            { size = Coord.xy 20 14
            , texturePosition = Coord.xy 99 594
            , sounds =
                Nonempty
                    ( 1 / 6, Moo0 )
                    [ ( 1 / 6, Moo1 )
                    , ( 1 / 12, Moo2 )
                    , ( 1 / 12, Moo3 )
                    , ( 1 / 6, Moo4 )
                    , ( 1 / 6, Moo5 )
                    , ( 1 / 6, Moo6 )
                    ]
            }

        Hamster ->
            { size = Coord.xy 12 14
            , texturePosition = Coord.xy 141 594
            , sounds = Nonempty ( 1 / 3, Hamster0 ) [ ( 1 / 3, Hamster1 ), ( 1 / 3, Hamster2 ) ]
            }

        Sheep ->
            { size = Coord.xy 16 12
            , texturePosition = Coord.xy 99 608
            , sounds = Nonempty ( 0.5, Sheep0 ) [ ( 0.5, Sheep1 ) ]
            }


defaultColors : Colors
defaultColors =
    { primaryColor = Color.white, secondaryColor = Color.rgb255 30 30 30 }


inside : Point2d WorldUnit WorldUnit -> Animal -> Bool
inside point animal =
    let
        ( width, height ) =
            getData animal.animalType |> .size |> Coord.toTuple

        size =
            Vector2d.unsafe
                { x = toFloat width / toFloat Units.tileWidth
                , y = toFloat height / toFloat Units.tileHeight
                }
    in
    BoundingBox2d.from
        (Point2d.translateBy (Vector2d.scaleBy 0.5 size) animal.position)
        (Point2d.translateBy (Vector2d.scaleBy -0.5 size) animal.position)
        |> BoundingBox2d.contains point
