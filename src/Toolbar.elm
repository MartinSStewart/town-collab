module Toolbar exposing
    ( ToolbarUnit
    , getTileGroupTile
    , hoverAt
    , primaryColorInputPosition
    , secondaryColorInputPosition
    , showColorTextInputs
    , toolbarMesh
    , toolbarPosition
    , toolbarSize
    , toolbarTileButtonPosition
    , toolbarToPixel
    )

import AssocList
import Bounds
import Color exposing (Colors)
import Coord exposing (Coord)
import Cursor
import Dict exposing (Dict)
import List.Extra as List
import List.Nonempty
import Pixels exposing (Pixels)
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite
import TextInput
import Tile exposing (DefaultColor(..), Tile(..), TileData, TileGroup(..))
import Types exposing (Hover(..), Tool(..), ToolButton(..))
import Units
import WebGL


toolbarMesh :
    Bool
    -> Colors
    -> TextInput.Model
    -> TextInput.Model
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> Hover
    -> Tool
    -> WebGL.Mesh Vertex
toolbarMesh hasCmdKey handColor primaryColorTextInput secondaryColorTextInput colors hotkeys focus currentTile =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs currentTile

        currentTool2 =
            case currentTile of
                TilePlacerTool { tileGroup } ->
                    TilePlacerToolButton tileGroup

                TilePickerTool ->
                    TilePickerToolButton

                HandTool ->
                    HandToolButton
    in
    Sprite.sprite Coord.origin toolbarSize (Coord.xy 506 28) (Coord.xy 1 1)
        ++ Sprite.sprite (Coord.xy 2 2) (toolbarSize |> Coord.minus (Coord.xy 4 4)) (Coord.xy 507 28) (Coord.xy 1 1)
        ++ (List.indexedMap
                (\index tool ->
                    let
                        tileColors =
                            case tool of
                                TilePlacerToolButton tileGroup ->
                                    case AssocList.get tileGroup colors of
                                        Just a ->
                                            a

                                        Nothing ->
                                            Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary

                                HandToolButton ->
                                    handColor

                                TilePickerToolButton ->
                                    Tile.defaultToPrimaryAndSecondary ZeroDefaultColors

                        hotkeyText =
                            case tool of
                                TilePlacerToolButton tileGroup ->
                                    Dict.toList hotkeys |> List.find (Tuple.second >> (==) tileGroup) |> Maybe.map Tuple.first

                                HandToolButton ->
                                    Just "Esc"

                                TilePickerToolButton ->
                                    if hasCmdKey then
                                        Just "Cmd"

                                    else
                                        Just "Ctrl"

                        innerMesh =
                            \offset ->
                                case tool of
                                    TilePlacerToolButton tileGroup ->
                                        tileMesh tileColors offset (getTileGroupTile tileGroup 0)

                                    HandToolButton ->
                                        Cursor.defaultCursorMesh2 handColor offset

                                    TilePickerToolButton ->
                                        Cursor.eyeDropperCursor2 offset
                    in
                    toolbarTileButton
                        innerMesh
                        hotkeyText
                        (tool == currentTool2)
                        (toolbarTileButtonPosition index)
                )
                buttonTiles
                |> List.concat
           )
        ++ (if showPrimaryColorTextInput then
                colorTextInputView
                    primaryColorInputPosition
                    primaryColorInputWidth
                    (focus == PrimaryColorInput)
                    (Color.fromHexCode >> (/=) Nothing)
                    primaryColorTextInput

            else
                []
           )
        ++ (if showSecondaryColorTextInput then
                colorTextInputView
                    secondaryColorInputPosition
                    secondaryColorInputWidth
                    (focus == SecondaryColorInput)
                    (Color.fromHexCode >> (/=) Nothing)
                    secondaryColorTextInput

            else
                []
           )
        ++ (case currentTile of
                HandTool ->
                    []

                TilePickerTool ->
                    []

                TilePlacerTool { tileGroup } ->
                    let
                        primaryAndSecondaryColors : Colors
                        primaryAndSecondaryColors =
                            case AssocList.get tileGroup colors of
                                Just a ->
                                    a

                                Nothing ->
                                    Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary

                        tile =
                            getTileGroupTile tileGroup 0

                        data : TileData unit
                        data =
                            Tile.getData tile

                        size : Coord unit
                        size =
                            Coord.multiply Units.tileSize data.size

                        spriteSize : Coord unit
                        spriteSize =
                            size |> Coord.multiply (Coord.xy 2 2)

                        position2 : Coord ToolbarUnit
                        position2 =
                            primaryColorInputPosition
                                |> Coord.plus ( secondaryColorInputWidth, Quantity.zero )
                                |> Coord.plus (Coord.xy 4 0)
                    in
                    (case data.texturePosition of
                        Just texturePosition ->
                            Sprite.spriteWithTwoColors
                                primaryAndSecondaryColors
                                position2
                                spriteSize
                                (Coord.multiply Units.tileSize texturePosition)
                                size

                        Nothing ->
                            []
                    )
                        ++ (case data.texturePositionTopLayer of
                                Just topLayer ->
                                    let
                                        texturePosition2 =
                                            Coord.multiply Units.tileSize topLayer.texturePosition
                                    in
                                    Sprite.spriteWithTwoColors
                                        primaryAndSecondaryColors
                                        position2
                                        spriteSize
                                        texturePosition2
                                        size

                                Nothing ->
                                    []
                           )
           )
        |> Sprite.toMesh


