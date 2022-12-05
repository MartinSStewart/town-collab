module TextInput exposing (Model, bounds, charScale, init, keyMsg, mouseDown, padding, size, view, withText)

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
    { model | text = text }


pushChange : (State -> State) -> Model -> Model
pushChange changeFunc model =
    { redoHistory = [], undoHistory = model.current :: model.undoHistory, current = changeFunc model.current }


replaceChange : (State -> State) -> Model -> Model
replaceChange changeFunc model =
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
        ( True, False, Keyboard.Character "a" ) ->
            { model | cursorPosition = String.length model.text, cursorSize = String.length model.text |> negate }

        ( False, _, Keyboard.Character string ) ->
            { model
                | text =
                    String.left model.cursorPosition model.text
                        ++ string
                        ++ String.dropLeft model.cursorPosition model.text
                , cursorPosition = model.cursorPosition + String.length string
            }

        ( True, False, Keyboard.ArrowLeft ) ->
            { model
                | cursorPosition =
                    if model.cursorSize == 0 then
                        0

                    else
                        selectionMin model
                , cursorSize = 0
            }

        ( False, False, Keyboard.ArrowLeft ) ->
            { model
                | cursorPosition =
                    if model.cursorSize == 0 then
                        model.cursorPosition - 1 |> max 0

                    else
                        selectionMin model
                , cursorSize = 0
            }

        ( True, False, Keyboard.ArrowRight ) ->
            { model
                | cursorPosition =
                    if model.cursorSize == 0 then
                        String.length model.text

                    else
                        selectionMax model
                , cursorSize = 0
            }

        ( False, False, Keyboard.ArrowRight ) ->
            { model
                | cursorPosition =
                    (if model.cursorSize == 0 then
                        model.cursorPosition + 1

                     else
                        selectionMax model
                    )
                        |> min (String.length model.text)
                , cursorSize = 0
            }

        ( False, False, Keyboard.ArrowUp ) ->
            { model | cursorPosition = 0, cursorSize = 0 }

        ( False, False, Keyboard.ArrowDown ) ->
            { model | cursorPosition = String.length model.text, cursorSize = 0 }

        ( True, False, Keyboard.Backspace ) ->
            if model.cursorSize == 0 then
                { model
                    | text = String.dropLeft model.cursorPosition model.text
                    , cursorPosition = 0
                    , cursorSize = 0
                }

            else
                { model
                    | text = String.left (selectionMin model) model.text ++ String.dropLeft (selectionMax model) model.text
                    , cursorPosition = selectionMin model
                    , cursorSize = 0
                }

        ( False, False, Keyboard.Backspace ) ->
            if model.cursorSize == 0 then
                { model
                    | text =
                        String.left (model.cursorPosition - 1) model.text
                            ++ String.dropLeft model.cursorPosition model.text
                    , cursorPosition = model.cursorPosition - 1 |> max 0
                    , cursorSize = 0
                }

            else
                { model
                    | text = String.left (selectionMin model) model.text ++ String.dropLeft (selectionMax model) model.text
                    , cursorPosition = selectionMin model
                    , cursorSize = 0
                }

        ( False, False, Keyboard.Delete ) ->
            { model
                | text =
                    String.left (model.cursorPosition - 1) model.text
                        ++ String.dropLeft model.cursorPosition model.text
            }

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
    replaceChange
        (\state ->
            { state
                | cursorPosition =
                    toFloat (mouseX - (positionX + paddingX + charScale)) / toFloat (Coord.xRaw Sprite.charSize * 2) |> round
                , cursorSize = 0
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
        ++ (if current.cursorSize == 0 then
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
