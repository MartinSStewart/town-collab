module Tile exposing
    ( Tile(..)
    , allTiles
    , fromChar
    , getData
    , size
    , texturePosition
    )

import Dict exposing (Dict)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


charToTile : Dict Char Tile
charToTile =
    List.map (\tile -> ( getData tile |> .char, tile )) allTiles |> Dict.fromList


fromChar : Char -> Maybe Tile
fromChar char =
    Dict.get char charToTile


size : ( Quantity number Pixels, Quantity number Pixels )
size =
    ( Pixels.pixels 18, Pixels.pixels 18 )


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
    | TrainHouseRight
    | TrainHouseLeft


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
    { topLeft = Math.Vector2.vec2 (toFloat x * tileW) (toFloat y * tileH)
    , bottomRight = Math.Vector2.vec2 (toFloat (x + w) * tileW) (toFloat (y + h) * tileH)
    }


type alias TileData =
    { texturePosition : ( Int, Int ), size : ( Int, Int ), char : Char }


allTiles : List Tile
allTiles =
    [ House
    , RailHorizontal
    , RailVertical
    , RailBottomToRight
    , RailBottomToLeft
    , RailTopToRight
    , RailTopToLeft
    , RailCrossing
    , RailStrafeUp
    , RailStrafeDown
    , RailStrafeLeft
    , RailStrafeRight
    , TrainHouseRight
    , TrainHouseLeft
    ]


getData : Tile -> TileData
getData tile =
    case tile of
        House ->
            { texturePosition = ( 0, 1 ), size = ( 3, 2 ), char = 'h' }

        RailHorizontal ->
            { texturePosition = ( 0, 0 ), size = ( 1, 1 ), char = 'r' }

        RailVertical ->
            { texturePosition = ( 1, 0 ), size = ( 1, 1 ), char = 'R' }

        RailBottomToRight ->
            { texturePosition = ( 3, 0 ), size = ( 4, 4 ), char = 'q' }

        RailBottomToLeft ->
            { texturePosition = ( 7, 0 ), size = ( 4, 4 ), char = 'w' }

        RailTopToRight ->
            { texturePosition = ( 3, 4 ), size = ( 4, 4 ), char = 'a' }

        RailTopToLeft ->
            { texturePosition = ( 7, 4 ), size = ( 4, 4 ), char = 's' }

        RailCrossing ->
            { texturePosition = ( 2, 0 ), size = ( 1, 1 ), char = 'e' }

        RailStrafeDown ->
            { texturePosition = ( 0, 8 ), size = ( 5, 3 ), char = 'Q' }

        RailStrafeUp ->
            { texturePosition = ( 5, 8 ), size = ( 5, 3 ), char = 'A' }

        RailStrafeLeft ->
            { texturePosition = ( 0, 11 ), size = ( 3, 5 ), char = 'W' }

        RailStrafeRight ->
            { texturePosition = ( 0, 16 ), size = ( 3, 5 ), char = 'S' }

        TrainHouseRight ->
            { texturePosition = ( 3, 11 ), size = ( 4, 4 ), char = 't' }

        TrainHouseLeft ->
            { texturePosition = ( 7, 11 ), size = ( 4, 4 ), char = 'T' }