colorTextInputView : Coord units -> Quantity Int units -> Bool -> (String -> Bool) -> TextInput.Model -> List Vertex
colorTextInputView position width hasFocus isValid model =
    TextInput.view position width hasFocus isValid model


buttonTiles : List ToolButton
buttonTiles =
    [ HandToolButton
    , TilePickerToolButton
    , TilePlacerToolButton EmptyTileGroup
    , TilePlacerToolButton PostOfficeGroup
    , TilePlacerToolButton HouseGroup
    , TilePlacerToolButton LogCabinGroup
    , TilePlacerToolButton TrainHouseGroup
    , TilePlacerToolButton RailTurnGroup
    , TilePlacerToolButton RailTurnSplitGroup
    , TilePlacerToolButton RailTurnSplitMirrorGroup
    , TilePlacerToolButton RailStrafeSmallGroup
    , TilePlacerToolButton RailStrafeGroup
    , TilePlacerToolButton RailTurnLargeGroup
    , TilePlacerToolButton RailStraightGroup
    , TilePlacerToolButton RailCrossingGroup
    , TilePlacerToolButton SidewalkRailGroup
    , TilePlacerToolButton SidewalkGroup
    , TilePlacerToolButton PineTreeGroup
    , TilePlacerToolButton RoadStraightGroup
    , TilePlacerToolButton RoadTurnGroup
    , TilePlacerToolButton Road4WayGroup
    , TilePlacerToolButton RoadSidewalkCrossingGroup
    , TilePlacerToolButton Road3WayGroup
    , TilePlacerToolButton RoadRailCrossingGroup
    , TilePlacerToolButton RoadDeadendGroup
    , TilePlacerToolButton FenceStraightGroup
    ]


type ToolbarUnit
    = ToolbarUnit Never


