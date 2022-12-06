module TextInput exposing (Model, bounds, charScale, init, keyMsg, mouseDown, mouseDownMove, padding, pushState, replaceState, size, view, withText)

import Bounds
import Color
import Coord exposing (Coord)
import Keyboard
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite


type alias Model =
    { current : State
    , undoHistory : List State
    , redoHistory : List State
    }


type alias State =
    { cursorPosition : Int
    , cursorSize : Int
    , text : String
    }


init : Model
init =
    { current = { cursorPosition = 0, cursorSize = 0, text = "" }, undoHistory = [], redoHistory = [] }


withText : String -> Model -> Model
withText text model =
    replaceState (\state -> { state | text = text }) model


pushState : (State -> State) -> Model -> Model
pushState changeFunc model =
    { redoHistory = [], undoHistory = model.current :: model.undoHistory, current = changeFunc model.current }


replaceState : (State -> State) -> Model -> Model
replaceState changeFunc model =
    { model | current = changeFunc model.current }


undo : Model -> Model
undo model =
    case model.undoHistory of
        head :: rest ->
            { undoHistory = rest
            , current = head
            , redoHistory = model.current :: model.redoHistory
            }

        [] ->
            model


redo : Model -> Model
redo model =
    case model.redoHistory of
        head :: rest ->
            { redoHistory = rest
            , current = head
            , undoHistory = model.current :: model.undoHistory
            }

        [] ->
            model


bounds : Coord units -> Quantity Int units -> Bounds.Bounds units
bounds position width =
    Bounds.fromCoordAndSize position (size width)


selectionMin : State -> Int
selectionMin model =
    min model.cursorPosition (model.cursorPosition + model.cursorSize)


selectionMax : State -> Int
selectionMax model =
    max model.cursorPosition (model.cursorPosition + model.cursorSize)


keyMsg : Bool -> Bool -> Keyboard.Key -> Model -> Model
keyMsg ctrlDown shiftDown key model =
    case ( ctrlDown, shiftDown, key ) of
        ( True, False, Keyboard.Character "z" ) ->
            undo model

        ( True, False, Keyboard.Character "y" ) ->
            redo model

        ( True, True, Keyboard.Character "Z" ) ->
            redo model

        ( True, False, Keyboard.Character "a" ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition = String.length state.text
                        , cursorSize = String.length state.text |> negate
                    }
                )
                model

        ( False, _, Keyboard.Character string ) ->
            pushState
                (\state ->
                    { state
                        | text =
                            String.left (selectionMin state) state.text
                                ++ string
                                ++ String.dropLeft (selectionMax state) state.text
                        , cursorPosition = state.cursorPosition + String.length string
                        , cursorSize = 0
                    }
                )
                model

        ( True, False, Keyboard.ArrowLeft ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition =
                            if state.cursorSize == 0 then
                                0

                            else
                                selectionMin state
                        , cursorSize = 0
                    }
                )
                model

        ( False, True, Keyboard.ArrowLeft ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition = state.cursorPosition - 1 |> max 0
                        , cursorSize =
                            if state.cursorPosition > 0 then
                                state.cursorSize + 1

                            else
                                state.cursorSize
                    }
                )
                model

        ( False, False, Keyboard.ArrowLeft ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition =
                            if state.cursorSize == 0 then
                                state.cursorPosition - 1 |> max 0

                            else
                                selectionMin state
                        , cursorSize = 0
                    }
                )
                model

        ( True, False, Keyboard.ArrowRight ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition =
                            if state.cursorSize == 0 then
                                String.length state.text

                            else
                                selectionMax state
                        , cursorSize = 0
                    }
                )
                model

        ( False, True, Keyboard.ArrowRight ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition = state.cursorPosition + 1 |> min (String.length state.text)
                        , cursorSize =
                            if state.cursorPosition < String.length state.text then
                                state.cursorSize - 1

                            else
                                state.cursorSize
                    }
                )
                model

        ( False, False, Keyboard.ArrowRight ) ->
            replaceState
                (\state ->
                    { state
                        | cursorPosition =
                            (if state.cursorSize == 0 then
                                state.cursorPosition + 1

                             else
                                selectionMax state
                            )
                                |> min (String.length state.text)
                        , cursorSize = 0
                    }
                )
                model

        ( False, False, Keyboard.ArrowUp ) ->
            replaceState
                (\state -> { state | cursorPosition = 0, cursorSize = 0 })
                model

        ( False, False, Keyboard.ArrowDown ) ->
            replaceState
                (\state -> { state | cursorPosition = String.length state.text, cursorSize = 0 })
                model

        ( True, False, Keyboard.Backspace ) ->
            pushState
                (\state ->
                    if state.cursorSize == 0 then
                        { state
                            | text = String.dropLeft state.cursorPosition state.text
                            , cursorPosition = 0
                            , cursorSize = 0
                        }

                    else
                        { state
                            | text = String.left (selectionMin state) state.text ++ String.dropLeft (selectionMax state) state.text
                            , cursorPosition = selectionMin state
                            , cursorSize = 0
                        }
                )
                model

        ( False, False, Keyboard.Backspace ) ->
            pushState
                (\state ->
                    if state.cursorSize == 0 then
                        { state
                            | text =
                                String.left (state.cursorPosition - 1) state.text
                                    ++ String.dropLeft state.cursorPosition state.text
                            , cursorPosition = state.cursorPosition - 1 |> max 0
                            , cursorSize = 0
                        }

                    else
                        { state
                            | text = String.left (selectionMin state) state.text ++ String.dropLeft (selectionMax state) state.text
                            , cursorPosition = selectionMin state
                            , cursorSize = 0
                        }
                )
                model

        ( False, False, Keyboard.Delete ) ->
            pushState
                (\state ->
                    { state
                        | text =
                            String.left (state.cursorPosition - 1) state.text
                                ++ String.dropLeft state.cursorPosition state.text
                    }
                )
                model

        _ ->
            model


