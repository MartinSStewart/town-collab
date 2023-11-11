module GridCell exposing
    ( BackendHistory(..)
    , Cell(..)
    , CellData(..)
    , FrontendHistory(..)
    , Value
    , addValue
    , cellToData
    , dataToCell
    , empty
    , flatten
    , getPostOffices
    , getToggledRailSplit
    , hasUserChanges
    , historyDecoder
    , latestChange
    , mapPixelData
    , moveUndoPoint
    , toggleRailSplit
    , updateCache
    )

import AssocSet
import Bitwise
import Bounds exposing (Bounds)
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Effect.Time
import Id exposing (Id, UserId)
import IdDict exposing (IdDict)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Math.Vector2 as Vec2 exposing (Vec2)
import Quantity exposing (Quantity(..))
import Random
import Shaders
import Terrain exposing (TerrainType(..))
import Tile exposing (Tile(..))
import Units exposing (CellLocalUnit, CellUnit, TerrainUnit)


type CellData
    = CellData
        { history : Bytes
        , undoPoint : IdDict UserId Int
        , railSplitToggled : AssocSet.Set (Coord CellLocalUnit)
        , cache : List Value
        }


valueEncoder : Value -> Bytes.Encode.Encoder
valueEncoder value =
    Bytes.Encode.sequence
        [ Bytes.Encode.unsignedInt16 BE (Id.toInt value.userId)
        , Bytes.Encode.signedInt8 (Coord.xRaw value.position)
        , Bytes.Encode.signedInt8 (Coord.yRaw value.position)
        , Bytes.Encode.unsignedInt16 BE (Tile.toInt value.tile)
        , colorsEncoder value.colors
        , Bytes.Encode.float64 BE (Effect.Time.posixToMillis value.time |> toFloat)
        ]


valueDecoder : Bytes.Decode.Decoder Value
valueDecoder =
    Bytes.Decode.map5
        (\id ( x, y ) tile colors time ->
            Value (Id.fromInt id) (Coord.xy x y) (Tile.fromInt tile) colors (Effect.Time.millisToPosix (round time))
        )
        (Bytes.Decode.unsignedInt16 BE)
        (Bytes.Decode.map2 Tuple.pair Bytes.Decode.signedInt8 Bytes.Decode.signedInt8)
        (Bytes.Decode.unsignedInt16 BE)
        colorsDecoder
        (Bytes.Decode.float64 BE)


colorsEncoder : Colors -> Bytes.Encode.Encoder
colorsEncoder colors =
    Bytes.Encode.sequence
        [ colorEncoder colors.primaryColor
        , colorEncoder colors.secondaryColor
        ]


colorsDecoder : Bytes.Decode.Decoder Colors
colorsDecoder =
    Bytes.Decode.map2 Colors colorDecoder colorDecoder


colorEncoder : Color -> Bytes.Encode.Encoder
colorEncoder color =
    Bytes.Encode.unsignedInt32 BE (Color.unwrap color)


colorDecoder : Bytes.Decode.Decoder Color
colorDecoder =
    Bytes.Decode.unsignedInt32 BE |> Bytes.Decode.map Color.unsafe


type FrontendHistory
    = FrontendEncoded Bytes
    | FrontendDecoded (List Value)


dataToCell : CellData -> Cell FrontendHistory
dataToCell (CellData cellData) =
    { history = FrontendEncoded cellData.history
    , undoPoint = cellData.undoPoint
    , cache = cellData.cache
    , railSplitToggled = cellData.railSplitToggled
    , mapCache = updateMapPixelData cellData.cache
    }
        |> Cell


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
        (\{ tile, position } { lowBit, highBit } ->
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
                    max currentValue (tileMapValue tile)

                newHighBit : Int
                newHighBit =
                    Bitwise.shiftRightBy 1 newValue |> Bitwise.and 1

                newLowBit : Int
                newLowBit =
                    Bitwise.and 1 newValue
            in
            { lowBit = Bitwise.shiftLeftBy index newLowBit |> Bitwise.or (zeroOutBit index lowBit)
            , highBit = Bitwise.shiftLeftBy index newHighBit |> Bitwise.or (zeroOutBit index highBit)
            }
        )
        { lowBit = 0, highBit = 0 }
        cache
        |> (\{ lowBit, highBit } -> Vec2.vec2 (toFloat lowBit) (toFloat highBit))


