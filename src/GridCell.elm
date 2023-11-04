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
    , hasChangesBy
    , historyDecoder
    , latestChange
    , mapPixelData
    , moveUndoPoint
    , tileFromInt
    , tileToInt
    , toggleRailSplit
    , updateCache
    )

import Array
import AssocSet
import Bitwise
import Bounds exposing (Bounds)
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode
import Bytes.Encode
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Dict
import Effect.Time
import Id exposing (Id, UserId)
import IdDict exposing (IdDict)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Math.Vector2 as Vec2 exposing (Vec2)
import Quantity exposing (Quantity(..))
import Random
import Shaders exposing (MapOverlayVertex)
import Sprite
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
        , Bytes.Encode.unsignedInt16 BE (tileToInt value.tile)
        , colorsEncoder value.colors
        , Bytes.Encode.float64 BE (Effect.Time.posixToMillis value.time |> toFloat)
        ]


valueDecoder : Bytes.Decode.Decoder Value
valueDecoder =
    Bytes.Decode.map5
        (\id ( x, y ) tile colors time ->
            Value (Id.fromInt id) (Coord.xy x y) (tileFromInt tile) colors (Effect.Time.millisToPosix (round time))
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


tileToInt : Tile -> Int
tileToInt tile =
    case tile of
        EmptyTile ->
            0

        HouseDown ->
            1

        HouseRight ->
            2

        HouseUp ->
            3

        HouseLeft ->
            4

        RailHorizontal ->
            5

        RailVertical ->
            6

        RailBottomToRight ->
            7

        RailBottomToLeft ->
            8

        RailTopToRight ->
            9

        RailTopToLeft ->
            10

        RailBottomToRightLarge ->
            11

        RailBottomToLeftLarge ->
            12

        RailTopToRightLarge ->
            13

        RailTopToLeftLarge ->
            14

        RailCrossing ->
            15

        RailStrafeDown ->
            16

        RailStrafeUp ->
            17

        RailStrafeLeft ->
            18

        RailStrafeRight ->
            19

        TrainHouseRight ->
            20

        TrainHouseLeft ->
            21

        RailStrafeDownSmall ->
            22

        RailStrafeUpSmall ->
            23

        RailStrafeLeftSmall ->
            24

        RailStrafeRightSmall ->
            25

        Sidewalk ->
            26

        SidewalkHorizontalRailCrossing ->
            27

        SidewalkVerticalRailCrossing ->
            28

        RailBottomToRight_SplitLeft ->
            29

        RailBottomToLeft_SplitUp ->
            30

        RailTopToRight_SplitDown ->
            31

        RailTopToLeft_SplitRight ->
            32

        RailBottomToRight_SplitUp ->
            33

        RailBottomToLeft_SplitRight ->
            34

        RailTopToRight_SplitLeft ->
            35

        RailTopToLeft_SplitDown ->
            36

        PostOffice ->
            37

        PineTree1 ->
            38

        PineTree2 ->
            39

        BigPineTree ->
            40

        LogCabinDown ->
            41

        LogCabinRight ->
            42

        LogCabinUp ->
            43

        LogCabinLeft ->
            44

        RoadHorizontal ->
            45

        RoadVertical ->
            46

        RoadBottomToLeft ->
            47

        RoadTopToLeft ->
            48

        RoadTopToRight ->
            49

        RoadBottomToRight ->
            50

        Road4Way ->
            51

        RoadSidewalkCrossingHorizontal ->
            52

        RoadSidewalkCrossingVertical ->
            53

        Road3WayDown ->
            54

        Road3WayLeft ->
            55

        Road3WayUp ->
            56

        Road3WayRight ->
            57

        RoadRailCrossingHorizontal ->
            58

        RoadRailCrossingVertical ->
            59

        FenceHorizontal ->
            60

        FenceVertical ->
            61

        FenceDiagonal ->
            62

        FenceAntidiagonal ->
            63

        RoadDeadendUp ->
            64

        RoadDeadendDown ->
            65

        BusStopDown ->
            66

        BusStopLeft ->
            67

        BusStopRight ->
            68

        BusStopUp ->
            69

        Hospital ->
            70

        Statue ->
            71

        HedgeRowDown ->
            72

        HedgeRowLeft ->
            73

        HedgeRowRight ->
            74

        HedgeRowUp ->
            75

        HedgeCornerDownLeft ->
            76

        HedgeCornerDownRight ->
            77

        HedgeCornerUpLeft ->
            78

        HedgeCornerUpRight ->
            79

        HedgePillarDownLeft ->
            80

        HedgePillarDownRight ->
            81

        HedgePillarUpLeft ->
            82

        HedgePillarUpRight ->
            83

        ApartmentDown ->
            84

        ApartmentLeft ->
            85

        ApartmentRight ->
            86

        ApartmentUp ->
            87

        RockDown ->
            88

        RockLeft ->
            89

        RockRight ->
            90

        RockUp ->
            91

        Flowers1 ->
            92

        Flowers2 ->
            93

        ElmTree ->
            94

        DirtPathHorizontal ->
            95

        DirtPathVertical ->
            96

        Hyperlink ->
            97

        BenchDown ->
            98

        BenchLeft ->
            99

        BenchUp ->
            100

        BenchRight ->
            101

        ParkingDown ->
            102

        ParkingLeft ->
            103

        ParkingUp ->
            104

        ParkingRight ->
            105

        ParkingRoad ->
            106

        ParkingRoundabout ->
            107

        CornerHouseUpLeft ->
            108

        CornerHouseUpRight ->
            109

        CornerHouseDownLeft ->
            110

        CornerHouseDownRight ->
            111

        DogHouseDown ->
            112

        DogHouseRight ->
            113

        DogHouseUp ->
            114

        DogHouseLeft ->
            115

        Mushroom1 ->
            116

        Mushroom2 ->
            117

        TreeStump1 ->
            118

        TreeStump2 ->
            119

        Sunflowers ->
            120

        RailDeadEndLeft ->
            121

        RailDeadEndRight ->
            122

        RailStrafeLeftToRight_SplitUp ->
            123

        RailStrafeLeftToRight_SplitDown ->
            124

        RailStrafeRightToLeft_SplitUp ->
            125

        RailStrafeRightToLeft_SplitDown ->
            126

        RailStrafeTopToBottom_SplitLeft ->
            127

        RailStrafeTopToBottom_SplitRight ->
            128

        RailStrafeBottomToTop_SplitLeft ->
            129

        RailStrafeBottomToTop_SplitRight ->
            130

        RoadManholeDown ->
            131

        RoadManholeLeft ->
            132

        RoadManholeUp ->
            133

        RoadManholeRight ->
            134

        BigText char ->
            maxTileValue - Maybe.withDefault 0 (Dict.get char Sprite.charToInt)


tileFromInt : Int -> Tile
tileFromInt int =
    case int of
        0 ->
            EmptyTile

        1 ->
            HouseDown

        2 ->
            HouseRight

        3 ->
            HouseUp

        4 ->
            HouseLeft

        5 ->
            RailHorizontal

        6 ->
            RailVertical

        7 ->
            RailBottomToRight

        8 ->
            RailBottomToLeft

        9 ->
            RailTopToRight

        10 ->
            RailTopToLeft

        11 ->
            RailBottomToRightLarge

        12 ->
            RailBottomToLeftLarge

        13 ->
            RailTopToRightLarge

        14 ->
            RailTopToLeftLarge

        15 ->
            RailCrossing

        16 ->
            RailStrafeDown

        17 ->
            RailStrafeUp

        18 ->
            RailStrafeLeft

        19 ->
            RailStrafeRight

        20 ->
            TrainHouseRight

        21 ->
            TrainHouseLeft

        22 ->
            RailStrafeDownSmall

        23 ->
            RailStrafeUpSmall

        24 ->
            RailStrafeLeftSmall

        25 ->
            RailStrafeRightSmall

        26 ->
            Sidewalk

        27 ->
            SidewalkHorizontalRailCrossing

        28 ->
            SidewalkVerticalRailCrossing

        29 ->
            RailBottomToRight_SplitLeft

        30 ->
            RailBottomToLeft_SplitUp

        31 ->
            RailTopToRight_SplitDown

        32 ->
            RailTopToLeft_SplitRight

        33 ->
            RailBottomToRight_SplitUp

        34 ->
            RailBottomToLeft_SplitRight

        35 ->
            RailTopToRight_SplitLeft

        36 ->
            RailTopToLeft_SplitDown

        37 ->
            PostOffice

        38 ->
            PineTree1

        39 ->
            PineTree2

        40 ->
            BigPineTree

        41 ->
            LogCabinDown

        42 ->
            LogCabinRight

        43 ->
            LogCabinUp

        44 ->
            LogCabinLeft

        45 ->
            RoadHorizontal

        46 ->
            RoadVertical

        47 ->
            RoadBottomToLeft

        48 ->
            RoadTopToLeft

        49 ->
            RoadTopToRight

        50 ->
            RoadBottomToRight

        51 ->
            Road4Way

        52 ->
            RoadSidewalkCrossingHorizontal

        53 ->
            RoadSidewalkCrossingVertical

        54 ->
            Road3WayDown

        55 ->
            Road3WayLeft

        56 ->
            Road3WayUp

        57 ->
            Road3WayRight

        58 ->
            RoadRailCrossingHorizontal

        59 ->
            RoadRailCrossingVertical

        60 ->
            FenceHorizontal

        61 ->
            FenceVertical

        62 ->
            FenceDiagonal

        63 ->
            FenceAntidiagonal

        64 ->
            RoadDeadendUp

        65 ->
            RoadDeadendDown

        66 ->
            BusStopDown

        67 ->
            BusStopLeft

        68 ->
            BusStopRight

        69 ->
            BusStopUp

        70 ->
            Hospital

        71 ->
            Statue

        72 ->
            HedgeRowDown

        73 ->
            HedgeRowLeft

        74 ->
            HedgeRowRight

        75 ->
            HedgeRowUp

        76 ->
            HedgeCornerDownLeft

        77 ->
            HedgeCornerDownRight

        78 ->
            HedgeCornerUpLeft

        79 ->
            HedgeCornerUpRight

        80 ->
            HedgePillarDownLeft

        81 ->
            HedgePillarDownRight

        82 ->
            HedgePillarUpLeft

        83 ->
            HedgePillarUpRight

        84 ->
            ApartmentDown

        85 ->
            ApartmentLeft

        86 ->
            ApartmentRight

        87 ->
            ApartmentUp

        88 ->
            RockDown

        89 ->
            RockLeft

        90 ->
            RockRight

        91 ->
            RockUp

        92 ->
            Flowers1

        93 ->
            Flowers2

        94 ->
            ElmTree

        95 ->
            DirtPathHorizontal

        96 ->
            DirtPathVertical

        97 ->
            Hyperlink

        98 ->
            BenchDown

        99 ->
            BenchLeft

        100 ->
            BenchUp

        101 ->
            BenchRight

        102 ->
            ParkingDown

        103 ->
            ParkingLeft

        104 ->
            ParkingUp

        105 ->
            ParkingRight

        106 ->
            ParkingRoad

        107 ->
            ParkingRoundabout

        108 ->
            CornerHouseUpLeft

        109 ->
            CornerHouseUpRight

        110 ->
            CornerHouseDownLeft

        111 ->
            CornerHouseDownRight

        112 ->
            DogHouseDown

        113 ->
            DogHouseRight

        114 ->
            DogHouseUp

        115 ->
            DogHouseLeft

        116 ->
            Mushroom1

        117 ->
            Mushroom2

        118 ->
            TreeStump1

        119 ->
            TreeStump2

        120 ->
            Sunflowers

        121 ->
            RailDeadEndLeft

        122 ->
            RailDeadEndRight

        123 ->
            RailStrafeLeftToRight_SplitUp

        124 ->
            RailStrafeLeftToRight_SplitDown

        125 ->
            RailStrafeRightToLeft_SplitUp

        126 ->
            RailStrafeRightToLeft_SplitDown

        127 ->
            RailStrafeTopToBottom_SplitLeft

        128 ->
            RailStrafeTopToBottom_SplitRight

        129 ->
            RailStrafeBottomToTop_SplitLeft

        130 ->
            RailStrafeBottomToTop_SplitRight

        131 ->
            RoadManholeDown

        132 ->
            RoadManholeLeft

        133 ->
            RoadManholeUp

        134 ->
            RoadManholeRight

        _ ->
            --maxTileValue - Maybe.withDefault 0 (Dict.get char Sprite.charToInt)
            case Array.get (maxTileValue - int) Sprite.intToChar of
                Just char ->
                    BigText char

                Nothing ->
                    BigText '?'


maxTileValue =
    (2 ^ 16) - 1


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
stepCache ({ userId, position, tile } as item) state =
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
stepCacheHelper ({ userId, position, tile } as item) cache =
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
stepCacheHelperWithRemoved ({ userId, position, tile } as item) cache =
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


hasChangesBy : Id UserId -> Cell a -> Bool
hasChangesBy userId (Cell cell) =
    IdDict.member userId cell.undoPoint


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
