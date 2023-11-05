module TileUsageBot exposing (Model, drawHighscore, init)

import AssocList
import Color
import Coord exposing (Coord)
import Dict exposing (Dict)
import Effect.Time
import Grid exposing (Grid, GridChange)
import GridCell exposing (BackendHistory)
import List.Nonempty
import Shaders
import Tile exposing (Tile, TileGroup, TileGroupData)
import Units exposing (WorldUnit)


type alias Model =
    { tileUsage : AssocList.Dict TileGroup Int
    , changedCells : Dict ( Int, Int ) (List GridCell.Value)
    }


init : Grid BackendHistory -> Model
init grid =
    let
        initialDict =
            List.foldl (\group dict -> AssocList.insert group 0 dict) AssocList.empty Tile.allTileGroups
    in
    { tileUsage =
        Dict.foldl
            (\_ cell dict ->
                if GridCell.hasUserChanges cell then
                    List.foldl
                        (\value dict2 ->
                            if value.userId == Shaders.worldGenUserId then
                                dict2

                            else
                                case Tile.tileToTileGroup value.tile of
                                    Just { tileGroup } ->
                                        AssocList.update
                                            tileGroup
                                            (\a -> Maybe.withDefault 0 a |> (+) 1 |> Just)
                                            dict2

                                    Nothing ->
                                        dict2
                        )
                        dict
                        (GridCell.flatten cell)

                else
                    dict
            )
            initialDict
            (Grid.allCellsDict grid)
    , changedCells = Dict.empty
    }


textColor =
    { primaryColor = Color.black, secondaryColor = Color.black }


drawHighscore : Effect.Time.Posix -> Model -> List Grid.LocalGridChange
drawHighscore time model =
    AssocList.toList model.tileUsage
        |> List.sortBy Tuple.second
        |> List.foldl
            (\( tileGroup, count ) state ->
                let
                    data : TileGroupData
                    data =
                        Tile.getTileGroupData tileGroup

                    tile =
                        List.Nonempty.head data.tiles

                    text =
                        String.fromInt count ++ " x "
                in
                { y = Tile.getData tile |> .size |> Coord.yRaw |> (+) state.y
                , changes =
                    List.indexedMap
                        (\index char ->
                            { position = Coord.xy (Coord.xRaw position + index) state.y
                            , change = Tile.BigText char
                            , colors = textColor
                            , time = time
                            }
                        )
                        (String.toList text)
                        ++ [ { position = Coord.xy (Coord.xRaw position + String.length text) state.y
                             , change = tile
                             , colors = Tile.defaultToPrimaryAndSecondary data.defaultColors
                             , time = time
                             }
                           ]
                        ++ state.changes
                }
            )
            { y = Coord.yRaw position, changes = [] }
        |> .changes


position : Coord WorldUnit
position =
    Coord.xy 228 879
