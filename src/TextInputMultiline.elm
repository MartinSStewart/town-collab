module TextInputMultiline exposing
    ( Model
    , State
    , addLineBreaks
    , init
    , keyMsg
    , mouseDown
    , mouseDownMove
    , paste
    , size
    , view
    , withText
    )

import Color
import Coord exposing (Coord)
import Keyboard
import List.Extra
import Quantity exposing (Quantity(..))
import Sprite exposing (Vertex)
import TextInput exposing (OutMsg(..))


type alias Model =
    { current : State
    , undoHistory : List State
    , redoHistory : List State
    , dummyField : ()
    }


type alias State =
    { cursorPosition : Int
    , cursorSize : Int
    , text : String
    }


init : Model
init =
    { current = { cursorPosition = 0, cursorSize = 0, text = "" }, undoHistory = [], redoHistory = [], dummyField = () }


withText : String -> Model -> Model
withText text model =
    replaceState (\state -> { state | text = text }) model


pushState : (State -> State) -> Model -> Model
pushState changeFunc model =
    { redoHistory = [], undoHistory = model.current :: model.undoHistory, current = changeFunc model.current, dummyField = () }


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
            , dummyField = ()
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
            , dummyField = ()
            }

        [] ->
            model


selectionMin : State -> Int
selectionMin model =
    min model.cursorPosition (model.cursorPosition + model.cursorSize)


selectionMax : State -> Int
selectionMax model =
    max model.cursorPosition (model.cursorPosition + model.cursorSize)


keyMsg : Bool -> Bool -> Keyboard.Key -> Model -> ( Model, OutMsg )
keyMsg ctrlDown shiftDown key model =
    case ( ctrlDown, shiftDown, key ) of
        ( True, False, Keyboard.Character "c" ) ->
            ( model
            , String.dropLeft (selectionMin model.current) model.current.text
                |> String.left (abs model.current.cursorSize)
                |> CopyText
            )

        ( True, False, Keyboard.Character "x" ) ->
            ( pushState deleteSelection model
            , String.dropLeft (selectionMin model.current) model.current.text
                |> String.left (abs model.current.cursorSize)
                |> CopyText
            )

        ( True, False, Keyboard.Character "v" ) ->
            ( model, PasteText )

        ( True, False, Keyboard.Character "z" ) ->
            ( undo model, NoOutMsg )

        ( True, False, Keyboard.Character "y" ) ->
            ( redo model, NoOutMsg )

        ( True, True, Keyboard.Character "Z" ) ->
            ( redo model, NoOutMsg )

        ( True, False, Keyboard.Character "a" ) ->
            ( replaceState
                (\state ->
                    { state
                        | cursorPosition = String.length state.text
                        , cursorSize = String.length state.text |> negate
                    }
                )
                model
            , NoOutMsg
            )

        ( False, _, Keyboard.Character string ) ->
            ( pushState (insertText string) model, NoOutMsg )

        ( False, _, Keyboard.Spacebar ) ->
            ( pushState (insertText " ") model, NoOutMsg )

        ( True, False, Keyboard.ArrowLeft ) ->
            ( replaceState
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
            , NoOutMsg
            )

        ( False, True, Keyboard.ArrowLeft ) ->
            ( replaceState
                (\state ->
                    { state
                        | cursorPosition = state.cursorPosition - 1 |> max 0
                    }
                        |> setCursorSize
                            (if state.cursorPosition > 0 then
                                state.cursorSize + 1

                             else
                                state.cursorSize
                            )
                )
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.ArrowLeft ) ->
            ( replaceState
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
            , NoOutMsg
            )

        ( True, False, Keyboard.ArrowRight ) ->
            ( replaceState
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
            , NoOutMsg
            )

        ( False, True, Keyboard.ArrowRight ) ->
            ( replaceState
                (\state ->
                    { state
                        | cursorPosition = state.cursorPosition + 1 |> min (String.length state.text)
                    }
                        |> setCursorSize
                            (if state.cursorPosition < String.length state.text then
                                state.cursorSize - 1

                             else
                                state.cursorSize
                            )
                )
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.ArrowRight ) ->
            ( replaceState
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
            , NoOutMsg
            )

        ( False, False, Keyboard.ArrowUp ) ->
            ( replaceState
                (\state -> { state | cursorPosition = 0, cursorSize = 0 })
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.ArrowDown ) ->
            ( replaceState
                (\state -> { state | cursorPosition = String.length state.text, cursorSize = 0 })
                model
            , NoOutMsg
            )

        ( True, False, Keyboard.Backspace ) ->
            ( pushState
                (\state ->
                    if state.cursorSize == 0 then
                        { state
                            | text = String.dropLeft state.cursorPosition state.text
                            , cursorPosition = 0
                            , cursorSize = 0
                        }

                    else
                        deleteSelection state
                )
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.Backspace ) ->
            ( pushState
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
                        deleteSelection state
                )
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.Delete ) ->
            ( pushState
                (\state ->
                    if state.cursorSize == 0 then
                        { state
                            | text =
                                String.left state.cursorPosition state.text
                                    ++ String.dropLeft (state.cursorPosition + 1) state.text
                        }

                    else
                        deleteSelection state
                )
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.Enter ) ->
            ( pushState (insertText "\n") model, NoOutMsg )

        _ ->
            ( model, NoOutMsg )


