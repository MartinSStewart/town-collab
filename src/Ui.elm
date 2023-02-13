module Ui exposing
    ( BorderAndFill(..)
    , Element
    , HoverType(..)
    , Padding
    , bottomCenter
    , bottomLeft
    , button
    , center
    , colorScaledText
    , colorSprite
    , colorText
    , column
    , customButton
    , defaultButtonBorderAndFill
    , el
    , findButton
    , findTextInput
    , handleKeyDown
    , hover
    , ignoreInputs
    , noPadding
    , none
    , outlinedText
    , paddingXY
    , paddingXY2
    , quads
    , row
    , scaledText
    , size
    , sprite
    , tabBackward
    , tabForward
    , text
    , textInput
    , topRight
    , view
    , wrappedText
    )

import Bounds
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Keyboard
import List.Extra as List
import Pixels exposing (Pixels)
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite
import TextInput
import WebGL


type alias RowColumn =
    { spacing : Int
    , padding : Padding
    , cachedSize : Coord Pixels
    }


type alias ButtonData id msg =
    { id : id
    , padding : Padding
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    , cachedSize : Coord Pixels
    , inFront : List (Element id msg)
    , onPress : msg
    , onMouseDown : Maybe msg
    }


type Element id msg
    = Text
        { outline : Maybe Color
        , color : Color
        , scale : Int
        , text : String
        , cachedSize : Coord Pixels
        }
    | TextInput
        { id : id
        , width : Int
        , isValid : Bool
        , onKeyDown : Bool -> Bool -> Keyboard.Key -> TextInput.Model -> msg
        }
        TextInput.Model
    | Button (ButtonData id msg) (Element id msg)
    | Row RowColumn (List (Element id msg))
    | Column RowColumn (List (Element id msg))
    | Single
        { padding : Padding
        , borderAndFill : BorderAndFill
        , inFront : List (Element id msg)
        , cachedSize : Coord Pixels
        , ignoreInputs : Bool
        }
        (Element id msg)
    | Quads { size : Coord Pixels, vertices : Coord Pixels -> List Vertex }
    | Empty


type BorderAndFill
    = NoBorderOrFill
    | FillOnly Color
    | BorderAndFill { borderWidth : Int, borderColor : Color, fillColor : Color }


type alias Padding =
    { topLeft : Coord Pixels, bottomRight : Coord Pixels }


noPadding : Padding
noPadding =
    { topLeft = Coord.origin, bottomRight = Coord.origin }


paddingXY : Int -> Int -> Padding
paddingXY x y =
    { topLeft = Coord.xy x y, bottomRight = Coord.xy x y }


paddingXY2 : Coord Pixels -> Padding
paddingXY2 coord =
    { topLeft = coord, bottomRight = coord }


text : String -> Element id msg
text text2 =
    Text
        { outline = Nothing
        , color = Color.black
        , scale = defaultCharScale
        , text = text2
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


scaledText : Int -> String -> Element id msg
scaledText scale text2 =
    Text
        { outline = Nothing
        , color = Color.black
        , scale = scale
        , text = text2
        , cachedSize = Sprite.textSize scale text2
        }


colorText : Color -> String -> Element id msg
colorText color text2 =
    Text
        { outline = Nothing
        , color = color
        , scale = defaultCharScale
        , text = text2
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


colorScaledText : Color -> Int -> String -> Element id msg
colorScaledText color scale text2 =
    Text
        { outline = Nothing
        , color = color
        , scale = scale
        , text = text2
        , cachedSize = Sprite.textSize scale text2
        }


outlinedText : { outline : Color, color : Color, text : String } -> Element id msg
outlinedText data =
    Text
        { outline = Just data.outline
        , color = data.color
        , scale = defaultCharScale
        , text = data.text
        , cachedSize = Sprite.textSize defaultCharScale data.text
        }


defaultCharScale =
    2


addLineBreaks : Int -> Int -> List String -> String -> List String
addLineBreaks charWidth maxWidth list text2 =
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
        addLineBreaks
            charWidth
            maxWidth
            (left2 :: list)
            right

    else
        text2 :: list


wrappedText : Int -> String -> Element id msg
wrappedText maxWidth text2 =
    let
        charWidth : Int
        charWidth =
            Coord.xRaw Sprite.charSize * defaultCharScale

        text3 : String
        text3 =
            List.concatMap
                (addLineBreaks charWidth maxWidth [] >> List.reverse)
                (String.split "\n" text2)
                |> String.join "\n"
    in
    Text
        { outline = Nothing
        , color = Color.black
        , scale = defaultCharScale
        , text = text3
        , cachedSize = Sprite.textSize defaultCharScale text3
        }


textInput :
    { id : id, width : Int, isValid : Bool, onKeyDown : Bool -> Bool -> Keyboard.Key -> TextInput.Model -> msg }
    -> TextInput.Model
    -> Element id msg
textInput =
    TextInput


none : Element id msg
none =
    Empty


button : { id : id, padding : Padding, onPress : msg } -> Element id msg -> Element id msg
button data child =
    Button
        { id = data.id
        , padding = data.padding
        , inFront = []
        , borderAndFill = defaultButtonBorderAndFill
        , borderAndFillFocus =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , fillColor = Color.highlightColor
                }
        , cachedSize =
            Coord.plus
                (Coord.plus data.padding.topLeft data.padding.bottomRight)
                (size child)
        , onPress = data.onPress
        , onMouseDown = Nothing
        }
        child


defaultButtonBorderAndFill : BorderAndFill
defaultButtonBorderAndFill =
    BorderAndFill
        { borderWidth = 2
        , borderColor = Color.outlineColor
        , fillColor = Color.fillColor2
        }


customButton :
    { id : id
    , padding : Padding
    , inFront : List (Element id msg)
    , onPress : msg
    , onMouseDown : Maybe msg
    , borderAndFill : BorderAndFill
    , borderAndFillFocus : BorderAndFill
    }
    -> Element id msg
    -> Element id msg
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
        , onPress = data.onPress
        , onMouseDown = data.onMouseDown
        }
        child


