module Toolbar exposing
    ( ToolbarUnit
    , getTileGroupTile
    , hoverAt
    , loginToolbar
    , mesh
    , position
    , primaryColorInputPosition
    , secondaryColorInputPosition
    , showColorTextInputs
    , toolbarSize
    , toolbarTileButtonPosition
    , toolbarToPixel
    )

import AssocList
import Bounds
import Color exposing (Color, Colors)
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
import Types exposing (Hover(..), LoginMenuHover(..), Tool(..), ToolButton(..))
import Ui exposing (BorderAndBackground(..))
import Units
import WebGL


loginToolbar : TextInput.Model -> WebGL.Mesh Vertex
loginToolbar emailTextInput =
    Ui.view
        MapHover
        (Ui.column
            { spacing = Quantity 10
            , padding = { topLeft = Coord.xy 20 10, bottomRight = Coord.xy 20 10 }
            , borderAndBackground =
                BorderAndBackground
                    { borderWidth = Quantity 2
                    , borderColor = Color.outlineColor
                    , backgroundColor = Color.fillColor
                    }
            }
            [ Ui.text "Enter your email address and we'll send a login link"
            , Ui.row
                { spacing = Quantity 10
                , padding = { topLeft = Coord.origin, bottomRight = Coord.origin }
                , borderAndBackground = NoBorderOrBackground
                }
                [ Ui.textInput
                    { id = LoginMenuHover EmailAddressTextInputHover
                    , width = Quantity 780
                    }
                , Ui.button
                    { id = LoginMenuHover SendEmailButtonHover
                    , size = Coord.xy 260 44
                    , label = "Send email"
                    }
                ]
            , Ui.text "\nIf you don't have an account you'll need to be\ninvited by an existing player."
            ]
        )
        |> Sprite.toMesh



--Sprite.rectangle Color.outlineColor Coord.origin toolbarSize
--    ++ Sprite.rectangle Color.fillColor (Coord.xy 2 2) (toolbarSize |> Coord.minus (Coord.xy 4 4))
--    ++ Sprite.text Color.black 2 "Enter your email address and we'll send a login link." (Coord.xy 20 10)
--    ++ TextInput.view (Coord.xy 20 60) (Quantity 780) False (\_ -> True) emailTextInput
--    ++ button (Coord.xy 820 60) (Coord.xy 260 44) "Send email"
--    ++ Sprite.text
--        Color.black
--        2
--        "If you don't have an account you'll need to be\ninvited by an existing player."
--        (Coord.xy 20 166)
--    |> Sprite.toMesh


mesh :
    Bool
    -> Colors
    -> TextInput.Model
    -> TextInput.Model
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> Hover
    -> Tool
    -> WebGL.Mesh Vertex
mesh hasCmdKey handColor primaryColorTextInput secondaryColorTextInput colors hotkeys focus currentTile =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs currentTile

        currentTool2 : ToolButton
        currentTool2 =
            case currentTile of
                TilePlacerTool { tileGroup } ->
                    TilePlacerToolButton tileGroup

                TilePickerTool ->
                    TilePickerToolButton

                HandTool ->
                    HandToolButton
    in
    Sprite.rectangle Color.outlineColor Coord.origin toolbarSize
        ++ Sprite.rectangle Color.fillColor (Coord.xy 2 2) (toolbarSize |> Coord.minus (Coord.xy 4 4))
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
                    tileButton
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
                    primaryColorInputPosition
                        |> Coord.plus ( secondaryColorInputWidth, Quantity.zero )
                        |> Coord.plus (Coord.xy 4 0)
                        |> Cursor.defaultCursorMesh2 handColor

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
colorTextInputView position2 width hasFocus isValid model =
    TextInput.view position2 width hasFocus isValid model


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
        ((Coord.xRaw buttonSize + 2) * (index // toolbarRowCount) + 6)
        ((Coord.yRaw buttonSize + 2) * modBy toolbarRowCount index + 6)


toolbarRowCount : number
toolbarRowCount =
    3


tileMesh : Colors -> Coord unit -> Tile -> List Vertex
tileMesh colors position2 tile =
    let
        data : TileData b
        data =
            Tile.getData tile

        size : Coord units
        size =
            Coord.multiply Units.tileSize data.size
                |> Coord.minimum buttonSize

        spriteSize =
            if data.size == Coord.xy 1 1 then
                Coord.multiplyTuple ( 2, 2 ) size

            else
                size

        position3 =
            position2 |> Coord.minus (Coord.divide (Coord.xy 2 2) spriteSize) |> Coord.plus (Coord.divide (Coord.xy 2 2) buttonSize)
    in
    if tile == EmptyTile then
        Sprite.sprite
            (Coord.plus (Coord.xy 10 12) position2)
            (Coord.tuple ( 28 * 2, 27 * 2 ))
            (Coord.xy 504 42)
            (Coord.xy 28 27)

    else
        (case data.texturePosition of
            Just texturePosition ->
                Sprite.spriteWithTwoColors
                    colors
                    position3
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
                            position3
                            spriteSize
                            texturePosition2
                            size

                    Nothing ->
                        []
               )


toolbarSize : Coord Pixels
toolbarSize =
    Coord.xy 1100 ((Coord.yRaw buttonSize + 4) * toolbarRowCount + 4)


position : Float -> Coord Pixels -> Coord Pixels
position devicePixelRatio windowSize =
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


buttonSize : Coord units
buttonSize =
    Coord.xy 80 80


tileButton :
    (Coord ToolbarUnit -> List Vertex)
    -> Maybe String
    -> Bool
    -> Coord ToolbarUnit
    -> List Vertex
tileButton mesh2 maybeHotkey highlight offset =
    let
        charSize : Coord unit
        charSize =
            Sprite.charSize |> Coord.multiplyTuple ( 2, 2 )
    in
    Sprite.rectangle
        (if highlight then
            Color.highlightColor

         else
            Color.outlineColor
        )
        offset
        buttonSize
        ++ Sprite.rectangle
            (if highlight then
                Color.highlightColor

             else
                Color.fillColor
            )
            (offset |> Coord.plus (Coord.xy 2 2))
            (buttonSize |> Coord.minus (Coord.xy 4 4))
        ++ mesh2 offset
        ++ (case maybeHotkey of
                Just hotkey ->
                    Sprite.sprite
                        (Coord.plus
                            (Coord.xy 0 (Coord.yRaw buttonSize - Coord.yRaw charSize + 4))
                            offset
                        )
                        (Coord.multiply (Coord.xy (String.length hotkey) 1) charSize
                            |> Coord.plus (Coord.xy 2 -4)
                            |> Coord.minimum (buttonSize |> Coord.minus (Coord.xy 2 2))
                        )
                        (Coord.xy 506 28)
                        (Coord.xy 1 1)
                        ++ Sprite.text
                            Color.white
                            2
                            hotkey
                            (Coord.plus
                                (Coord.xy 2 (Coord.yRaw buttonSize - Coord.yRaw charSize))
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
                                Bounds.bounds topLeft (Coord.plus buttonSize topLeft)
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
    position devicePixelRatio windowSize |> Coord.changeUnit |> Coord.plus coord |> Coord.changeUnit


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
