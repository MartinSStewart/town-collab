module Animal exposing
    ( Animal
    , AnimalData
    , AnimalType(..)
    , actualPositionWithoutCursor
    , all
    , animalTypeCodec
    , defaultColors
    , getData
    , inside
    , moveCollisionThreshold
    , moveEndTime
    )

import BoundingBox2d
import Codec exposing (Codec)
import Color exposing (Colors)
import Coord exposing (Coord)
import Duration exposing (Duration, Seconds)
import Effect.Time
import List.Nonempty exposing (Nonempty(..))
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity, Rate)
import Sound exposing (Sound(..))
import Units exposing (WorldUnit)
import Vector2d


type alias Animal =
    { position : Point2d WorldUnit WorldUnit
    , startTime : Effect.Time.Posix
    , endPosition : Point2d WorldUnit WorldUnit
    , animalType : AnimalType
    }


moveCollisionThreshold : Quantity Float WorldUnit
moveCollisionThreshold =
    Units.tileUnit 0.01


moveEndTime : Animal -> Effect.Time.Posix
moveEndTime animal =
    let
        travelTime : Duration
        travelTime =
            Point2d.distanceFrom animal.position animal.endPosition
                |> Quantity.at_ (getData animal.animalType).speed
    in
    Duration.addTo animal.startTime travelTime


actualPositionWithoutCursor : Effect.Time.Posix -> Animal -> Point2d WorldUnit WorldUnit
actualPositionWithoutCursor time animal =
    let
        currentDistance : Quantity Float WorldUnit
        currentDistance =
            Duration.from animal.startTime time
                |> Quantity.at (getData animal.animalType).speed

        distance : Quantity Float WorldUnit
        distance =
            Point2d.distanceFrom animal.position animal.endPosition
    in
    Quantity.ratio currentDistance distance
        |> clamp 0 1
        |> Point2d.interpolateFrom animal.position animal.endPosition


type AnimalType
    = Cow
    | Hamster
    | Sheep


type alias AnimalData =
    { size : Coord Pixels
    , texturePosition : Coord Pixels
    , walkTexturePosition : Coord Pixels
    , texturePositionFlipped : Coord Pixels
    , walkTexturePositionFlipped : Coord Pixels
    , sounds : Nonempty ( Float, Sound )
    , speed : Quantity Float (Rate WorldUnit Seconds)
    }


animalTypeCodec : Codec AnimalType
animalTypeCodec =
    Codec.enum
        Codec.string
        [ ( "Cow", Cow )
        , ( "Hamster", Hamster )
        , ( "Sheep", Sheep )
        ]


all : List AnimalType
all =
    [ Cow, Hamster, Sheep ]


getData : AnimalType -> AnimalData
getData animal =
    case animal of
        Cow ->
            { size = Coord.xy 20 14
            , texturePosition = Coord.xy 220 361
            , walkTexturePosition = Coord.xy 240 361
            , texturePositionFlipped = Coord.xy 260 361
            , walkTexturePositionFlipped = Coord.xy 280 361
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
            , speed = Quantity.per Duration.second (Units.tileUnit 1)
            }

        Hamster ->
            { size = Coord.xy 12 14
            , texturePosition = Coord.xy 220 392
            , walkTexturePosition = Coord.xy 232 392
            , texturePositionFlipped = Coord.xy 244 392
            , walkTexturePositionFlipped = Coord.xy 256 392
            , sounds = Nonempty ( 1 / 3, Hamster0 ) [ ( 1 / 3, Hamster1 ), ( 1 / 3, Hamster2 ) ]
            , speed = Quantity.per Duration.second (Units.tileUnit 2)
            }

        Sheep ->
            { size = Coord.xy 16 12
            , texturePosition = Coord.xy 220 378
            , walkTexturePosition = Coord.xy 236 378
            , texturePositionFlipped = Coord.xy 252 378
            , walkTexturePositionFlipped = Coord.xy 268 378
            , sounds = Nonempty ( 0.5, Sheep0 ) [ ( 0.5, Sheep1 ) ]
            , speed = Quantity.per Duration.second (Units.tileUnit 1.5)
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