row :
    { spacing : Int, padding : Padding }
    -> List (Element id msg)
    -> Element id msg
row data children =
    Row
        { spacing = data.spacing
        , padding = data.padding
        , cachedSize = rowSize data children
        }
        children


column :
    { spacing : Int, padding : Padding }
    -> List (Element id msg)
    -> Element id msg
column data children =
    Column
        { spacing = data.spacing
        , padding = data.padding
        , cachedSize = columnSize data children
        }
        children


el :
    { padding : Padding, inFront : List (Element id msg), borderAndFill : BorderAndFill }
    -> Element id msg
    -> Element id msg
el data element2 =
    Single
        { padding = data.padding
        , borderAndFill = data.borderAndFill
        , inFront = data.inFront
        , cachedSize = Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight) (size element2)
        , ignoreInputs = False
        }
        element2


center : { size : Coord Pixels } -> Element id msg -> Element id msg
center data element2 =
    let
        size2 : Coord Pixels
        size2 =
            size element2

        topLeft : Coord Pixels
        topLeft =
            data.size |> Coord.minus size2 |> Coord.divide (Coord.xy 2 2)
    in
    Single
        { padding =
            { topLeft = topLeft
            , bottomRight = data.size |> Coord.minus size2 |> Coord.minus topLeft
            }
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = data.size
        , ignoreInputs = False
        }
        element2


topRight : { size : Coord Pixels } -> Element id msg -> Element id msg
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
        , ignoreInputs = False
        }
        element2


bottomLeft : { size : Coord Pixels } -> Element id msg -> Element id msg
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
        , ignoreInputs = False
        }
        element2


bottomCenter : { size : Coord Pixels, inFront : List (Element id msg) } -> Element id msg -> Element id msg
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
        , ignoreInputs = False
        }
        element2


ignoreInputs : Element id msg -> Element id msg
ignoreInputs element2 =
    Single
        { padding = noPadding
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , cachedSize = size element2
        , ignoreInputs = True
        }
        element2


sprite : { size : Coord Pixels, texturePosition : Coord Pixels, textureSize : Coord Pixels } -> Element id msg
sprite data =
    Quads
        { size = data.size
        , vertices = \position -> Sprite.sprite position data.size data.texturePosition data.textureSize
        }


colorSprite :
    { colors : Colors, size : Coord Pixels, texturePosition : Coord Pixels, textureSize : Coord Pixels }
    -> Element id msg
colorSprite data =
    Quads
        { size = data.size
        , vertices = \position -> Sprite.spriteWithTwoColors data.colors position data.size data.texturePosition data.textureSize
        }


quads : { size : Coord Pixels, vertices : Coord Pixels -> List Vertex } -> Element id msg
quads =
    Quads


type HoverType id msg
    = NoHover
    | InputHover { id : id, position : Coord Pixels }
    | BackgroundHover


hover : Coord Pixels -> Element id msg -> HoverType id msg
hover point element2 =
    hoverHelper point Coord.origin element2


hoverHelper : Coord Pixels -> Coord Pixels -> Element id msg -> HoverType id msg
hoverHelper point elementPosition element2 =
    case element2 of
        Text _ ->
            NoHover

        TextInput data _ ->
            if Bounds.fromCoordAndSize elementPosition (TextInput.size (Quantity data.width)) |> Bounds.contains point then
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
            if data.ignoreInputs then
                NoHover

            else
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