setCursorSize : Int -> State -> State
setCursorSize newCursorSize state =
    { state
        | cursorSize =
            if newCursorSize > 0 then
                min (String.length state.text - state.cursorPosition) newCursorSize

            else
                max -state.cursorPosition newCursorSize
    }


paste : String -> Model -> Model
paste text model =
    if text == "" then
        model

    else
        pushState (insertText text) model


insertText : String -> State -> State
insertText text state =
    { state
        | text =
            String.left (selectionMin state) state.text
                ++ text
                ++ String.dropLeft (selectionMax state) state.text
        , cursorPosition = selectionMin state + String.length text
        , cursorSize = 0
    }


deleteSelection : State -> State
deleteSelection state =
    { state
        | text = String.left (selectionMin state) state.text ++ String.dropLeft (selectionMax state) state.text
        , cursorPosition = selectionMin state
        , cursorSize = 0
    }


mouseDown : Int -> Coord units -> Coord units -> Model -> Model
mouseDown textScale mousePosition position model =
    replaceState
        (\state ->
            { state
                | cursorPosition = cursorPosition textScale mousePosition position state
                , cursorSize = 0
            }
        )
        model


cursorPosition : Int -> Coord units -> Coord units -> State -> Int
cursorPosition textScale mousePosition position state =
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
    toFloat (mouseX - (positionX + paddingX + textScale))
        / toFloat (Coord.xRaw Sprite.charSize * textScale)
        |> round
        |> clamp 0 (String.length state.text)


mouseDownMove : Int -> Coord units -> Coord units -> Model -> Model
mouseDownMove textScale mousePosition position model =
    replaceState
        (\state ->
            let
                cursorPosition2 =
                    cursorPosition textScale mousePosition position state
            in
            { state | cursorPosition = cursorPosition2 }
                |> setCursorSize (state.cursorSize + (state.cursorPosition - cursorPosition2))
        )
        model


padding : Coord units
padding =
    Coord.xy 4 4


size : Int -> Quantity Int units -> State -> Coord units
size textScale width current =
    let
        text : List String
        text =
            addLineBreaks
                (Coord.xRaw Sprite.charSize * textScale)
                (Quantity.unwrap width - (Coord.xRaw padding + textScale) * 2)
                current.text
    in
    size2 textScale width (List.length text)


size2 : Int -> Quantity Int units -> Int -> Coord units
size2 textScale width lineCount =
    ( width, Coord.yRaw Sprite.charSize * textScale * lineCount + Coord.yRaw padding * 2 |> Quantity )


