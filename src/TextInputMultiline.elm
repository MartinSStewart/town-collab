module TextInputMultiline exposing
    ( Model
    , State
    , addLineBreaks
    , coordToIndex
    , indexToCoord
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
    { cursorIndex : Int
    , cursorSize : Int
    , text : String
    }


init : Model
init =
    { current = { cursorIndex = 0, cursorSize = 0, text = "" }, undoHistory = [], redoHistory = [], dummyField = () }


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
    min model.cursorIndex (model.cursorIndex + model.cursorSize)


selectionMax : State -> Int
selectionMax model =
    max model.cursorIndex (model.cursorIndex + model.cursorSize)


keyMsg : Int -> Int -> Bool -> Bool -> Keyboard.Key -> Model -> ( Model, OutMsg )
keyMsg textScale width ctrlDown shiftDown key model =
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
                        | cursorIndex = String.length state.text
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
                        | cursorIndex =
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
                        | cursorIndex = state.cursorIndex - 1 |> max 0
                    }
                        |> setCursorSize
                            (if state.cursorIndex > 0 then
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
                        | cursorIndex =
                            if state.cursorSize == 0 then
                                state.cursorIndex - 1 |> max 0

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
                        | cursorIndex =
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
                        | cursorIndex = state.cursorIndex + 1 |> min (String.length state.text)
                    }
                        |> setCursorSize
                            (if state.cursorIndex < String.length state.text then
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
                        | cursorIndex =
                            (if state.cursorSize == 0 then
                                state.cursorIndex + 1

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
                (\state ->
                    let
                        lines : List (List String)
                        lines =
                            addLineBreaks textScale width state.text
                    in
                    { state
                        | cursorIndex =
                            indexToCoord lines state.cursorIndex
                                |> Coord.plus (Coord.xy 0 -1)
                                |> coordToIndex lines
                    }
                )
                model
            , NoOutMsg
            )

        ( False, False, Keyboard.ArrowDown ) ->
            ( replaceState
                (\state ->
                    let
                        lines : List (List String)
                        lines =
                            addLineBreaks textScale width state.text
                    in
                    { state
                        | cursorIndex =
                            indexToCoord lines state.cursorIndex
                                |> Coord.plus (Coord.xy 0 1)
                                |> coordToIndex lines
                                |> min (String.length state.text)
                    }
                )
                model
            , NoOutMsg
            )

        ( True, False, Keyboard.Backspace ) ->
            ( pushState
                (\state ->
                    if state.cursorSize == 0 then
                        { state
                            | text = String.dropLeft state.cursorIndex state.text
                            , cursorIndex = 0
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
                                String.left (state.cursorIndex - 1) state.text
                                    ++ String.dropLeft state.cursorIndex state.text
                            , cursorIndex = state.cursorIndex - 1 |> max 0
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
                                String.left state.cursorIndex state.text
                                    ++ String.dropLeft (state.cursorIndex + 1) state.text
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
                min (String.length state.text - state.cursorIndex) newCursorSize

            else
                max -state.cursorIndex newCursorSize
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
        , cursorIndex = selectionMin state + String.length text
        , cursorSize = 0
    }


deleteSelection : State -> State
deleteSelection state =
    { state
        | text = String.left (selectionMin state) state.text ++ String.dropLeft (selectionMax state) state.text
        , cursorIndex = selectionMin state
        , cursorSize = 0
    }


mouseDown : Int -> Coord units -> Coord units -> Model -> Model
mouseDown textScale mousePosition position model =
    replaceState
        (\state ->
            { state
                | cursorIndex = cursorPosition textScale mousePosition position state
                , cursorSize = 0
            }
        )
        model


cursorPosition : Int -> Coord units -> Coord units -> State -> Int
cursorPosition textScale mousePosition position state =
    let
        mouseX : Int
        mouseX =
            Coord.x mousePosition

        paddingX : Int
        paddingX =
            Coord.x padding

        positionX : Int
        positionX =
            Coord.x position
    in
    toFloat (mouseX - (positionX + paddingX + textScale))
        / toFloat (Coord.x Sprite.charSize * textScale)
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
            { state | cursorIndex = cursorPosition2 }
                |> setCursorSize (state.cursorSize + (state.cursorIndex - cursorPosition2))
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
                textScale
                (Quantity.unwrap width - (Coord.x padding + textScale) * 2)
                current.text
                |> List.concat
    in
    size2 textScale width (List.length text)


size2 : Int -> Quantity Int units -> Int -> Coord units
size2 textScale width lineCount =
    ( width, Coord.y Sprite.charSize * textScale * lineCount + Coord.y padding * 2 |> Quantity )


view : Int -> Coord units -> Quantity Int units -> Bool -> Bool -> State -> List Vertex
view textScale offset width hasFocus isValid current =
    let
        rows : List (List String)
        rows =
            addLineBreaks
                textScale
                (Quantity.unwrap width - (Coord.x padding + textScale) * 2)
                current.text

        lineCount : Int
        lineCount =
            List.length (List.concat rows)

        cursorPosition2 =
            indexToCoord rows current.cursorIndex

        text : String
        text =
            List.concat rows |> String.join "\n"

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
        ++ Sprite.text Color.black textScale text (offset |> Coord.plus padding |> Coord.plus (Coord.xy textScale 0))
        ++ (if hasFocus then
                Sprite.sprite
                    (offset
                        |> Coord.plus (Coord.multiply Sprite.charSize cursorPosition2 |> Coord.scalar textScale)
                        |> Coord.plus padding
                    )
                    (Coord.xy
                        textScale
                        (Coord.y Sprite.charSize * textScale)
                    )
                    (Coord.xy 504 28)
                    (Coord.xy 1 1)

            else
                []
           )


addLineBreaks : Int -> Int -> String -> List (List String)
addLineBreaks textScale maxWidth text2 =
    List.map
        (\text -> addLineBreaksHelper (Coord.x Sprite.charSize * textScale) maxWidth [] text |> List.reverse)
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


indexToCoord : List (List String) -> Int -> Coord units
indexToCoord rows cursorIndex =
    List.foldl
        (\row state ->
            if state.stopped == True then
                state

            else
                List.foldl
                    (\rowPart state2 ->
                        if state2.stopped == True then
                            state2

                        else if String.length rowPart < state2.charsLeft then
                            { cursorRow = state2.cursorRow + 1
                            , charsLeft = state2.charsLeft - String.length rowPart
                            , stopped = False
                            }

                        else
                            { cursorRow = state2.cursorRow, charsLeft = state2.charsLeft, stopped = True }
                    )
                    { cursorRow = state.cursorRow
                    , charsLeft = state.charsLeft - 1
                    , stopped = state.stopped
                    }
                    row
        )
        { cursorRow = 0, charsLeft = cursorIndex + 1, stopped = False }
        rows
        |> (\{ cursorRow, charsLeft } -> Coord.xy charsLeft cursorRow)


coordToIndex : List (List String) -> Coord units -> Int
coordToIndex rows coord =
    if Coord.y coord < 0 then
        0

    else
        List.foldl
            (\row state ->
                if state.stopped then
                    state

                else
                    List.foldl
                        (\rowPart state2 ->
                            if state2.stopped then
                                state2

                            else if state2.cursorRow > 0 then
                                { cursorRow = state2.cursorRow - 1
                                , charsLeft = state2.charsLeft + String.length rowPart
                                , stopped = False
                                }

                            else
                                { cursorRow = state2.cursorRow
                                , charsLeft = state2.charsLeft + min (Coord.x coord) (String.length rowPart)
                                , stopped = True
                                }
                        )
                        state
                        row
                        |> (\state2 ->
                                if state2.stopped then
                                    state2

                                else
                                    { cursorRow = state2.cursorRow
                                    , charsLeft = state2.charsLeft + 1
                                    , stopped = state2.stopped
                                    }
                           )
            )
            { cursorRow = Coord.y coord, charsLeft = 0, stopped = False }
            rows
            |> .charsLeft