hoverRowColumnHelper :
    Bool
    -> Coord Pixels
    -> Coord Pixels
    -> RowColumn
    -> List (Element id msg)
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


view : Maybe id -> Element id msg -> WebGL.Mesh Vertex
view focus element2 =
    viewHelper focus Coord.origin [] element2 |> Sprite.toMesh


verticesHelper : Maybe id -> Coord Pixels -> List Vertex -> { a | inFront : List (Element id msg) } -> List Vertex
verticesHelper focus position vertices data =
    List.foldl
        (\inFront vertices3 ->
            viewHelper focus position vertices3 inFront
        )
        vertices
        data.inFront


viewHelper : Maybe id -> Coord Pixels -> List Vertex -> Element id msg -> List Vertex
viewHelper focus position vertices element2 =
    case element2 of
        Text data ->
            (case data.outline of
                Just outline ->
                    Sprite.outlinedText outline data.color data.scale data.text position

                Nothing ->
                    Sprite.text data.color data.scale data.text position
            )
                ++ vertices

        TextInput data model ->
            TextInput.view position (Quantity data.width) (focus == Just data.id) data.isValid model ++ vertices

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
            data.vertices position ++ vertices

        Empty ->
            vertices


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


size : Element id msg -> Coord Pixels
size element2 =
    case element2 of
        Text data ->
            data.cachedSize

        TextInput data _ ->
            TextInput.size (Quantity data.width)

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


rowSize : { a | spacing : Int, padding : Padding } -> List (Element id msg) -> Coord Pixels
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


columnSize : { a | spacing : Int, padding : Padding } -> List (Element id msg) -> Coord Pixels
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


findTextInput : id -> Element id msg -> Maybe ( Bool -> Bool -> Keyboard.Key -> TextInput.Model -> msg, TextInput.Model )
findTextInput id element =
    case element of
        Text _ ->
            Nothing

        TextInput data textInput2 ->
            if id == data.id then
                Just ( data.onKeyDown, textInput2 )

            else
                Nothing

        Button _ _ ->
            Nothing

        Row _ children ->
            List.findMap (findTextInput id) children

        Column _ children ->
            List.findMap (findTextInput id) children

        Single data child ->
            List.findMap (findTextInput id) (child :: data.inFront)

        Quads _ ->
            Nothing

        Empty ->
            Nothing


findButton : id -> Element id msg -> Maybe { buttonData : ButtonData id msg, position : Coord Pixels }
findButton id element =
    findButtonHelper id Coord.origin element


findButtonHelper : id -> Coord Pixels -> Element id msg -> Maybe { buttonData : ButtonData id msg, position : Coord Pixels }
findButtonHelper id position element =
    case element of
        Text _ ->
            Nothing

        TextInput _ _ ->
            Nothing

        Button data _ ->
            if data.id == id then
                Just { buttonData = data, position = position }

            else
                Nothing

        Row data children ->
            List.foldl
                (\child state ->
                    case state.result of
                        Just _ ->
                            state

                        Nothing ->
                            { result = findButtonHelper id state.position child
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
                            { result = findButtonHelper id state.position child
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
            case List.findMap (findButtonHelper id position2) (child :: data.inFront) of
                Just result ->
                    Just result

                Nothing ->
                    findButtonHelper id position2 child

        Quads _ ->
            Nothing

        Empty ->
            Nothing


handleKeyDown :
    (msg -> model -> model2)
    -> msg
    -> Element id msg
    -> Maybe id
    -> Bool
    -> Bool
    -> Keyboard.Key
    -> model
    -> model2
handleKeyDown updateFunc keyUnhandled element maybeFocus ctrlOrMetaDown shiftDown key model =
    case maybeFocus of
        Just focus ->
            case findTextInput focus element of
                Just ( onKeyDown, textInput2 ) ->
                    updateFunc (onKeyDown ctrlOrMetaDown shiftDown key textInput2) model

                Nothing ->
                    updateFunc keyUnhandled model

        Nothing ->
            updateFunc keyUnhandled model


tabForward : id -> Element id msg -> id
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


tabBackward : id -> Element id msg -> id
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


tabHelper : Bool -> Bool -> id -> Element id msg -> TabForward id
tabHelper stepForward hasFoundId id element =
    case element of
        Text _ ->
            if hasFoundId then
                FoundId

            else
                NotFound

        TextInput data _ ->
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


rowColumnTabHelper : Bool -> Bool -> id -> List (Element id msg) -> TabForward id
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