view : Int -> Coord units -> Quantity Int units -> Bool -> Bool -> State -> List Vertex
view textScale offset width hasFocus isValid current =
    let
        rows : List String
        rows =
            addLineBreaks
                (Coord.xRaw Sprite.charSize * textScale)
                (Quantity.unwrap width - (Coord.xRaw padding + textScale) * 2)
                current.text
                |> Debug.log "abc"

        lineCount : Int
        lineCount =
            List.length rows

        cursorPosition2 : { cursorRow : Int, charsLeft : Int }
        cursorPosition2 =
            List.Extra.stoppableFoldl
                (\row state ->
                    if String.length row < state.charsLeft then
                        { cursorRow = state.cursorRow + 1
                        , charsLeft = state.charsLeft - String.length row - 1
                        }
                            |> List.Extra.Continue

                    else
                        List.Extra.Stop state
                )
                { cursorRow = 0, charsLeft = current.cursorPosition }
                rows

        --|> Debug.log "cursor position"
    in
    Sprite.spriteWithColor
        (if not isValid then
            Color.errorColor

         else if hasFocus then
            Color.highlightColor

         else
            Color.outlineColor
        )
        offset
        (size2 textScale width lineCount)
        (Coord.xy 508 28)
        (Coord.xy 1 1)
        ++ Sprite.spriteWithColor
            (if hasFocus then
                Color.highlightColor

             else
                Color.fillColor3
            )
            (offset |> Coord.plus padding)
            (size2 textScale width lineCount |> Coord.minus (Coord.multiplyTuple ( 2, 2 ) padding))
            (Coord.xy
                508
                28
            )
            (Coord.xy 1 1)
        ++ (if current.cursorSize == 0 || not hasFocus then
                []

            else
                []
            --Sprite.spriteWithColor
            --    (Color.rgb255 170 210 255)
            --    (offset
            --        |> Coord.plus
            --            (Coord.xy
            --                (cursorPosition2.charsLeft * Coord.xRaw Sprite.charSize * textScale)
            --                (cursorPosition2.cursorRow * Coord.yRaw Sprite.charSize * textScale)
            --            )
            --        |> Coord.plus padding
            --    )
            --    (Coord.xy
            --        (Coord.xRaw Sprite.charSize * textScale * current.cursorSize)
            --        (Coord.yRaw Sprite.charSize * textScale)
            --    )
            --    (Coord.xy 508 28)
            --    (Coord.xy 1 1)
           )
        ++ Sprite.text Color.black textScale (String.join "\n" rows) (offset |> Coord.plus padding |> Coord.plus (Coord.xy textScale 0))
        ++ (if hasFocus then
                Sprite.sprite
                    (offset
                        |> Coord.plus
                            (Coord.xy
                                (cursorPosition2.charsLeft * Coord.xRaw Sprite.charSize * textScale)
                                (cursorPosition2.cursorRow * Coord.yRaw Sprite.charSize * textScale)
                            )
                        |> Coord.plus padding
                    )
                    (Coord.xy
                        textScale
                        (Coord.yRaw Sprite.charSize * textScale)
                    )
                    (Coord.xy 504 28)
                    (Coord.xy 1 1)

            else
                []
           )


addLineBreaks : Int -> Int -> String -> List String
addLineBreaks charWidth maxWidth text2 =
    List.concatMap
        (\text -> addLineBreaksHelper charWidth maxWidth [] text |> List.reverse)
        (String.split "\n" text2)


addLineBreaksHelper : Int -> Int -> List String -> String -> List String
addLineBreaksHelper charWidth maxWidth list text2 =
    let
        charCount : Int
        charCount =
            String.length text2

        width : Int
        width =
            charWidth * charCount

        index : Int
        index =
            1 + maxWidth // charWidth

        left : String
        left =
            String.left index text2

        ( left2, right ) =
            if String.contains " " left then
                String.foldr
                    (\char ( continue, index3 ) ->
                        if continue then
                            if char == ' ' then
                                ( False, index3 - 1 )

                            else
                                ( True, index3 - 1 )

                        else
                            ( False, index3 )
                    )
                    ( True, index )
                    left
                    |> Tuple.second
                    |> (\index4 -> ( String.left index4 text2, String.dropLeft (index4 + 1) text2 ))

            else
                ( left, String.dropLeft index text2 )
    in
    if width > maxWidth then
        addLineBreaksHelper
            charWidth
            maxWidth
            (left2 :: list)
            right

    else
        text2 :: list