zeroOutBit : Int -> Int -> Int
zeroOutBit index value =
    Bitwise.shiftLeftBy index 1 |> Bitwise.complement |> Bitwise.and value


mapPixelData : Cell a -> Vec2
mapPixelData (Cell cell) =
    cell.mapCache


historyEncoder : List Value -> Bytes.Encode.Encoder
historyEncoder history =
    Bytes.Encode.unsignedInt32 BE (List.length history)
        :: List.map valueEncoder (List.reverse history)
        |> Bytes.Encode.sequence


historyDecoder : Bytes.Decode.Decoder (List Value)
historyDecoder =
    Bytes.Decode.andThen
        (\length ->
            Bytes.Decode.loop
                ( [], 0 )
                (\( list, count ) ->
                    if count < length then
                        Bytes.Decode.map (\a -> Bytes.Decode.Loop ( a :: list, count + 1 )) valueDecoder

                    else
                        Bytes.Decode.succeed (Bytes.Decode.Done list)
                )
        )
        (Bytes.Decode.unsignedInt32 BE)


cellToData : Cell BackendHistory -> ( Cell BackendHistory, CellData )
cellToData (Cell cell) =
    case cell.history of
        BackendEncodedAndDecoded bytes _ ->
            ( Cell cell
            , CellData
                { history = bytes
                , undoPoint = cell.undoPoint
                , railSplitToggled = cell.railSplitToggled
                , cache = cell.cache
                }
            )

        BackendDecoded history ->
            let
                bytes =
                    Bytes.Encode.encode (historyEncoder history)
            in
            ( Cell { cell | history = BackendEncodedAndDecoded bytes history }
            , CellData
                { history = bytes
                , undoPoint = cell.undoPoint
                , railSplitToggled = cell.railSplitToggled
                , cache = cell.cache
                }
            )


type BackendHistory
    = BackendDecoded (List Value)
    | BackendEncodedAndDecoded Bytes (List Value)


type Cell a
    = Cell
        { history : a
        , undoPoint : IdDict UserId Int
        , cache : List Value
        , railSplitToggled : AssocSet.Set (Coord CellLocalUnit)
        , mapCache : Vec2
        }


type alias Value =
    { userId : Id UserId, position : Coord CellLocalUnit, tile : Tile, colors : Colors, time : Effect.Time.Posix }


latestChange : Id UserId -> Cell BackendHistory -> Maybe Value
latestChange currentUser (Cell cell) =
    let
        history =
            case cell.history of
                BackendEncodedAndDecoded _ a ->
                    a

                BackendDecoded a ->
                    a
    in
    List.find
        (\value ->
            (value.userId /= currentUser)
                && (Coord.clamp Coord.origin (Coord.xy Units.cellSize Units.cellSize) value.position == value.position)
        )
        history


getPostOffices : Cell a -> List { position : Coord CellLocalUnit, userId : Id UserId }
getPostOffices cell =
    List.filterMap
        (\value ->
            if value.tile == PostOffice then
                Just { userId = value.userId, position = value.position }

            else
                Nothing
        )
        (flatten cell)


addValue : (a -> List Value) -> (List Value -> a) -> Value -> Cell a -> { cell : Cell a, removed : List Value }
addValue getHistory setHistory value (Cell cell) =
    let
        userUndoPoint =
            IdDict.get value.userId cell.undoPoint |> Maybe.withDefault 0

        { remaining, removed } =
            stepCacheHelperWithRemoved value cell.cache

        history : List Value
        history =
            getHistory cell.history
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
                    history
                    |> Tuple.first
                    |> (\list -> value :: list)
                    |> setHistory
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


