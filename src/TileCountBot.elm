module TileCountBot exposing
    ( Model
    , countCellsHelper
    , drawHighscore
    , init
    , name
    , onGridChanged
    )

import AssocList
import Change exposing (LocalChange)
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Effect.Time
import Grid exposing (Grid)
import GridCell exposing (BackendHistory)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import Shaders
import Tile exposing (TileGroup, TileGroupData)
import Units exposing (CellUnit, WorldUnit)
import Unsafe


type alias Model =
    { userId : Id UserId
    , tileUsage : AssocList.Dict TileGroup Int
    , changedCells : Dict RawCellCoord (List GridCell.Value)
    }


init : Id UserId -> Grid BackendHistory -> Model
init userId grid =
    let
        initialDict : AssocList.Dict TileGroup number
        initialDict =
            List.foldl (\group dict -> AssocList.insert group 0 dict) AssocList.empty Tile.allTileGroups
    in
    { userId = userId
    , tileUsage =
        Dict.foldl
            (\_ cell dict ->
                if GridCell.hasUserChanges cell then
                    countCellsHelper dict (GridCell.flatten cell)

                else
                    dict
            )
            initialDict
            (Grid.allCellsDict grid)
    , changedCells = Dict.empty
    }


countCellsHelper : AssocList.Dict TileGroup Int -> List GridCell.Value -> AssocList.Dict TileGroup Int
countCellsHelper dict flattenedCell =
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
        flattenedCell


onGridChanged : List (Coord CellUnit) -> Grid BackendHistory -> Model -> Model
onGridChanged changedCells grid model =
    { model
        | changedCells =
            List.foldl
                (\cellPos dict ->
                    Dict.update
                        (Coord.toTuple cellPos)
                        (\maybe ->
                            case maybe of
                                Just _ ->
                                    maybe

                                Nothing ->
                                    (case Grid.getCell cellPos grid of
                                        Just cell ->
                                            GridCell.flatten cell

                                        Nothing ->
                                            []
                                    )
                                        |> Just
                        )
                        dict
                )
                model.changedCells
                changedCells
    }


name : DisplayName
name =
    Unsafe.displayName "Tile count"


textColor : Colors
textColor =
    { primaryColor = Color.black, secondaryColor = Color.black }


drawHighscore : Bool -> Effect.Time.Posix -> Model -> Nonempty LocalChange
drawHighscore isFirstDraw time model =
    let
        title : List LocalChange
        title =
            List.indexedMap
                (\index char ->
                    { position = Coord.xy (Coord.xRaw position + index) (Coord.yRaw position)
                    , change = Tile.BigText char
                    , colors = textColor
                    , time = time
                    }
                        |> Change.LocalGridChange
                )
                (String.toList "Tile highscores (world gen tiles excluded)")

        newChanges : List LocalChange
        newChanges =
            AssocList.toList model.tileUsage
                |> List.sortBy (\( _, a ) -> -a)
                |> List.foldl
                    (\( tileGroup, count ) state ->
                        let
                            data : TileGroupData
                            data =
                                Tile.getTileGroupData tileGroup

                            tile =
                                List.Nonempty.head data.tiles

                            tileSize =
                                (Tile.getData tile).size

                            text =
                                String.fromInt count ++ " x "

                            height =
                                Coord.yRaw tileSize |> max 2

                            ( x2, y2, columnWidth ) =
                                if state.y + height - Coord.yRaw position > 30 then
                                    ( state.x + state.columnWidth + 1, Coord.yRaw position + 3, 0 )

                                else
                                    ( state.x
                                    , state.y
                                    , max state.columnWidth (String.length text + Coord.xRaw tileSize)
                                    )
                        in
                        { x = x2
                        , y = y2 + height
                        , columnWidth = columnWidth
                        , changes =
                            List.indexedMap
                                (\index char ->
                                    { position = Coord.xy (x2 + index) (y2 + (height - 1) // 2)
                                    , change = Tile.BigText char
                                    , colors = textColor
                                    , time = time
                                    }
                                        |> Change.LocalGridChange
                                )
                                (String.toList text)
                                ++ [ { position = Coord.xy (x2 + String.length text) y2
                                     , change = tile
                                     , colors = Tile.defaultToPrimaryAndSecondary data.defaultColors
                                     , time = time
                                     }
                                        |> Change.LocalGridChange
                                   ]
                                ++ state.changes
                        }
                    )
                    { x = Coord.xRaw position, y = Coord.yRaw position + 3, columnWidth = 0, changes = title }
                |> .changes
    in
    if isFirstDraw then
        Nonempty Change.LocalAddUndo newChanges

    else
        Nonempty Change.LocalUndo (Change.LocalAddUndo :: newChanges)


position : Coord WorldUnit
position =
    Coord.xy 203 -92
