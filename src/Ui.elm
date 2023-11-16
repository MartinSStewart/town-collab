module Ui exposing
    ( BorderAndFill(..)
    , ButtonData
    , Element(..)
    , HoverType(..)
    , InputType(..)
    , Padding
    , RowColumn
    , TextInputData
    , TextInputMultilineData
    , UiEvent(..)
    , bottomCenter
    , bottomLeft
    , button
    , center
    , centerHorizontally
    , centerRight
    , checkbox
    , colorScaledText
    , colorSprite
    , colorText
    , column
    , customButton
    , defaultButtonBorderAndFill
    , defaultButtonBorderAndFillFocus
    , defaultElBorderAndFill
    , el
    , findInput
    , hover
    , ignoreInputs
    , noPadding
    , none
    , outlinedText
    , paddingXY
    , quads
    , row
    , scaledText
    , selectableButton
    , size
    , sprite
    , tabBackward
    , tabForward
    , table
    , text
    , textInput
    , textInputMultiline
    , textInputScaled
    , topCenter
    , topLeft
    , topLeft2
    , topRight
    , underlinedColorText
    , underlinedText
    , view
    , visuallyEqual
    , wrappedText
    )

import Bounds
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Keyboard
import List.Extra as List
import Pixels exposing (Pixels)
import Quantity exposing (Quantity(..))
import Sprite exposing (Vertex)
import TextInput
import TextInputMultiline
import WebGL


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Coord Pixels
    }


type alias ButtonData id =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Coord Pixels
    , inFront : List (Element id)
    }


type alias TextInputData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : TextInput.State
    , textScale : Int
    }


type alias TextInputMultilineData id =
    { id : id
    , width : Int
    , isValid : Bool
    , state : TextInputMultiline.State
    , textScale : Int
    , dummyField : ()
    }


type UiEvent
    = MouseDown { elementPosition : Coord Pixels }
    | MousePressed
    | MouseMove { elementPosition : Coord Pixels }
    | KeyDown Keyboard.RawKey Keyboard.Key
    | PastedText String


type Element id
    = Text
        { outline : Maybe Color
        , color : Color
        , scale : Int
        , text : String
        , underlined : Bool
        , cachedSize : Coord Pixels
        }
    | TextInput (TextInputData id)
    | TextInputMultiline (TextInputMultilineData id)
    | Button (ButtonData id) (Element id)
    | Row RowColumn (List (Element id))
    | Column RowColumn (List (Element id))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id)
        , cachedSize : Coord Pixels
        }
        (Element id)
    | Quads { size : Coord Pixels, vertices : List Vertex }
    | Empty
    | IgnoreInputs (Element id)


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Color
    | BorderAndFill { borderWidth : Int, borderColor : Color, fillColor : Color }


type alias Padding =
    { topLeft : Coord Pixels, bottomRight : Coord Pixels }


listsVisuallyEqual : List (Element id) -> List (Element id) -> Bool
listsVisuallyEqual a b =
    if List.length a == List.length b then
        List.all identity (List.map2 visuallyEqual a b)

    else
        False


visuallyEqual : Element id -> Element id -> Bool
visuallyEqual a b =
    case ( a, b ) of
        ( Single aData aChild, Single bData bChild ) ->
            (aData.padding == bData.padding)
                && (aData.borderAndFill == bData.borderAndFill)
                && listsVisuallyEqual aData.inFront bData.inFront
                && visuallyEqual aChild bChild

        ( Row aRow aChildren, Row bRow bChildren ) ->
            (aRow.spacing == bRow.spacing)
                && (aRow.padding == bRow.padding)
                && listsVisuallyEqual aChildren bChildren

        ( Column aColumn aChildren, Column bColumn bChildren ) ->
            (aColumn.spacing == bColumn.spacing)
                && (aColumn.padding == bColumn.padding)
                && listsVisuallyEqual aChildren bChildren

        ( Text aText, Text bText ) ->
            (aText.text == bText.text)
                && (aText.outline == bText.outline)
                && (aText.color == bText.color)
                && (aText.scale == bText.scale)
                && (aText.text == bText.text)
                && (aText.underlined == bText.underlined)

        ( TextInput aTextInput, TextInput bTextInput ) ->
            (aTextInput.width - bTextInput.width == 0)
                && (aTextInput.isValid == bTextInput.isValid)
                && (aTextInput.textScale - bTextInput.textScale == 0)
                && (aTextInput.state == bTextInput.state)

        ( Button aButton aChild, Button bButton bChild ) ->
            (aButton.padding == bButton.padding)
                && (aButton.borderAndFill == bButton.borderAndFill)
                && (aButton.borderAndFillFocus == bButton.borderAndFillFocus)
                && listsVisuallyEqual aButton.inFront bButton.inFront
                && visuallyEqual aChild bChild

        ( Quads aQuad, Quads bQuad ) ->
            aQuad == bQuad

        ( Empty, Empty ) ->
            True

        ( IgnoreInputs aChild, IgnoreInputs bChild ) ->
            visuallyEqual aChild bChild

        _ ->
            False


