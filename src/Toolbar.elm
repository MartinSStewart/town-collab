module Toolbar exposing
    ( ViewData
    , getTileGroupTile
    , showColorTextInputs
    , view
    )

import AssocList
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor
import Dict exposing (Dict)
import EmailAddress exposing (EmailAddress)
import List.Extra as List
import List.Nonempty
import Quantity exposing (Quantity(..))
import Sprite
import TextInput
import Tile exposing (DefaultColor(..), Tile(..), TileData, TileGroup(..))
import Types exposing (Hover(..), SubmitStatus(..), Tool(..), ToolButton(..), UiHover(..))
import Ui exposing (BorderAndBackground(..))
import Units


type alias ViewData units =
    { devicePixelRatio : Float
    , windowSize : Coord units
    , pressedSubmitEmail : SubmitStatus EmailAddress
    , loginTextInput : TextInput.Model
    , hasCmdKey : Bool
    , handColor : Maybe Colors
    , primaryColorTextInput : TextInput.Model
    , secondaryColorTextInput : TextInput.Model
    , tileColors : AssocList.Dict TileGroup Colors
    , tileHotkeys : Dict String TileGroup
    , currentTool : Tool
    }


view : ViewData units -> Ui.Element UiHover units
view data =
    let
        ( windowWidth, windowHeight ) =
            Coord.multiplyTuple_ ( data.devicePixelRatio, data.devicePixelRatio ) data.windowSize |> Coord.toTuple

        currentToolbar : Ui.Element UiHover units
        currentToolbar =
            toolbarUi
                data.hasCmdKey
                { primaryColor = Color.black, secondaryColor = Color.white }
                data.primaryColorTextInput
                data.secondaryColorTextInput
                data.tileColors
                data.tileHotkeys
                data.currentTool

        --case data.handColor of
        --    Just handColor ->
        --        toolbarUi
        --            data.hasCmdKey
        --            handColor
        --            data.primaryColorTextInput
        --            data.secondaryColorTextInput
        --            data.tileColors
        --            data.tileHotkeys
        --            data.currentTool
        --
        --    Nothing ->
        --        loginToolbarUi data.pressedSubmitEmail data.loginTextInput
        ( toolbarWidth, toolbarHeight ) =
            Ui.size currentToolbar |> Coord.toTuple
    in
    Ui.el
        { padding =
            { topLeft = Coord.xy ((windowWidth - toolbarWidth) // 2) (windowHeight - toolbarHeight)
            , bottomRight = Coord.xy ((windowWidth - toolbarWidth) // 2) 0
            }
        , borderAndBackground = NoBorderOrBackground
        }
        (Ui.el { padding = Ui.noPadding, borderAndBackground = borderAndBackground } currentToolbar)


borderAndBackground : BorderAndBackground units
borderAndBackground =
    BorderAndBackground
        { borderWidth = Quantity 2
        , borderColor = Color.outlineColor
        , backgroundColor = Color.fillColor
        }


loginToolbarUi : SubmitStatus EmailAddress -> TextInput.Model -> Ui.Element UiHover units
loginToolbarUi pressedSubmitEmail emailTextInput =
    let
        pressedSubmit2 : Bool
        pressedSubmit2 =
            case pressedSubmitEmail of
                NotSubmitted { pressedSubmit } ->
                    pressedSubmit

                _ ->
                    False

        loginUi : Ui.Element UiHover units
        loginUi =
            Ui.column
                { spacing = 10, padding = Ui.paddingXY 20 10 }
                [ Ui.text "Enter your email address and we'll send a login link"
                , Ui.column
                    { spacing = 6, padding = Ui.noPadding }
                    [ Ui.row
                        { spacing = 10, padding = Ui.noPadding }
                        [ Ui.textInput
                            { id = EmailAddressTextInputHover
                            , width = Quantity 780
                            , isValid =
                                if pressedSubmit2 then
                                    EmailAddress.fromString emailTextInput.current.text /= Nothing

                                else
                                    True
                            }
                            emailTextInput
                        , Ui.button
                            { id = SendEmailButtonHover, padding = Ui.paddingXY 30 4, inFront = [] }
                            (Ui.text "Send email")
                        ]
                    , case pressedSubmitEmail of
                        NotSubmitted { pressedSubmit } ->
                            if pressedSubmit then
                                case EmailAddress.fromString emailTextInput.current.text of
                                    Just _ ->
                                        Ui.text ""

                                    Nothing ->
                                        Ui.colorText (Color.rgb255 245 0 0) "Invalid email address"

                            else
                                Ui.text ""

                        Submitting ->
                            Ui.text "Sending..."

                        Submitted _ ->
                            Ui.text ""
                    ]
                , Ui.text "If you don't have an account you'll need to be\ninvited by an existing player."
                ]
    in
    case pressedSubmitEmail of
        Submitted emailAddress ->
            let
                submittedText =
                    "Login email sent to " ++ EmailAddress.toString emailAddress |> Ui.text
            in
            Ui.el
                { padding =
                    Ui.size loginUi
                        |> Coord.minus (Ui.size submittedText)
                        |> Coord.divide (Coord.xy 2 2)
                        |> Ui.paddingXY2
                , borderAndBackground = borderAndBackground
                }
                submittedText

        _ ->
            loginUi


toolbarUi :
    Bool
    -> Colors
    -> TextInput.Model
    -> TextInput.Model
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> Tool
    -> Ui.Element UiHover units
toolbarUi hasCmdKey handColor primaryColorTextInput secondaryColorTextInput colors hotkeys currentTile =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs currentTile
    in
    Ui.row
        { spacing = 0, padding = Ui.noPadding }
        [ List.map (toolButtonUi hasCmdKey handColor colors hotkeys) buttonTiles
            |> List.greedyGroupsOf 3
            |> List.map
                (Ui.column { spacing = 2, padding = Ui.noPadding })
            |> Ui.row { spacing = 2, padding = Ui.noPadding }
        , Ui.row
            { spacing = 10, padding = Ui.paddingXY 12 8 }
            [ Ui.column
                { spacing = 10, padding = Ui.noPadding }
                [ if showPrimaryColorTextInput then
                    Ui.textInput
                        { id = PrimaryColorInput, width = primaryColorInputWidth, isValid = True }
                        primaryColorTextInput

                  else
                    Ui.empty
                , if showSecondaryColorTextInput then
                    Ui.textInput
                        { id = SecondaryColorInput, width = secondaryColorInputWidth, isValid = True }
                        secondaryColorTextInput

                  else
                    Ui.empty
                , Ui.el
                    { padding =
                        { topLeft = Coord.xy (Quantity.unwrap primaryColorInputWidth) 0
                        , bottomRight = Coord.xy 0 0
                        }
                    , borderAndBackground = NoBorderOrBackground
                    }
                    Ui.empty
                ]
            , Ui.center
                { size = buttonSize }
                (case currentTile of
                    TilePlacerTool { tileGroup } ->
                        case AssocList.get tileGroup colors of
                            Just color ->
                                (Tile.getTileGroupData tileGroup).tiles
                                    |> List.Nonempty.head
                                    |> tileMesh color

                            Nothing ->
                                Ui.empty

                    TilePickerTool ->
                        Cursor.eyeDropperCursor2

                    HandTool ->
                        Cursor.defaultCursorMesh2 handColor
                )
            ]
        ]


toolButtonUi :
    Bool
    -> Colors
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> ToolButton
    -> Ui.Element UiHover units
toolButtonUi hasCmdKey handColor colors hotkeys tool =
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

        hotkeyText : Maybe String
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

        label : Ui.Element UiHover units
        label =
            case tool of
                TilePlacerToolButton tileGroup ->
                    tileMesh tileColors (getTileGroupTile tileGroup 0)

                HandToolButton ->
                    Cursor.defaultCursorMesh2 handColor

                TilePickerToolButton ->
                    Cursor.eyeDropperCursor2
    in
    Ui.button
        { id = ToolButtonHover tool
        , padding = Ui.noPadding
        , inFront =
            case hotkeyText of
                Just hotkey ->
                    [ Ui.outlinedText { outline = Color.black, color = Color.white, text = hotkey }
                        |> Ui.el
                            { padding = { topLeft = Coord.xy 4 0, bottomRight = Coord.xy 0 0 }
                            , borderAndBackground = NoBorderOrBackground
                            }
                        |> Ui.bottomLeft { size = buttonSize }
                    ]

                Nothing ->
                    []
        }
        (Ui.center { size = buttonSize } label)



--
--mesh :
--    Bool
--    -> Colors
--    -> TextInput.Model
--    -> TextInput.Model
--    -> AssocList.Dict TileGroup Colors
--    -> Dict String TileGroup
--    -> Hover
--    -> Tool
--    -> WebGL.Mesh Vertex
--mesh hasCmdKey handColor primaryColorTextInput secondaryColorTextInput colors hotkeys focus currentTile =
--    let
--        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
--            showColorTextInputs currentTile
--
--        currentTool2 : ToolButton
--        currentTool2 =
--            case currentTile of
--                TilePlacerTool { tileGroup } ->
--                    TilePlacerToolButton tileGroup
--
--                TilePickerTool ->
--                    TilePickerToolButton
--
--                HandTool ->
--                    HandToolButton
--    in
--    Sprite.rectangle Color.outlineColor Coord.origin toolbarSize
--        ++ Sprite.rectangle Color.fillColor (Coord.xy 2 2) (toolbarSize |> Coord.minus (Coord.xy 4 4))
--        ++ (List.indexedMap
--                (\index tool ->
--                    let
--                        tileColors =
--                            case tool of
--                                TilePlacerToolButton tileGroup ->
--                                    case AssocList.get tileGroup colors of
--                                        Just a ->
--                                            a
--
--                                        Nothing ->
--                                            Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary
--
--                                HandToolButton ->
--                                    handColor
--
--                                TilePickerToolButton ->
--                                    Tile.defaultToPrimaryAndSecondary ZeroDefaultColors
--
--                        hotkeyText =
--                            case tool of
--                                TilePlacerToolButton tileGroup ->
--                                    Dict.toList hotkeys |> List.find (Tuple.second >> (==) tileGroup) |> Maybe.map Tuple.first
--
--                                HandToolButton ->
--                                    Just "Esc"
--
--                                TilePickerToolButton ->
--                                    if hasCmdKey then
--                                        Just "Cmd"
--
--                                    else
--                                        Just "Ctrl"
--
--                        innerMesh =
--                            \offset ->
--                                case tool of
--                                    TilePlacerToolButton tileGroup ->
--                                        tileMesh tileColors offset (getTileGroupTile tileGroup 0)
--
--                                    HandToolButton ->
--                                        Cursor.defaultCursorMesh2 handColor offset
--
--                                    TilePickerToolButton ->
--                                        Cursor.eyeDropperCursor2 offset
--                    in
--                    tileButton
--                        innerMesh
--                        hotkeyText
--                        (tool == currentTool2)
--                        (toolbarTileButtonPosition index)
--                )
--                buttonTiles
--                |> List.concat
--           )
--        ++ (if showPrimaryColorTextInput then
--                colorTextInputView
--                    primaryColorInputPosition
--                    primaryColorInputWidth
--                    (focus == PrimaryColorInput)
--                    (Color.fromHexCode primaryColorTextInput.current.text |> (/=) Nothing)
--                    primaryColorTextInput
--
--            else
--                []
--           )
--        ++ (if showSecondaryColorTextInput then
--                colorTextInputView
--                    secondaryColorInputPosition
--                    secondaryColorInputWidth
--                    (focus == SecondaryColorInput)
--                    (Color.fromHexCode secondaryColorTextInput.current.text |> (/=) Nothing)
--                    secondaryColorTextInput
--
--            else
--                []
--           )
--        ++ (case currentTile of
--                HandTool ->
--                    primaryColorInputPosition
--                        |> Coord.plus ( secondaryColorInputWidth, Quantity.zero )
--                        |> Coord.plus (Coord.xy 4 0)
--                        |> Cursor.defaultCursorMesh2 handColor
--
--                TilePickerTool ->
--                    []
--
--                TilePlacerTool { tileGroup } ->
--                    let
--                        primaryAndSecondaryColors : Colors
--                        primaryAndSecondaryColors =
--                            case AssocList.get tileGroup colors of
--                                Just a ->
--                                    a
--
--                                Nothing ->
--                                    Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary
--
--                        tile =
--                            getTileGroupTile tileGroup 0
--
--                        data : TileData unit
--                        data =
--                            Tile.getData tile
--
--                        size : Coord unit
--                        size =
--                            Coord.multiply Units.tileSize data.size
--
--                        spriteSize : Coord unit
--                        spriteSize =
--                            size |> Coord.multiply (Coord.xy 2 2)
--
--                        position2 : Coord ToolbarUnit
--                        position2 =
--                            primaryColorInputPosition
--                                |> Coord.plus ( secondaryColorInputWidth, Quantity.zero )
--                                |> Coord.plus (Coord.xy 4 0)
--                    in
--                    (case data.texturePosition of
--                        Just texturePosition ->
--                            Sprite.spriteWithTwoColors
--                                primaryAndSecondaryColors
--                                position2
--                                spriteSize
--                                (Coord.multiply Units.tileSize texturePosition)
--                                size
--
--                        Nothing ->
--                            []
--                    )
--                        ++ (case data.texturePositionTopLayer of
--                                Just topLayer ->
--                                    let
--                                        texturePosition2 =
--                                            Coord.multiply Units.tileSize topLayer.texturePosition
--                                    in
--                                    Sprite.spriteWithTwoColors
--                                        primaryAndSecondaryColors
--                                        position2
--                                        spriteSize
--                                        texturePosition2
--                                        size
--
--                                Nothing ->
--                                    []
--                           )
--           )
--        |> Sprite.toMesh
--
--
--colorTextInputView : Coord units -> Quantity Int units -> Bool -> Bool -> TextInput.Model -> List Vertex
--colorTextInputView position2 width hasFocus isValid model =
--    TextInput.view position2 width hasFocus isValid model
--


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


toolbarRowCount : number
toolbarRowCount =
    3


tileMesh : Colors -> Tile -> Ui.Element id units
tileMesh colors tile =
    let
        data : TileData b
        data =
            Tile.getData tile

        size =
            Coord.multiply Units.tileSize data.size
                |> Coord.minimum buttonSize

        spriteSize =
            if data.size == Coord.xy 1 1 then
                Coord.multiplyTuple ( 2, 2 ) size

            else
                size
    in
    Ui.quads
        { size =
            if tile == EmptyTile then
                Coord.tuple ( 28 * 2, 27 * 2 )

            else
                spriteSize
        , vertices =
            \position3 ->
                if tile == EmptyTile then
                    Sprite.sprite
                        position3
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
        }


primaryColorInputWidth : Quantity Int units
primaryColorInputWidth =
    6 * Coord.xRaw Sprite.charSize * TextInput.charScale + Coord.xRaw TextInput.padding * 2 + 2 |> Quantity


secondaryColorInputWidth : Quantity Int units
secondaryColorInputWidth =
    primaryColorInputWidth


buttonSize : Coord units
buttonSize =
    Coord.xy 80 80


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