updateCache : (a -> List Value) -> (List Value -> a -> a) -> Coord CellUnit -> Cell a -> Cell a
updateCache getHistory setHistory cellPosition (Cell cell) =
    let
        history : List Value
        history =
            getHistory cell.history

        cache : List Value
        cache =
            List.foldr
                stepCache
                { list = addTrees cellPosition, undoPoint = cell.undoPoint }
                history
                |> .list
    in
    { history = setHistory history cell.history
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
stepCache item state =
    case IdDict.get item.userId state.undoPoint of
        Just stepsLeft ->
            if stepsLeft > 0 then
                { list = stepCacheHelper item state.list
                , undoPoint = IdDict.insert item.userId (stepsLeft - 1) state.undoPoint
                }

            else
                state

        Nothing ->
            state


stepCacheHelper : Value -> List Value -> List Value
stepCacheHelper ({ position, tile } as item) cache =
    (if Bounds.contains position cellBounds then
        [ item ]

     else
        []
    )
        ++ List.filter
            (\item2 ->
                Tile.hasCollision position tile item2.position item2.tile
                    |> not
            )
            cache


stepCacheHelperWithRemoved : Value -> List Value -> { remaining : List Value, removed : List Value }
stepCacheHelperWithRemoved ({ position, tile } as item) cache =
    let
        ( remaining, removed ) =
            List.partition
                (\item2 ->
                    Tile.hasCollision position tile item2.position item2.tile
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


moveUndoPoint : (a -> List Value) -> (List Value -> a -> a) -> Id UserId -> Int -> Coord CellUnit -> Cell a -> Cell a
moveUndoPoint getHistory setHistory userId moveAmount cellPosition (Cell cell) =
    Cell
        { history = cell.history
        , undoPoint = IdDict.update2 userId ((+) moveAmount) cell.undoPoint
        , cache = cell.cache
        , railSplitToggled = cell.railSplitToggled
        , mapCache = cell.mapCache
        }
        |> updateCache getHistory setHistory cellPosition


flatten : Cell a -> List Value
flatten (Cell cell) =
    cell.cache


hasUserChanges : Cell BackendHistory -> Bool
hasUserChanges (Cell cell) =
    case cell.history of
        BackendDecoded values ->
            List.isEmpty values |> not

        BackendEncodedAndDecoded _ values ->
            List.isEmpty values |> not


empty : a -> Coord CellUnit -> Cell a
empty emptyHistory cellPosition =
    Cell
        { history = emptyHistory
        , undoPoint = IdDict.empty
        , cache = addTrees cellPosition
        , railSplitToggled = AssocSet.empty
        , mapCache = Vec2.vec2 0 0
        }


toggleRailSplit : Coord CellLocalUnit -> Cell a -> Cell a
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


getToggledRailSplit : Cell a -> AssocSet.Set (Coord CellLocalUnit)
getToggledRailSplit (Cell cell) =
    cell.railSplitToggled


addTrees : ( Quantity Int CellUnit, Quantity Int CellUnit ) -> List Value
addTrees (( Quantity cellX, Quantity cellY ) as cellPosition) =
    let
        treeColor =
            Tile.defaultToPrimaryAndSecondary Tile.defaultPineTreeColor

        berryBushColor =
            Tile.defaultToPrimaryAndSecondary Tile.defaultBerryBushColor

        mushroomColor =
            Tile.defaultToPrimaryAndSecondary Tile.defaultMushroomColor

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
                                , tile = item
                                , colors =
                                    if item == PineTree1 || item == PineTree2 || item == BigPineTree then
                                        treeColor

                                    else if item == BerryBush1 || item == BerryBush2 then
                                        berryBushColor

                                    else if item == Mushroom1 || item == Mushroom2 then
                                        mushroomColor

                                    else
                                        rockColor
                                , time = Effect.Time.millisToPosix 0
                                }
                                    :: cell2
                            )
                            cell

                else
                    cell
            )
            []