noPadding : Padding
noPadding =
    { topLeft = Coord.origin, bottomRight = Coord.origin }


paddingXY : Int -> Int -> Padding
paddingXY x y =
    { topLeft = Coord.xy x y, bottomRight = Coord.xy x y }


text : String -> Element id
text text2 =
    Text
        { outline = Nothing
        , color = Color.black
        , scale = defaultCharScale
        , text = text2
        , underlined = False
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


underlinedText : String -> Element id
underlinedText text2 =
    Text
        { outline = Nothing
        , color = Color.black
        , scale = defaultCharScale
        , text = text2
        , underlined = True
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


underlinedColorText : Color -> String -> Element id
underlinedColorText color text2 =
    Text
        { outline = Nothing
        , color = color
        , scale = defaultCharScale
        , text = text2
        , underlined = True
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


scaledText : Int -> String -> Element id
scaledText scale text2 =
    Text
        { outline = Nothing
        , color = Color.black
        , scale = scale
        , text = text2
        , underlined = False
        , cachedSize = Sprite.textSize scale text2
        }


colorText : Color -> String -> Element id
colorText color text2 =
    Text
        { outline = Nothing
        , color = color
        , scale = defaultCharScale
        , text = text2
        , underlined = False
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


colorScaledText : Color -> Int -> String -> Element id
colorScaledText color scale text2 =
    Text
        { outline = Nothing
        , color = color
        , scale = scale
        , text = text2
        , underlined = False
        , cachedSize = Sprite.textSize scale text2
        }


outlinedText : { outline : Color, color : Color, text : String } -> Element id
outlinedText data =
    Text
        { outline = Just data.outline
        , color = data.color
        , scale = defaultCharScale
        , text = data.text
        , underlined = False
        , cachedSize = Sprite.textSize defaultCharScale data.text
        }


defaultCharScale : number
defaultCharScale =
    2


wrappedText : Int -> String -> Element id
wrappedText maxWidth text2 =
    wrappedColorText maxWidth Color.black text2


wrappedColorText : Int -> Color -> String -> Element id
wrappedColorText maxWidth color text2 =
    let
        text3 : String
        text3 =
            TextInputMultiline.addLineBreaks defaultCharScale maxWidth text2 |> List.concat |> String.join "\n"
    in
    Text
        { outline = Nothing
        , color = color
        , scale = defaultCharScale
        , text = text3
        , underlined = False
        , cachedSize = Sprite.textSize defaultCharScale text3
        }


textInput : { id : id, width : Int, isValid : Bool, state : TextInput.State } -> Element id
textInput data =
    TextInput { id = data.id, width = data.width, textScale = 2, isValid = data.isValid, state = data.state }


textInputScaled :
    { id : id, width : Int, textScale : Int, isValid : Bool, state : TextInput.State }
    -> Element id
textInputScaled =
    TextInput


textInputMultiline : { id : id, width : Int, isValid : Bool, state : TextInputMultiline.State } -> Element id
textInputMultiline data =
    TextInputMultiline
        { id = data.id
        , width = data.width
        , textScale = 2
        , isValid = data.isValid
        , state = data.state
        , dummyField = ()
        }


none : Element id
none =
    Empty


button : { id : id, padding : Padding } -> Element id -> Element id
button data child =
    Button
        { id = data.id
        , padding = data.padding
        , inFront = []
        , borderAndFill = defaultButtonBorderAndFill
        , borderAndFillFocus = defaultButtonBorderAndFillFocus
        , cachedSize =
            Coord.plus
                (Coord.plus data.padding.topLeft data.padding.bottomRight)
                (size child)
        }
        child


defaultElBorderAndFill : BorderAndFill
defaultElBorderAndFill =
    BorderAndFill
        { borderWidth = 2
        , borderColor = Color.outlineColor
        , fillColor = Color.fillColor
        }


defaultButtonBorderAndFill : BorderAndFill
defaultButtonBorderAndFill =
    BorderAndFill
        { borderWidth = 2
        , borderColor = Color.outlineColor
        , fillColor = Color.fillColor2
        }


defaultButtonBorderAndFillFocus : BorderAndFill
defaultButtonBorderAndFillFocus =
    BorderAndFill
        { borderWidth = 2
        , borderColor = Color.focusedUiColor
        , fillColor = Color.fillColor2
        }


customButton :
    { id : id
    , padding : Padding
    , inFront : List (Element id)
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    }
    -> Element id
    -> Element id
customButton data child =
    Button
        { id = data.id
        , padding = data.padding
        , inFront = data.inFront
        , borderAndFill = data.borderAndFill
        , borderAndFillFocus = data.borderAndFillFocus
        , cachedSize =
            Coord.plus
                (Coord.plus data.padding.topLeft data.padding.bottomRight)
                (size child)
        }
        child


row : { spacing : Int, padding : Padding } -> List (Element id) -> Element id
row data children =
    let
        children2 =
            List.filter (\a -> a /= Empty) children
    in
    Row
        { spacing = data.spacing
        , padding = data.padding
        , cachedSize = rowSize data children2
        }
        (List.filter (\a -> a /= Empty) children2)


column : { spacing : Int, padding : Padding } -> List (Element id) -> Element id
column data children =
    let
        children2 =
            List.filter (\a -> a /= Empty) children
    in
    Column
        { spacing = data.spacing
        , padding = data.padding
        , cachedSize = columnSize data children2
        }
        children2


el :
    { padding : Padding, inFront : List (Element id), borderAndFill : BorderAndFill }
    -> Element id
    -> Element id
el data element2 =
    Single
        { padding = data.padding
        , borderAndFill = data.borderAndFill
        , inFront = data.inFront
        , cachedSize = Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight) (size element2)
        }
        element2


centerHorizontally : { parentWidth : Int } -> Element id -> Element id
centerHorizontally data element2 =
    let
        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)

        left =
            (data.parentWidth - childSizeX) // 2
    in
    Single
        { padding =
            { topLeft = Coord.xy left 0
            , bottomRight = Coord.xy (data.parentWidth - childSizeX - left) 0
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = Coord.xy data.parentWidth childSizeY
        }
        element2


center : { size : Coord Pixels } -> Element id -> Element id
center data element2 =
    let
        size2 : Coord Pixels
        size2 =
            size element2

        topLeft3 : Coord Pixels
        topLeft3 =
            data.size |> Coord.minus size2 |> Coord.divide (Coord.xy 2 2)
    in
    Single
        { padding =
            { topLeft = topLeft3
            , bottomRight = data.size |> Coord.minus size2 |> Coord.minus topLeft3
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


topLeft : { size : Coord Pixels } -> Element id -> Element id
topLeft data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)
    in
    Single
        { padding =
            { topLeft = Coord.xy 0 0
            , bottomRight = Coord.xy (sizeX - childSizeX) (sizeY - childSizeY)
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


topLeft2 :
    { size : Coord Pixels, inFront : List (Element id), borderAndFill : BorderAndFill }
    -> Element id
    -> Element id
topLeft2 data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)
    in
    Single
        { padding =
            { topLeft = Coord.xy 0 0
            , bottomRight = Coord.xy (sizeX - childSizeX) (sizeY - childSizeY)
            }
        , inFront = data.inFront
        , borderAndFill = data.borderAndFill
        , cachedSize = data.size
        }
        element2


topCenter : { size : Coord Pixels } -> Element id -> Element id
topCenter data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)

        left =
            (sizeX - childSizeX) // 2
    in
    Single
        { padding =
            { topLeft = Coord.xy left 0
            , bottomRight = Coord.xy (sizeX - childSizeX - left) (sizeY - childSizeY)
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


topRight : { size : Coord Pixels } -> Element id -> Element id
topRight data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)
    in
    Single
        { padding =
            { topLeft = Coord.xy (sizeX - childSizeX) 0
            , bottomRight = Coord.xy 0 (sizeY - childSizeY)
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


centerRight : { size : Coord Pixels } -> Element id -> Element id
centerRight data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)

        top =
            (sizeY - childSizeY) // 2
    in
    Single
        { padding =
            { topLeft = Coord.xy (sizeX - childSizeX) top
            , bottomRight = Coord.xy 0 (sizeY - childSizeY - top)
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


bottomLeft : { size : Coord Pixels } -> Element id -> Element id
bottomLeft data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)
    in
    Single
        { padding =
            { topLeft = Coord.xy 0 (sizeY - childSizeY)
            , bottomRight = Coord.xy (sizeX - childSizeX) 0
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


bottomCenter : { size : Coord Pixels, inFront : List (Element id) } -> Element id -> Element id
bottomCenter data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)

        left =
            (sizeX - childSizeX) // 2
    in
    Single
        { padding =
            { topLeft = Coord.xy left (sizeY - childSizeY)
            , bottomRight = Coord.xy (sizeX - childSizeX) (sizeX - childSizeX - left)
            }
        , inFront = data.inFront
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        }
        element2


ignoreInputs : Element id -> Element id
ignoreInputs =
    IgnoreInputs


sprite : { size : Coord Pixels, texturePosition : Coord Pixels, textureSize : Coord Pixels } -> Element id
sprite data =
    Quads
        { size = data.size
        , vertices = Sprite.sprite Coord.origin data.size data.texturePosition data.textureSize
        }


colorSprite :
    { colors : Colors, size : Coord Pixels, texturePosition : Coord Pixels, textureSize : Coord Pixels }
    -> Element id
colorSprite data =
    Quads
        { size = data.size
        , vertices = Sprite.spriteWithTwoColors data.colors Coord.origin data.size data.texturePosition data.textureSize
        }


quads : { size : Coord Pixels, vertices : List Vertex } -> Element id
quads =
    Quads


type HoverType id msg
    = NoHover
    | InputHover { id : id, position : Coord Pixels }
    | BackgroundHover


hover : Coord Pixels -> Element id -> HoverType id msg
hover point element2 =
    hoverHelper point Coord.origin element2


hoverHelper : Coord Pixels -> Coord Pixels -> Element id -> HoverType id msg
hoverHelper point elementPosition element2 =
    case element2 of
        Text _ ->
            NoHover

        TextInput data ->
            if Bounds.fromCoordAndSize elementPosition (TextInput.size data.textScale (Quantity data.width)) |> Bounds.contains point then
                InputHover { id = data.id, position = elementPosition }

            else
                NoHover

        TextInputMultiline data ->
            if
                Bounds.fromCoordAndSize
                    elementPosition
                    (TextInputMultiline.size data.textScale (Quantity data.width) data.state)
                    |> Bounds.contains point
            then
                InputHover { id = data.id, position = elementPosition }

            else
                NoHover

        Button data _ ->
            if Bounds.fromCoordAndSize elementPosition data.cachedSize |> Bounds.contains point then
                InputHover { id = data.id, position = elementPosition }

            else
                NoHover

        Row data children ->
            hoverRowColumnHelper True point elementPosition data children

        Column data children ->
            hoverRowColumnHelper False point elementPosition data children

        Single data child ->
            let
                hover2 : HoverType id msg
                hover2 =
                    List.foldl
                        (\inFront hover4 ->
                            case hover4 of
                                NoHover ->
                                    hoverHelper point elementPosition inFront

                                InputHover _ ->
                                    hover4

                                BackgroundHover ->
                                    hover4
                        )
                        NoHover
                        data.inFront

                hover3 : HoverType id msg
                hover3 =
                    case hover2 of
                        NoHover ->
                            hoverHelper point (elementPosition |> Coord.plus data.padding.topLeft) child

                        InputHover _ ->
                            hover2

                        BackgroundHover ->
                            hover2
            in
            case ( data.borderAndFill, hover3 ) of
                ( BorderAndFill _, NoHover ) ->
                    if Bounds.fromCoordAndSize elementPosition data.cachedSize |> Bounds.contains point then
                        BackgroundHover

                    else
                        NoHover

                _ ->
                    hover3

        Quads _ ->
            NoHover

        Empty ->
            NoHover

        IgnoreInputs _ ->
            NoHover


hoverRowColumnHelper :
    Bool
    -> Coord Pixels
    -> Coord Pixels
    -> RowColumn
    -> List (Element id)
    -> HoverType id msg
hoverRowColumnHelper isRow point elementPosition data children =
    List.foldl
        (\child state ->
            case state.hover of
                NoHover ->
                    let
                        ( sizeX, sizeY ) =
                            size child |> Coord.toTuple
                    in
                    { elementPosition =
                        state.elementPosition
                            |> Coord.plus
                                (if isRow then
                                    Coord.xy (sizeX + data.spacing) 0

                                 else
                                    Coord.xy 0 (sizeY + data.spacing)
                                )
                    , hover = hoverHelper point state.elementPosition child
                    }

                _ ->
                    state
        )
        { elementPosition = elementPosition |> Coord.plus data.padding.topLeft, hover = NoHover }
        children
        |> .hover


view : Maybe id -> Element id -> WebGL.Mesh Vertex
view focus element2 =
    viewHelper focus Coord.origin [] element2 |> Sprite.toMesh


verticesHelper : Maybe id -> Coord Pixels -> List Vertex -> { a | inFront : List (Element id) } -> List Vertex
verticesHelper focus position vertices data =
    List.foldl
        (\inFront vertices3 ->
            viewHelper focus position vertices3 inFront
        )
        vertices
        data.inFront


viewHelper : Maybe id -> Coord Pixels -> List Vertex -> Element id -> List Vertex
viewHelper focus position vertices element2 =
    case element2 of
        Text data ->
            (case data.outline of
                Just outline ->
                    Sprite.outlinedText outline data.color data.scale data.text position

                Nothing ->
                    if data.underlined then
                        Sprite.underlinedText data.color data.scale data.text position

                    else
                        Sprite.text data.color data.scale data.text position
            )
                ++ vertices

        TextInput data ->
            TextInput.view
                data.textScale
                position
                (Quantity data.width)
                (focus == Just data.id)
                data.isValid
                data.state
                ++ vertices

        TextInputMultiline data ->
            TextInputMultiline.view
                data.textScale
                position
                (Quantity data.width)
                (focus == Just data.id)
                data.isValid
                data.state
                ++ vertices

        Button data child ->
            borderAndFillView position
                (if Just data.id == focus then
                    data.borderAndFillFocus

                 else
                    data.borderAndFill
                )
                data.cachedSize
                ++ viewHelper
                    focus
                    (Coord.plus data.padding.topLeft position)
                    (verticesHelper focus position vertices data)
                    child

        Row data children ->
            List.foldl
                (\child state ->
                    { vertices = viewHelper focus state.position state.vertices child
                    , position =
                        Coord.xy (Coord.xRaw (size child) + data.spacing) 0
                            |> Coord.plus state.position
                    }
                )
                { position = Coord.plus data.padding.topLeft position
                , vertices = vertices
                }
                children
                |> .vertices

        Column data children ->
            List.foldl
                (\child state ->
                    { vertices = viewHelper focus state.position state.vertices child
                    , position =
                        Coord.xy 0 (Coord.yRaw (size child) + data.spacing)
                            |> Coord.plus state.position
                    }
                )
                { position = Coord.plus data.padding.topLeft position
                , vertices = vertices
                }
                children
                |> .vertices

        Single data child ->
            let
                vertices2 : List Vertex
                vertices2 =
                    List.foldl
                        (\inFront vertices3 ->
                            viewHelper focus position vertices3 inFront
                        )
                        vertices
                        data.inFront
            in
            borderAndFillView position data.borderAndFill (size element2)
                ++ viewHelper focus (Coord.plus data.padding.topLeft position) vertices2 child

        Quads data ->
            List.map
                (\v ->
                    { x = v.x + toFloat (Coord.xRaw position)
                    , y = v.y + toFloat (Coord.yRaw position)
                    , z = v.z
                    , texturePosition = v.texturePosition
                    , opacityAndUserId = v.opacityAndUserId
                    , primaryColor = v.primaryColor
                    , secondaryColor = v.secondaryColor
                    }
                )
                data.vertices
                ++ vertices

        Empty ->
            vertices

        IgnoreInputs element ->
            viewHelper focus position vertices element


borderAndFillView :
    Coord Pixels
    -> BorderAndFill
    -> Coord Pixels
    -> List Vertex
borderAndFillView position borderAndBackground size2 =
    case borderAndBackground of
        NoBorderOrFill ->
            []

        FillOnly color ->
            Sprite.rectangle color position size2

        BorderAndFill { borderWidth, borderColor, fillColor } ->
            Sprite.rectangle borderColor position size2
                ++ Sprite.rectangle
                    fillColor
                    (Coord.plus (Coord.xy borderWidth borderWidth) position)
                    (size2 |> Coord.minus (Coord.scalar 2 (Coord.xy borderWidth borderWidth)))


size : Element id -> Coord Pixels
size element2 =
    case element2 of
        Text data ->
            data.cachedSize

        TextInput data ->
            TextInput.size data.textScale (Quantity data.width)

        TextInputMultiline data ->
            TextInputMultiline.size data.textScale (Quantity data.width) data.state

        Button data _ ->
            data.cachedSize

        Row data _ ->
            data.cachedSize

        Column data _ ->
            data.cachedSize

        Single data _ ->
            data.cachedSize

        Quads data ->
            data.size

        Empty ->
            Coord.origin

        IgnoreInputs element ->
            size element


rowSize : { a | spacing : Int, padding : Padding } -> List (Element id) -> Coord Pixels
rowSize data children =
    List.foldl
        (\child ( x, y ) ->
            let
                size2 =
                    size child
            in
            ( Coord.xRaw size2 + data.spacing + x
            , max (Coord.yRaw size2) y
            )
        )
        ( 0, 0 )
        children
        |> Coord.tuple
        |> Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight)
        |> (if List.isEmpty children then
                identity

            else
                Coord.minus (Coord.xy data.spacing 0)
           )


columnSize : { a | spacing : Int, padding : Padding } -> List (Element id) -> Coord Pixels
columnSize data children =
    List.foldl
        (\child ( x, y ) ->
            let
                size2 =
                    size child
            in
            ( max (Coord.xRaw size2) x
            , Coord.yRaw size2 + data.spacing + y
            )
        )
        ( 0, 0 )
        children
        |> Coord.tuple
        |> Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight)
        |> (if List.isEmpty children then
                identity

            else
                Coord.minus (Coord.xy 0 data.spacing)
           )


type InputType id
    = ButtonType { data : ButtonData id, position : Coord Pixels }
    | TextInputType


findInput : id -> Element id -> Maybe (InputType id)
findInput id element =
    findInputHelper id Coord.origin element


findInputHelper : id -> Coord Pixels -> Element id -> Maybe (InputType id)
findInputHelper id position element =
    case element of
        Text _ ->
            Nothing

        TextInput data ->
            if data.id == id then
                TextInputType |> Just

            else
                Nothing

        TextInputMultiline data ->
            if data.id == id then
                TextInputType |> Just

            else
                Nothing

        Button data _ ->
            if data.id == id then
                ButtonType { data = data, position = position } |> Just

            else
                Nothing

        Row data children ->
            List.foldl
                (\child state ->
                    case state.result of
                        Just _ ->
                            state

                        Nothing ->
                            { result = findInputHelper id state.position child
                            , position =
                                Coord.xy (Coord.xRaw (size child) + data.spacing) 0
                                    |> Coord.plus state.position
                            }
                )
                { position = Coord.plus data.padding.topLeft position
                , result = Nothing
                }
                children
                |> .result

        Column data children ->
            List.foldl
                (\child state ->
                    case state.result of
                        Just _ ->
                            state

                        Nothing ->
                            { result = findInputHelper id state.position child
                            , position =
                                Coord.xy 0 (Coord.yRaw (size child) + data.spacing)
                                    |> Coord.plus state.position
                            }
                )
                { position = Coord.plus data.padding.topLeft position
                , result = Nothing
                }
                children
                |> .result

        Single data child ->
            let
                position2 =
                    Coord.plus data.padding.topLeft position
            in
            case List.findMap (findInputHelper id position2) (child :: data.inFront) of
                Just result ->
                    Just result

                Nothing ->
                    findInputHelper id position2 child

        Quads _ ->
            Nothing

        Empty ->
            Nothing

        IgnoreInputs child ->
            findInputHelper id position child


tabForward : id -> Element id -> id
tabForward id element =
    case tabHelper True False id element of
        NotFound ->
            id

        FoundId ->
            case tabHelper True True id element of
                NotFound ->
                    id

                FoundId ->
                    id

                FoundNextId id2 ->
                    id2

        FoundNextId id2 ->
            id2


tabBackward : id -> Element id -> id
tabBackward id element =
    case tabHelper False False id element of
        NotFound ->
            id

        FoundId ->
            case tabHelper False True id element of
                NotFound ->
                    id

                FoundId ->
                    id

                FoundNextId id2 ->
                    id2

        FoundNextId id2 ->
            id2


tabHelper : Bool -> Bool -> id -> Element id -> TabForward id
tabHelper stepForward hasFoundId id element =
    case element of
        Text _ ->
            if hasFoundId then
                FoundId

            else
                NotFound

        TextInput data ->
            if hasFoundId then
                FoundNextId data.id

            else if id == data.id then
                FoundId

            else
                NotFound

        TextInputMultiline data ->
            if hasFoundId then
                FoundNextId data.id

            else if id == data.id then
                FoundId

            else
                NotFound

        Button data _ ->
            if hasFoundId then
                FoundNextId data.id

            else if id == data.id then
                FoundId

            else
                NotFound

        Row _ children ->
            rowColumnTabHelper stepForward hasFoundId id children

        Column _ children ->
            rowColumnTabHelper stepForward hasFoundId id children

        Single data child ->
            rowColumnTabHelper stepForward hasFoundId id (child :: data.inFront)

        Quads _ ->
            if hasFoundId then
                FoundId

            else
                NotFound

        Empty ->
            if hasFoundId then
                FoundId

            else
                NotFound

        IgnoreInputs _ ->
            NotFound


rowColumnTabHelper : Bool -> Bool -> id -> List (Element id) -> TabForward id
rowColumnTabHelper stepForward hasFoundId id children =
    (if stepForward then
        List.foldl

     else
        List.foldr
    )
        (\child state2 ->
            case state2 of
                FoundNextId _ ->
                    state2

                FoundId ->
                    tabHelper stepForward True id child

                NotFound ->
                    tabHelper stepForward False id child
        )
        (if hasFoundId then
            FoundId

         else
            NotFound
        )
        children


type TabForward id
    = FoundId
    | FoundNextId id
    | NotFound


table : List { header : Element id, row : data -> Element id } -> List data -> Element id
table columns data =
    row
        { spacing = 24, padding = noPadding }
        (List.map
            (\a -> column { spacing = 8, padding = noPadding } (a.header :: List.map a.row data))
            columns
        )


checkbox : id -> Bool -> String -> Element id
checkbox id isChecked text2 =
    customButton
        { id = id
        , padding = paddingXY 2 2
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , borderAndFillFocus = FillOnly Color.fillColor2
        }
        (row
            { spacing = 8, padding = noPadding }
            [ if isChecked then
                colorSprite
                    { colors = { primaryColor = Color.outlineColor, secondaryColor = Color.fillColor }
                    , size = Coord.xy 36 36
                    , texturePosition = Coord.xy 591 72
                    , textureSize = Coord.xy 36 36
                    }

              else
                colorSprite
                    { colors = { primaryColor = Color.outlineColor, secondaryColor = Color.fillColor }
                    , size = Coord.xy 36 36
                    , texturePosition = Coord.xy 627 72
                    , textureSize = Coord.xy 36 36
                    }
            , text text2
            ]
        )


selectableButton : { id : id, padding : Padding } -> Bool -> Element id -> Element id
selectableButton data isSelected child =
    customButton
        { id = data.id
        , padding = data.padding
        , inFront = []
        , borderAndFill =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , fillColor =
                    if isSelected then
                        Color.highlightColor

                    else
                        Color.fillColor2
                }
        , borderAndFillFocus =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.focusedUiColor
                , fillColor =
                    if isSelected then
                        Color.highlightColor

                    else
                        Color.fillColor2
                }
        }
        child
