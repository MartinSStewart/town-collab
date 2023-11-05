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
import Color
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Effect.Time
import Grid exposing (Grid, GridChange)
import GridCell exposing (BackendHistory)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import Shaders
import Tile exposing (Tile, TileGroup, TileGroupData)
import Units exposing (WorldUnit)
import Unsafe


type alias Model =
    { userId : Id UserId
    , tileUsage : AssocList.Dict TileGroup Int
    , changedCells : Dict RawCellCoord (List GridCell.Value)
    }


init : Id UserId -> Grid BackendHistory -> Model
init userId grid =
    let
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


onGridChanged : Grid.LocalGridChange -> Grid BackendHistory -> Model -> Model
onGridChanged localChange grid model =
    let
        ( cellPos, _ ) =
            Grid.worldToCellAndLocalCoord localChange.position
    in
    { model
        | changedCells =
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
                model.changedCells
    }


name : DisplayName
name =
    Unsafe.displayName "Tile count"


textColor =
    { primaryColor = Color.black, secondaryColor = Color.black }


drawHighscore : Bool -> Effect.Time.Posix -> Model -> Nonempty LocalChange
drawHighscore isFirstDraw time model =
    let
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

                            text =
                                String.fromInt count ++ " x "

                            height =
                                Tile.getData tile |> .size |> Coord.yRaw |> max 2
                        in
                        { y = state.y + height
                        , changes =
                            List.indexedMap
                                (\index char ->
                                    { position = Coord.xy (Coord.xRaw position + index) (state.y + (height - 1) // 2)
                                    , change = Tile.BigText char
                                    , colors = textColor
                                    , time = time
                                    }
                                        |> Change.LocalGridChange
                                )
                                (String.toList text)
                                ++ [ { position = Coord.xy (Coord.xRaw position + String.length text) state.y
                                     , change = tile
                                     , colors = Tile.defaultToPrimaryAndSecondary data.defaultColors
                                     , time = time
                                     }
                                        |> Change.LocalGridChange
                                   ]
                                ++ state.changes
                        }
                    )
                    { y = Coord.yRaw position, changes = [] }
                |> .changes
    in
    if isFirstDraw then
        Nonempty Change.LocalAddUndo newChanges

    else
        Nonempty Change.LocalUndo (Change.LocalAddUndo :: newChanges)


position : Coord WorldUnit
position =
    Coord.xy -228 -879
