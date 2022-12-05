module TextInput exposing (Model, bounds, charScale, init, keyMsg, mouseDown, padding, size, view, withText)

import Bounds
import Color
import Coord exposing (Coord)
import Keyboard
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite


type alias Model =
    { cursorPosition : Int
    , text : String
    }


init : Model
init =
    { cursorPosition = 0, text = "" }


withText : String -> Model -> Model
withText text model =
    { model | text = text }


bounds : Coord units -> Quantity Int units -> Bounds.Bounds units
bounds position width =
    Bounds.fromCoordAndSize position (size width)


keyMsg : Keyboard.Key -> Model -> Model
keyMsg key model =
    case key of
        Keyboard.Character string ->
            { model
                | text =
                    String.left model.cursorPosition model.text
                        ++ string
                        ++ String.dropLeft model.cursorPosition model.text
                , cursorPosition = model.cursorPosition + String.length string
            }

        Keyboard.ArrowLeft ->
            { model | cursorPosition = model.cursorPosition - 1 |> max 0 }

        Keyboard.ArrowRight ->
            { model | cursorPosition = model.cursorPosition + 1 |> min (String.length model.text) }

        Keyboard.ArrowUp ->
            { model | cursorPosition = 0 }

        Keyboard.ArrowDown ->
            { model | cursorPosition = String.length model.text }

        Keyboard.Backspace ->
            { model
                | text =
                    String.left (model.cursorPosition - 1) model.text
                        ++ String.dropLeft model.cursorPosition model.text
                , cursorPosition = model.cursorPosition - 1 |> max 0
            }

        Keyboard.Delete ->
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
    { model
        | cursorPosition =
            toFloat (mouseX - (positionX + paddingX + charScale)) / toFloat (Coord.xRaw Sprite.charSize * 2) |> round
    }


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
    Sprite.spriteWithColor
        (if not (isValid model.text) then
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
        ++ Sprite.text Color.black charScale model.text (offset |> Coord.plus padding |> Coord.plus (Coord.xy charScale 0))
        ++ (if hasFocus then
                Sprite.sprite
                    (offset
                        |> Coord.plus
                            (Coord.xy (model.cursorPosition * Coord.xRaw Sprite.charSize * charScale + Coord.xRaw padding) charScale)
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
