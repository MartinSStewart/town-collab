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
    , mapPixelData
    , moveUndoPoint
    , removeUser
    , toggleRailSplit
    , updateCache
    )

import AssocSet
import Bitwise
import Bounds exposing (Bounds)
import Color exposing (Colors)
import Coord exposing (Coord)
import Id exposing (Id, UserId)
import IdDict exposing (IdDict)
import List.Nonempty exposing (Nonempty(..))
import Math.Vector2 as Vec2 exposing (Vec2)
import Quantity exposing (Quantity(..))
import Random
import Shaders exposing (MapOverlayVertex)
import Terrain exposing (TerrainType(..))
import Tile exposing (Tile(..))
import Units exposing (CellLocalUnit, CellUnit, TerrainUnit)


type CellData
    = CellData
        { history : List Value
        , undoPoint : IdDict UserId Int
        , railSplitToggled : AssocSet.Set (Coord CellLocalUnit)
        , cache : List Value
        }


dataToCell : Coord CellUnit -> CellData -> Cell
dataToCell cellPosition (CellData cellData) =
    { history = cellData.history
    , undoPoint = cellData.undoPoint
    , cache = cellData.cache
    , railSplitToggled = cellData.railSplitToggled
    , mapCache = updateMapPixelData cellData.cache
    }
        |> Cell
        |> updateCache cellPosition


tileMapValue : Tile -> number
tileMapValue value =
    case value of
        BigPineTree ->
            1

        PineTree1 ->
            1

        PineTree2 ->
            1

        RockDown ->
            1

        RockLeft ->
            1

        RockRight ->
            1

        RockUp ->
            1

        ElmTree ->
            1

        EmptyTile ->
            0

        RailHorizontal ->
            3

        RailVertical ->
            3

        RailBottomToRight ->
            3

        RailBottomToLeft ->
            3

        RailTopToRight ->
            3

        RailTopToLeft ->
            3

        RailBottomToRightLarge ->
            3

        RailBottomToLeftLarge ->
            3

        RailTopToRightLarge ->
            3

        RailTopToLeftLarge ->
            3

        RailCrossing ->
            3

        RailStrafeDown ->
            3

        RailStrafeUp ->
            3

        RailStrafeLeft ->
            3

        RailStrafeRight ->
            3

        TrainHouseRight ->
            3

        TrainHouseLeft ->
            3

        RailStrafeDownSmall ->
            3

        RailStrafeUpSmall ->
            3

        RailStrafeLeftSmall ->
            3

        RailStrafeRightSmall ->
            3

        RailBottomToRight_SplitLeft ->
            3

        RailBottomToLeft_SplitUp ->
            3

        RailTopToRight_SplitDown ->
            3

        RailTopToLeft_SplitRight ->
            3

        RailBottomToRight_SplitUp ->
            3

        RailBottomToLeft_SplitRight ->
            3

        RailTopToRight_SplitLeft ->
            3

        RailTopToLeft_SplitDown ->
            3

        PostOffice ->
            3

        RoadRailCrossingHorizontal ->
            3

        RoadRailCrossingVertical ->
            3

        SidewalkHorizontalRailCrossing ->
            3

        SidewalkVerticalRailCrossing ->
            3

        _ ->
            2