toolbarTileButtonPosition : Int -> Coord ToolbarUnit
toolbarTileButtonPosition index =
    Coord.xy
        ((Coord.xRaw toolbarButtonSize + 2) * (index // toolbarRowCount) + 6)
        ((Coord.yRaw toolbarButtonSize + 2) * modBy toolbarRowCount index + 6)


toolbarRowCount : number
toolbarRowCount =
    3


tileMesh : Colors -> Coord unit -> Tile -> List Vertex
tileMesh colors position tile =
    let
        data : TileData b
        data =
            Tile.getData tile

        size : Coord units
        size =
            Coord.multiply Units.tileSize data.size
                |> Coord.minimum toolbarButtonSize

        spriteSize =
            if data.size == Coord.xy 1 1 then
                Coord.multiplyTuple ( 2, 2 ) size

            else
                size

        position2 =
            position |> Coord.minus (Coord.divide (Coord.xy 2 2) spriteSize) |> Coord.plus (Coord.divide (Coord.xy 2 2) toolbarButtonSize)
    in
    if tile == EmptyTile then
        Sprite.sprite
            (Coord.plus (Coord.xy 10 12) position)
            (Coord.tuple ( 28 * 2, 27 * 2 ))
            (Coord.xy 504 42)
            (Coord.xy 28 27)

    else
        (case data.texturePosition of
            Just texturePosition ->
                Sprite.spriteWithTwoColors
                    colors
                    position2
                    spriteSize
                    (Coord.multiply Units.tileSize texturePosition)
                    size

            Nothing ->
                []
        )
            ++ (case data.texturePositionTopLayer of
                    Just topLayer ->
                        let
                            texturePosition2 =
                                Coord.multiply Units.tileSize topLayer.texturePosition
                        in
                        Sprite.spriteWithTwoColors
                            colors
                            position2
                            spriteSize
                            texturePosition2
                            size

                    Nothing ->
                        []
               )


toolbarSize : Coord Pixels
toolbarSize =
    Coord.xy 1100 ((Coord.yRaw toolbarButtonSize + 4) * toolbarRowCount + 4)


toolbarPosition : Float -> Coord Pixels -> Coord Pixels
toolbarPosition devicePixelRatio windowSize =
    windowSize
        |> Coord.multiplyTuple_ ( devicePixelRatio, devicePixelRatio )
        |> Coord.divide (Coord.xy 2 1)
        |> Coord.minus (Coord.divide (Coord.xy 2 1) toolbarSize)


primaryColorInputPosition : Coord ToolbarUnit
primaryColorInputPosition =
    Coord.xy 800 8


secondaryColorInputPosition : Coord ToolbarUnit
secondaryColorInputPosition =
    primaryColorInputPosition
        |> Coord.plus (Coord.xy 0 (Coord.yRaw (TextInput.size primaryColorInputWidth) + 6))


primaryColorInputWidth : Quantity Int units
primaryColorInputWidth =
    6 * Coord.xRaw Sprite.charSize * TextInput.charScale + Coord.xRaw TextInput.padding * 2 + 2 |> Quantity


secondaryColorInputWidth : Quantity Int units
secondaryColorInputWidth =
    primaryColorInputWidth


toolbarButtonSize : Coord units
toolbarButtonSize =
    Coord.xy 80 80


toolbarTileButton :
    (Coord ToolbarUnit -> List Vertex)
    -> Maybe String
    -> Bool
    -> Coord ToolbarUnit
    -> List Vertex
toolbarTileButton mesh maybeHotkey highlight offset =
    let
        charSize : Coord unit
        charSize =
            Sprite.charSize |> Coord.multiplyTuple ( 2, 2 )
    in
    Sprite.sprite
        offset
        toolbarButtonSize
        (Coord.xy
            (if highlight then
                505

             else
                506
            )
            28
        )
        (Coord.xy 1 1)
        ++ Sprite.sprite
            (offset |> Coord.plus (Coord.xy 2 2))
            (toolbarButtonSize |> Coord.minus (Coord.xy 4 4))
            (Coord.xy
                (if highlight then
                    505

                 else
                    507
                )
                28
            )
            (Coord.xy 1 1)
        ++ mesh offset
        ++ (case maybeHotkey of
                Just hotkey ->
                    Sprite.sprite
                        (Coord.plus
                            (Coord.xy 0 (Coord.yRaw toolbarButtonSize - Coord.yRaw charSize + 4))
                            offset
                        )
                        (Coord.multiply (Coord.xy (String.length hotkey) 1) charSize
                            |> Coord.plus (Coord.xy 2 -4)
                            |> Coord.minimum (toolbarButtonSize |> Coord.minus (Coord.xy 2 2))
                        )
                        (Coord.xy 506 28)
                        (Coord.xy 1 1)
                        ++ Sprite.text
                            Color.white
                            2
                            hotkey
                            (Coord.plus
                                (Coord.xy 2 (Coord.yRaw toolbarButtonSize - Coord.yRaw charSize))
                                offset
                            )

                Nothing ->
                    []
           )


hoverAt : Float -> Coord Pixels -> Coord Pixels -> Tool -> Maybe Hover
hoverAt devicePixelRatio windowSize mousePosition2 currentTile =
    let
        toolbarTopLeft : Coord Pixels
        toolbarTopLeft =
            toolbarToPixel devicePixelRatio windowSize Coord.origin
    in
    if Bounds.bounds toolbarTopLeft (Coord.plus toolbarSize toolbarTopLeft) |> Bounds.contains mousePosition2 then
        let
            { showPrimaryColorTextInput, showSecondaryColorTextInput } =
                showColorTextInputs currentTile
        in
        if
            showPrimaryColorTextInput
                && (TextInput.bounds
                        (toolbarToPixel
                            devicePixelRatio
                            windowSize
                            primaryColorInputPosition
                        )
                        primaryColorInputWidth
                        |> Bounds.contains mousePosition2
                   )
        then
            Just PrimaryColorInput

        else if
            showSecondaryColorTextInput
                && (TextInput.bounds
                        (toolbarToPixel
                            devicePixelRatio
                            windowSize
                            secondaryColorInputPosition
                        )
                        secondaryColorInputWidth
                        |> Bounds.contains mousePosition2
                   )
        then
            Just SecondaryColorInput

        else
            let
                containsTileButton : Maybe ToolButton
                containsTileButton =
                    List.indexedMap
                        (\index tool ->
                            let
                                topLeft =
                                    toolbarToPixel
                                        devicePixelRatio
                                        windowSize
                                        (toolbarTileButtonPosition index)
                            in
                            if
                                Bounds.bounds topLeft (Coord.plus toolbarButtonSize topLeft)
                                    |> Bounds.contains mousePosition2
                            then
                                Just tool

                            else
                                Nothing
                        )
                        buttonTiles
                        |> List.filterMap identity
                        |> List.head
            in
            case containsTileButton of
                Just tile ->
                    ToolButtonHover tile |> Just

                Nothing ->
                    Just ToolbarHover

    else
        Nothing


toolbarToPixel : Float -> Coord Pixels -> Coord ToolbarUnit -> Coord Pixels
toolbarToPixel devicePixelRatio windowSize coord =
    toolbarPosition devicePixelRatio windowSize |> Coord.changeUnit |> Coord.plus coord |> Coord.changeUnit


showColorTextInputs : Tool -> { showPrimaryColorTextInput : Bool, showSecondaryColorTextInput : Bool }
showColorTextInputs tool =
    case tool of
        TilePlacerTool { tileGroup } ->
            case Tile.getTileGroupData tileGroup |> .defaultColors of
                ZeroDefaultColors ->
                    { showPrimaryColorTextInput = False, showSecondaryColorTextInput = False }

                OneDefaultColor _ ->
                    { showPrimaryColorTextInput = True, showSecondaryColorTextInput = False }

                TwoDefaultColors _ _ ->
                    { showPrimaryColorTextInput = True, showSecondaryColorTextInput = True }

        HandTool ->
            { showPrimaryColorTextInput = True, showSecondaryColorTextInput = True }

        TilePickerTool ->
            { showPrimaryColorTextInput = False, showSecondaryColorTextInput = False }


getTileGroupTile : TileGroup -> Int -> Tile
getTileGroupTile tileGroup index =
    Tile.getTileGroupData tileGroup |> .tiles |> List.Nonempty.get index
