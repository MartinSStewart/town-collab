module GridCell exposing
    ( Cell(..)
    , CellData
    , Value
    , addValue
    , cellToData
    , changeCount
    , dataToCell
    , empty
    , flatten
    , getPostOffices
    , getToggledRailSplit
    , hasChangesBy
    , moveUndoPoint
    , removeUser
    , toggleRailSplit
    , updateCache
    )

import AssocList
import AssocSet
import Bounds exposing (Bounds)
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Dict exposing (Dict)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import Quantity exposing (Quantity(..))
import Random
import Terrain exposing (TerrainType(..))
import Tile exposing (Tile(..))
import Units exposing (CellLocalUnit, CellUnit)


type CellData
    = CellData { history : List Value, undoPoint : Dict Int Int, railSplitToggled : AssocSet.Set (Coord CellLocalUnit) }


dataToCell : Coord CellUnit -> CellData -> Cell
dataToCell cellPosition (CellData cellData) =
    Cell { history = cellData.history, undoPoint = cellData.undoPoint, cache = [], railSplitToggled = cellData.railSplitToggled }
        |> updateCache cellPosition


cellToData : Cell -> CellData
cellToData (Cell cell) =
    CellData { history = cell.history, undoPoint = cell.undoPoint, railSplitToggled = cell.railSplitToggled }


type Cell
    = Cell
        { history : List Value
        , undoPoint : Dict Int Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Coord CellLocalUnit)
        }


type alias Value =
    { userId : Id UserId, position : Coord CellLocalUnit, value : Tile, colors : Colors }


getPostOffices : Cell -> List { position : Coord CellLocalUnit, userId : Id UserId }
getPostOffices (Cell cell) =
    if List.any (\{ value } -> value == PostOffice) cell.history then
        List.filterMap
            (\value ->
                if value.value == PostOffice then
                    Just { userId = value.userId, position = value.position }

                else
                    Nothing
            )
            cell.cache

    else
        []


addValue : Value -> Cell -> { cell : Cell, removed : List Value }
addValue value (Cell cell) =
    let
        userUndoPoint =
            Dict.get (Id.toInt value.userId) cell.undoPoint |> Maybe.withDefault 0

        { remaining, removed } =
            stepCacheHelperWithRemoved value cell.cache
    in
    { cell =
        Cell
            { history =
                List.foldr
                    (\change ( newHistory, counter ) ->
                        if change.userId == value.userId then
                            if counter > 0 then
                                ( change :: newHistory, counter - 1 )

                            else
                                ( newHistory, counter )

                        else
                            ( change :: newHistory, counter )
                    )
                    ( [], userUndoPoint )
                    cell.history
                    |> Tuple.first
                    |> (\list -> value :: list)
            , undoPoint =
                Dict.insert
                    (Id.toInt value.userId)
                    (userUndoPoint + 1)
                    cell.undoPoint
            , cache = remaining
            , railSplitToggled = cell.railSplitToggled
            }
    , removed = removed
    }


cellBounds : Bounds unit
cellBounds =
    Nonempty
        (Coord.tuple ( 0, 0 ))
        [ Coord.tuple ( Units.cellSize - 1, Units.cellSize - 1 ) ]
        |> Bounds.fromCoords


updateCache : Coord CellUnit -> Cell -> Cell
updateCache cellPosition (Cell cell) =
    { history = cell.history
    , undoPoint = cell.undoPoint
    , cache =
        List.foldr
            stepCache
            { list = addTrees cellPosition, undoPoint = cell.undoPoint }
            cell.history
            |> .list
    , railSplitToggled = cell.railSplitToggled
    }
        |> Cell


stepCache :
    Value
    -> { list : List Value, undoPoint : Dict Int number }
    -> { list : List Value, undoPoint : Dict Int number }
stepCache ({ userId, position, value } as item) state =
    case Dict.get (Id.toInt userId) state.undoPoint of
        Just stepsLeft ->
            if stepsLeft > 0 then
                { list = stepCacheHelper item state.list
                , undoPoint = Dict.insert (Id.toInt userId) (stepsLeft - 1) state.undoPoint
                }

            else
                state

        Nothing ->
            state


stepCacheHelper : Value -> List Value -> List Value
stepCacheHelper ({ userId, position, value } as item) cache =
    (if Bounds.contains position cellBounds && value /= EmptyTile then
        [ item ]

     else
        []
    )
        ++ List.filter
            (\item2 ->
                Tile.hasCollision position value item2.position item2.value
                    |> not
            )
            cache


