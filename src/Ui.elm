module Ui exposing
    ( BorderAndFill(..)
    , Element
    , HoverType(..)
    , Padding
    , bottomCenter
    , bottomLeft
    , button
    , center
    , colorSprite
    , colorText
    , column
    , customButton
    , el
    , empty
    , hover
    , noPadding
    , outlinedText
    , paddingXY
    , paddingXY2
    , quads
    , row
    , size
    , sprite
    , text
    , textInput
    , view
    , wrappedText
    )

import Bounds
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import List.Extra as List
import Pixels exposing (Pixels)
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite
import TextInput
import WebGL


type alias RowColumn units =
    { spacing : Int
    , padding : Padding units
    , cachedSize : Coord units
    }


type Element id units
    = Text
        { outline : Maybe Color
        , color : Color
        , scale : Int
        , text : String
        , cachedSize : Coord units
        }
    | TextInput { id : id, width : Int, isValid : Bool } TextInput.Model
    | Button
        { id : id
        , padding : Padding units
        , borderAndFill : BorderAndFill units
        , borderAndFillFocus : BorderAndFill units
        , cachedSize : Coord units
        , inFront : List (Element id units)
        }
        (Element id units)
    | Row (RowColumn units) (List (Element id units))
    | Column (RowColumn units) (List (Element id units))
    | Single
        { padding : Padding units
        , borderAndFill : BorderAndFill units
        , inFront : List (Element id units)
        , cachedSize : Coord units
        }
        (Element id units)
    | Quads { size : Coord units, vertices : Coord units -> List Vertex }
    | Empty


type BorderAndFill units
    = NoBorderOrFill
    | FillOnly Color
    | BorderAndFill { borderWidth : Int, borderColor : Color, fillColor : Color }


type alias Padding units =
    { topLeft : Coord units, bottomRight : Coord units }


noPadding : Padding units
noPadding =
    { topLeft = Coord.origin, bottomRight = Coord.origin }


paddingXY : Int -> Int -> Padding units
paddingXY x y =
    { topLeft = Coord.xy x y, bottomRight = Coord.xy x y }


paddingXY2 : Coord units -> Padding units
paddingXY2 coord =
    { topLeft = coord, bottomRight = coord }


text : String -> Element id units
text text2 =
    Text
        { outline = Nothing
        , color = Color.black
        , scale = defaultCharScale
        , text = text2
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


colorText : Color -> String -> Element id units
colorText color text2 =
    Text
        { outline = Nothing
        , color = color
        , scale = defaultCharScale
        , text = text2
        , cachedSize = Sprite.textSize defaultCharScale text2
        }


outlinedText : { outline : Color, color : Color, text : String } -> Element id units
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


wrappedText : Int -> String -> Element id units
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


textInput : { id : id, width : Int, isValid : Bool } -> TextInput.Model -> Element id units
textInput =
    TextInput


empty : Element id units
empty =
    Empty


button :
    { id : id, padding : Padding units, inFront : List (Element id units) }
    -> Element id units
    -> Element id units
button data child =
    Button
        { id = data.id
        , padding = data.padding
        , inFront = data.inFront
        , borderAndFill =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , fillColor = Color.fillColor
                }
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
        }
        child


customButton :
    { id : id
    , padding : Padding units
    , inFront : List (Element id units)
    , borderAndFill : BorderAndFill units
    , borderAndFillFocus : BorderAndFill units
    }
    -> Element id units
    -> Element id units
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


row :
    { spacing : Int, padding : Padding units }
    -> List (Element id units)
    -> Element id units
row data children =
    Row
        { spacing = data.spacing
        , padding = data.padding
        , cachedSize = rowSize data children
        }
        children


column :
    { spacing : Int, padding : Padding units }
    -> List (Element id units)
    -> Element id units
column data children =
    Column
        { spacing = data.spacing
        , padding = data.padding
        , cachedSize = columnSize data children
        }
        children


el :
    { padding : Padding units, inFront : List (Element id units), borderAndFill : BorderAndFill units }
    -> Element id units
    -> Element id units
el data element2 =
    Single
        { padding = data.padding
        , borderAndFill = data.borderAndFill
        , inFront = data.inFront
        , cachedSize = Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight) (size element2)
        }
        element2


center : { size : Coord units } -> Element id units -> Element id units
center data element2 =
    let
        size2 : Coord units
        size2 =
            size element2

        topLeft : Coord units
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
        }
        element2


bottomLeft : { size : Coord units } -> Element id units -> Element id units
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


bottomCenter : { size : Coord units, inFront : List (Element id units) } -> Element id units -> Element id units
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


sprite : { size : Coord units, texturePosition : Coord Pixels, textureSize : Coord Pixels } -> Element id units
sprite data =
    Quads
        { size = data.size
        , vertices = \position -> Sprite.sprite position data.size data.texturePosition data.textureSize
        }


colorSprite :
    { colors : Colors, size : Coord units, texturePosition : Coord Pixels, textureSize : Coord Pixels }
    -> Element id units
colorSprite data =
    Quads
        { size = data.size
        , vertices = \position -> Sprite.spriteWithTwoColors data.colors position data.size data.texturePosition data.textureSize
        }


quads : { size : Coord units, vertices : Coord units -> List Vertex } -> Element id units
quads =
    Quads


type HoverType id units
    = NoHover
    | InputHover { id : id, position : Coord units }
    | BackgroundHover


hover : Coord units -> Element id units -> HoverType id units
hover point element2 =
    hoverHelper point Coord.origin element2


hoverHelper : Coord units -> Coord units -> Element id units -> HoverType id units
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
            let
                hover2 : HoverType id units
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

                hover3 : HoverType id units
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
    -> Coord units
    -> Coord units
    -> RowColumn units
    -> List (Element id units)
    -> HoverType id units
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


view : Maybe id -> Element id units -> WebGL.Mesh Vertex
view focus element2 =
    viewHelper focus Coord.origin [] element2 |> Sprite.toMesh


viewHelper : Maybe id -> Coord units -> List Vertex -> Element id units -> List Vertex
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
            borderAndFillView position
                (if Just data.id == focus then
                    data.borderAndFillFocus

                 else
                    data.borderAndFill
                )
                data.cachedSize
                ++ viewHelper focus (Coord.plus data.padding.topLeft position) vertices2 child

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
    Coord units
    -> BorderAndFill units
    -> Coord units
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
                    (size2 |> Coord.minus (Coord.multiply (Coord.xy 2 2) (Coord.xy borderWidth borderWidth)))


size : Element id units -> Coord units
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


rowSize : { a | spacing : Int, padding : Padding units } -> List (Element id units) -> Coord units
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


columnSize : { a | spacing : Int, padding : Padding units } -> List (Element id units) -> Coord units
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