mouseDown : Coord units -> Coord units -> Model -> Model
mouseDown mousePosition position model =
    let
        mouseX : Int
        mouseX =
            Coord.xRaw mousePosition

        paddingX : Int
        paddingX =
            Coord.xRaw padding

        positionX : Int
        positionX =
            Coord.xRaw position
    in
    replaceState
        (\state ->
            { state
                | cursorPosition =
                    toFloat (mouseX - (positionX + paddingX + charScale))
                        / toFloat (Coord.xRaw Sprite.charSize * 2)
                        |> round
                        |> clamp 0 (String.length state.text)
                , cursorSize = 0
            }
        )
        model


mouseDownMove : Coord units -> Coord units -> Model -> Model
mouseDownMove mousePosition position model =
    replaceState
        (\state ->
            let
                mouseX : Int
                mouseX =
                    Coord.xRaw mousePosition

                paddingX : Int
                paddingX =
                    Coord.xRaw padding

                positionX : Int
                positionX =
                    Coord.xRaw position

                cursorPosition =
                    toFloat (mouseX - (positionX + paddingX + charScale))
                        / toFloat (Coord.xRaw Sprite.charSize * 2)
                        |> round
                        |> clamp 0 (String.length state.text)
            in
            { state
                | cursorPosition = cursorPosition
                , cursorSize = state.cursorSize + (state.cursorPosition - cursorPosition)
            }
        )
        model


charScale : number
charScale =
    2


padding : Coord units
padding =
    Coord.xy 2 2


size : Quantity Int units -> Coord units
size width =
    ( width, Coord.yRaw Sprite.charSize * charScale + Coord.yRaw padding * 2 |> Quantity )


view : Coord units -> Quantity Int units -> Bool -> (String -> Bool) -> Model -> List Vertex
view offset width hasFocus isValid model =
    let
        current =
            model.current
    in
    Sprite.spriteWithColor
        (if not (isValid current.text) then
            Color.rgb255 255 0 0

         else if hasFocus then
            Color.rgb255 241 231 223

         else
            Color.rgb255 157 143 134
        )
        offset
        (size width)
        (Coord.xy 508 28)
        (Coord.xy 1 1)
        ++ Sprite.sprite
            (offset |> Coord.plus padding)
            (size width |> Coord.minus (Coord.multiplyTuple ( 2, 2 ) padding))
            (Coord.xy
                (if hasFocus then
                    505

                 else
                    507
                )
                28
            )
            (Coord.xy 1 1)
        ++ (if current.cursorSize == 0 || not hasFocus then
                []

            else
                Sprite.spriteWithColor
                    (Color.rgb255 100 160 255)
                    (offset
                        |> Coord.plus
                            (Coord.xy (current.cursorPosition * Coord.xRaw Sprite.charSize * charScale + Coord.xRaw padding) charScale)
                    )
                    (Coord.xy
                        (Coord.xRaw Sprite.charSize * charScale * current.cursorSize)
                        (Coord.yRaw Sprite.charSize * charScale)
                    )
                    (Coord.xy 508 28)
                    (Coord.xy 1 1)
           )
        ++ Sprite.text Color.black charScale current.text (offset |> Coord.plus padding |> Coord.plus (Coord.xy charScale 0))
        ++ (if hasFocus then
                Sprite.sprite
                    (offset
                        |> Coord.plus
                            (Coord.xy (current.cursorPosition * Coord.xRaw Sprite.charSize * charScale + Coord.xRaw padding) charScale)
                    )
                    (Coord.xy
                        charScale
                        (Coord.yRaw Sprite.charSize * charScale)
                    )
                    (Coord.xy 504 28)
                    (Coord.xy 1 1)

            else
                []
           )