stepCacheHelperWithRemoved : Value -> List Value -> { remaining : List Value, removed : List Value }
stepCacheHelperWithRemoved ({ userId, position, value } as item) cache =
    let
        ( remaining, removed ) =
            List.partition
                (\item2 ->
                    Tile.hasCollision position value item2.position item2.value
                        |> not
                )
                cache
    in
    { remaining =
        (if Bounds.contains position cellBounds && value /= EmptyTile then
            [ item ]

         else
            []
        )
            ++ remaining
    , removed = removed
    }


removeUser : Id UserId -> Coord CellUnit -> Cell -> Cell
removeUser userId cellPosition (Cell cell) =
    Cell
        { history = List.filter (.userId >> (==) userId) cell.history
        , undoPoint = Dict.remove (Id.toInt userId) cell.undoPoint
        , cache = cell.cache
        , railSplitToggled = cell.railSplitToggled
        }
        |> updateCache cellPosition


hasChangesBy : Id UserId -> Cell -> Bool
hasChangesBy userId (Cell cell) =
    Dict.member (Id.toInt userId) cell.undoPoint


moveUndoPoint : Id UserId -> Int -> Coord CellUnit -> Cell -> Cell
moveUndoPoint userId moveAmount cellPosition (Cell cell) =
    Cell
        { history = cell.history
        , undoPoint = Dict.update (Id.toInt userId) (Maybe.map ((+) moveAmount)) cell.undoPoint
        , cache = cell.cache
        , railSplitToggled = cell.railSplitToggled
        }
        |> updateCache cellPosition


changeCount : Cell -> Int
changeCount (Cell { history }) =
    List.length history


flatten : Cell -> List Value
flatten (Cell cell) =
    cell.cache


empty : Coord CellUnit -> Cell
empty cellPosition =
    Cell { history = [], undoPoint = Dict.empty, cache = addTrees cellPosition, railSplitToggled = AssocSet.empty }


toggleRailSplit : Coord CellLocalUnit -> Cell -> Cell
toggleRailSplit coord (Cell cell) =
    Cell
        { history = cell.history
        , undoPoint = cell.undoPoint
        , cache = cell.cache
        , railSplitToggled =
            if AssocSet.member coord cell.railSplitToggled then
                AssocSet.remove coord cell.railSplitToggled

            else
                AssocSet.insert coord cell.railSplitToggled
        }


getToggledRailSplit : Cell -> AssocSet.Set (Coord CellLocalUnit)
getToggledRailSplit (Cell cell) =
    cell.railSplitToggled


addTrees : ( Quantity Int CellUnit, Quantity Int CellUnit ) -> List Value
addTrees (( Quantity cellX, Quantity cellY ) as cellPosition) =
    let
        treeColor =
            Tile.defaultToPrimaryAndSecondary Tile.defaultPineTreeColor

        rockColor =
            Tile.defaultToPrimaryAndSecondary Tile.defaultRockColor
    in
    List.range 0 (Terrain.terrainDivisionsPerCell - 1)
        |> List.concatMap
            (\x ->
                List.range 0 (Terrain.terrainDivisionsPerCell - 1)
                    |> List.map (\y -> Terrain.terrainCoord x y)
            )
        |> List.foldl
            (\(( Quantity terrainX, Quantity terrainY ) as terrainCoord_) cell ->
                let
                    position : Coord CellLocalUnit
                    position =
                        Terrain.terrainToLocalCoord terrainCoord_

                    seed =
                        Random.initialSeed (cellX * 269 + cellY * 229 + terrainX * 67 + terrainY)

                    terrain =
                        Terrain.getTerrainValue terrainCoord_ cellPosition
                in
                if terrain.terrainType == Ground then
                    Random.step (Terrain.randomScenery terrain.value position) seed
                        |> Tuple.first
                        |> List.foldl
                            (\( item, itemPosition ) cell2 ->
                                { userId = Id.fromInt -1
                                , position = itemPosition
                                , value = item
                                , colors =
                                    if item == PineTree1 || item == PineTree2 || item == BigPineTree then
                                        treeColor

                                    else
                                        rockColor
                                }
                                    :: cell2
                            )
                            cell

                else
                    cell
            )
            []