updateMapPixelData : List Value -> Vec2
updateMapPixelData cache =
    List.foldl
        (\{ value, position } { lowBit, highBit } ->
            let
                terrainPos : Coord TerrainUnit
                terrainPos =
                    Terrain.localCoordToTerrain position

                index : Int
                index =
                    Coord.xRaw terrainPos + Coord.yRaw terrainPos * Terrain.terrainDivisionsPerCell

                currentValue : Int
                currentValue =
                    Bitwise.and 1 (Bitwise.shiftRightZfBy index lowBit)
                        + (Bitwise.and 1 (Bitwise.shiftRightZfBy index highBit) * 2)

                newValue : Int
                newValue =
                    max currentValue (tileMapValue value)

                newHighBit : Int
                newHighBit =
                    Bitwise.shiftRightBy 1 newValue |> Bitwise.and 1

                newLowBit : Int
                newLowBit =
                    Bitwise.and 1 newValue

                --_ =
                --    if newHighBit > 1 || newLowBit > 1 || currentValue > 2 || newValue > 2 then
                --        Debug.todo ""
                --
                --    else
                --        ()
            in
            { lowBit = Bitwise.shiftLeftBy index newLowBit |> Bitwise.or lowBit
            , highBit = Bitwise.shiftLeftBy index newHighBit |> Bitwise.or highBit
            }
        )
        { lowBit = 0, highBit = 0 }
        cache
        |> (\{ lowBit, highBit } -> Vec2.vec2 (toFloat lowBit) (toFloat highBit))


mapPixelData : Cell -> Vec2
mapPixelData (Cell cell) =
    cell.mapCache


cellToData : Cell -> CellData
cellToData (Cell cell) =
    CellData
        { history = cell.history
        , undoPoint = cell.undoPoint
        , railSplitToggled = cell.railSplitToggled
        , cache = cell.cache
        }


type Cell
    = Cell
        { history : List Value
        , undoPoint : IdDict UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Coord CellLocalUnit)
        , mapCache : Vec2
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
            IdDict.get value.userId cell.undoPoint |> Maybe.withDefault 0

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
            , undoPoint = IdDict.insert value.userId (userUndoPoint + 1) cell.undoPoint
            , cache = remaining
            , railSplitToggled = cell.railSplitToggled
            , mapCache = updateMapPixelData remaining
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
    let
        cache =
            List.foldr
                stepCache
                { list = addTrees cellPosition, undoPoint = cell.undoPoint }
                cell.history
                |> .list
    in
    { history = cell.history
    , undoPoint = cell.undoPoint
    , cache = cache
    , railSplitToggled = cell.railSplitToggled
    , mapCache = updateMapPixelData cache
    }
        |> Cell


stepCache :
    Value
    -> { list : List Value, undoPoint : IdDict UserId number }
    -> { list : List Value, undoPoint : IdDict UserId number }
stepCache ({ userId, position, value } as item) state =
    case IdDict.get userId state.undoPoint of
        Just stepsLeft ->
            if stepsLeft > 0 then
                { list = stepCacheHelper item state.list
                , undoPoint = IdDict.insert userId (stepsLeft - 1) state.undoPoint
                }

            else
                state

        Nothing ->
            state


stepCacheHelper : Value -> List Value -> List Value
stepCacheHelper ({ userId, position, value } as item) cache =
    (if Bounds.contains position cellBounds then
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
        (if Bounds.contains position cellBounds then
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
        , undoPoint = IdDict.remove userId cell.undoPoint
        , cache = cell.cache
        , railSplitToggled = cell.railSplitToggled
        , mapCache = cell.mapCache
        }
        |> updateCache cellPosition


hasChangesBy : Id UserId -> Cell -> Bool
hasChangesBy userId (Cell cell) =
    IdDict.member userId cell.undoPoint


moveUndoPoint : Id UserId -> Int -> Coord CellUnit -> Cell -> Cell
moveUndoPoint userId moveAmount cellPosition (Cell cell) =
    Cell
        { history = cell.history
        , undoPoint = IdDict.update userId (Maybe.map ((+) moveAmount)) cell.undoPoint
        , cache = cell.cache
        , railSplitToggled = cell.railSplitToggled
        , mapCache = cell.mapCache
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
    Cell
        { history = []
        , undoPoint = IdDict.empty
        , cache = addTrees cellPosition
        , railSplitToggled = AssocSet.empty
        , mapCache = Vec2.vec2 0 0
        }


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
        , mapCache = cell.mapCache
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
                                { userId = Shaders.worldGenUserId
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
