module Tile exposing
    ( Tile(..)
    , fromChar
    , getData
    , size
    , textureHeight
    , texturePosition
    , textureWidth
    )

import Dict exposing (Dict)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


charToTile : Dict Char Tile
charToTile =
    Dict.fromList
        [ ( 'h', House )
        , ( 'r', RailHorizontal )
        , ( 'R', RailVertical )
        , ( 'q', RailBottomToRight )
        , ( 'w', RailBottomToLeft )
        , ( 'a', RailTopToRight )
        , ( 's', RailTopToLeft )
        , ( 'e', RailCrossing )
        , ( 'Q', RailStrafeUp )
        , ( 'A', RailStrafeDown )
        , ( 'W', RailStrafeLeft )
        , ( 'S', RailStrafeRight )
        ]


fromChar : Char -> Maybe Tile
fromChar char =
    Dict.get char charToTile


size : ( Quantity number Pixels, Quantity number Pixels )
size =
    ( Pixels.pixels 18, Pixels.pixels 18 )


textureWidth : Quantity number Pixels
textureWidth =
    Pixels.pixels 256


textureHeight : Quantity number Pixels
textureHeight =
    Pixels.pixels 512


type Tile
    = House
    | RailHorizontal
    | RailVertical
    | RailBottomToRight
    | RailBottomToLeft
    | RailTopToRight
    | RailTopToLeft
    | RailCrossing
    | RailStrafeDown
    | RailStrafeUp
    | RailStrafeLeft
    | RailStrafeRight


texturePosition : Tile -> { topLeft : Vec2, bottomRight : Vec2 }
texturePosition tile =
    let
        ( Quantity.Quantity tileW, Quantity.Quantity tileH ) =
            size

        data =
            getData tile

        ( x, y ) =
            data.texturePosition

        ( w, h ) =
            data.size
    in
    { topLeft = Math.Vector2.vec2 (x * tileW) (y * tileH)
    , bottomRight = Math.Vector2.vec2 ((x + w) * tileW) ((y + h) * tileH)
    }


getData : Tile -> { texturePosition : ( number, number ), size : ( number, number ) }
getData tile =
    case tile of
        House ->
            { texturePosition = ( 0, 1 ), size = ( 3, 2 ) }

        RailHorizontal ->
            { texturePosition = ( 0, 0 ), size = ( 1, 1 ) }

        RailVertical ->
            { texturePosition = ( 1, 0 ), size = ( 1, 1 ) }

        RailBottomToRight ->
            { texturePosition = ( 3, 0 ), size = ( 4, 4 ) }

        RailBottomToLeft ->
            { texturePosition = ( 7, 0 ), size = ( 4, 4 ) }

        RailTopToRight ->
            { texturePosition = ( 3, 4 ), size = ( 4, 4 ) }

        RailTopToLeft ->
            { texturePosition = ( 7, 4 ), size = ( 4, 4 ) }

        RailCrossing ->
            { texturePosition = ( 2, 0 ), size = ( 1, 1 ) }

        RailStrafeDown ->
            { texturePosition = ( 0, 8 ), size = ( 5, 3 ) }

        RailStrafeUp ->
            { texturePosition = ( 5, 8 ), size = ( 5, 3 ) }

        RailStrafeLeft ->
            { texturePosition = ( 0, 11 ), size = ( 3, 5 ) }

        RailStrafeRight ->
            { texturePosition = ( 0, 16 ), size = ( 3, 5 ) }
