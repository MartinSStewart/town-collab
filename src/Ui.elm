module Ui exposing
    ( BorderAndBackground(..)
    , Element
    , HoverType(..)
    , Padding
    , bottomLeft
    , button
    , center
    , colorSprite
    , colorText
    , column
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
    )

import Bounds
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Shaders exposing (Vertex)
import Sprite
import TextInput
import WebGL


type alias RowColumn units =
    { spacing : Quantity Int units
    , padding : Padding units
    , borderAndBackground : BorderAndBackground units
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
    | TextInput { id : id, width : Quantity Int units, isValid : Bool } TextInput.Model
    | Button
        { id : id
        , padding : Padding units
        , cachedSize : Coord units
        , inFront : List (Element id units)
        }
        (Element id units)
    | Row (RowColumn units) (List (Element id units))
    | Column (RowColumn units) (List (Element id units))
    | Quads { size : Coord units, vertices : Coord units -> List Vertex }
    | Empty


type BorderAndBackground units
    = NoBorderOrBackground
    | BackgroundOnly Color
    | BorderAndBackground { borderWidth : Quantity Int units, borderColor : Color, backgroundColor : Color }


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
    Text { outline = Nothing, color = Color.black, scale = 2, text = text2, cachedSize = Sprite.textSize 2 text2 }


colorText : Color -> String -> Element id units
colorText color text2 =
    Text { outline = Nothing, color = color, scale = 2, text = text2, cachedSize = Sprite.textSize 2 text2 }


outlinedText : { outline : Color, color : Color, text : String } -> Element id units
outlinedText data =
    Text
        { outline = Just data.outline
        , color = data.color
        , scale = 2
        , text = data.text
        , cachedSize = Sprite.textSize 2 data.text
        }


textInput : { id : id, width : Quantity Int units, isValid : Bool } -> TextInput.Model -> Element id units
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
        , cachedSize =
            Coord.plus
                (Coord.plus data.padding.topLeft data.padding.bottomRight)
                (size child)
        }
        child


row :
    { spacing : Quantity Int units
    , padding : Padding units
    , borderAndBackground : BorderAndBackground units
    }
    -> List (Element id units)
    -> Element id units
row data children =
    Row
        { spacing = data.spacing
        , padding = data.padding
        , borderAndBackground = data.borderAndBackground
        , cachedSize = rowSize data children
        }
        children


column :
    { spacing : Quantity Int units
    , padding : Padding units
    , borderAndBackground : BorderAndBackground units
    }
    -> List (Element id units)
    -> Element id units
column data children =
    Column
        { spacing = data.spacing
        , padding = data.padding
        , borderAndBackground = data.borderAndBackground
        , cachedSize = columnSize data children
        }
        children


el :
    { padding : Padding units, borderAndBackground : BorderAndBackground units }
    -> Element id units
    -> Element id units
el data element2 =
    Row
        { padding = data.padding
        , borderAndBackground = data.borderAndBackground
        , spacing = Quantity.zero
        , cachedSize =
            Coord.plus
                (Coord.plus data.padding.topLeft data.padding.bottomRight)
                (size element2)
        }
        [ element2 ]


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
    Row
        { padding =
            { topLeft = topLeft
            , bottomRight = data.size |> Coord.minus size2 |> Coord.minus topLeft
            }
        , borderAndBackground = NoBorderOrBackground
        , spacing = Quantity.zero
        , cachedSize = data.size
        }
        [ element2 ]


bottomLeft : { size : Coord units } -> Element id units -> Element id units
bottomLeft data element2 =
    let
        ( sizeX, sizeY ) =
            Coord.toTuple data.size

        ( childSizeX, childSizeY ) =
            Coord.toTuple (size element2)
    in
    Row
        { padding =
            { topLeft = Coord.xy 0 (sizeY - childSizeY)
            , bottomRight = Coord.xy (sizeX - childSizeX) 0
            }
        , borderAndBackground = NoBorderOrBackground
        , spacing = Quantity.zero
        , cachedSize = data.size
        }
        [ element2 ]


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
            if Bounds.fromCoordAndSize elementPosition (TextInput.size data.width) |> Bounds.contains point then
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
    let
        hover2 : HoverType id units
        hover2 =
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
                                            Coord.xy (sizeX + Quantity.unwrap data.spacing) 0

                                         else
                                            Coord.xy 0 (sizeY + Quantity.unwrap data.spacing)
                                        )
                            , hover = hoverHelper point state.elementPosition child
                            }

                        _ ->
                            state
                )
                { elementPosition = elementPosition |> Coord.plus data.padding.topLeft, hover = NoHover }
                children
                |> .hover
    in
    case ( data.borderAndBackground, hover2 ) of
        ( BorderAndBackground _, NoHover ) ->
            if
                Bounds.fromCoordAndSize
                    elementPosition
                    (size
                        (if isRow then
                            Row data children

                         else
                            Column data children
                        )
                    )
                    |> Bounds.contains point
            then
                BackgroundHover

            else
                NoHover

        _ ->
            hover2


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
            TextInput.view position data.width (focus == Just data.id) data.isValid model ++ vertices

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
            Sprite.rectangle Color.outlineColor position data.cachedSize
                ++ Sprite.rectangle
                    (if Just data.id == focus then
                        Color.highlightColor

                     else
                        Color.fillColor
                    )
                    (position |> Coord.plus (Coord.xy 2 2))
                    (data.cachedSize |> Coord.minus (Coord.xy 4 4))
                ++ viewHelper focus (Coord.plus data.padding.topLeft position) vertices2 child

        Row data children ->
            List.foldl
                (\child state ->
                    { vertices = viewHelper focus state.position state.vertices child
                    , position =
                        Coord.xy (Coord.xRaw (size child) + Quantity.unwrap data.spacing) 0
                            |> Coord.plus state.position
                    }
                )
                { position = Coord.plus data.padding.topLeft position
                , vertices = vertices
                }
                children
                |> .vertices
                |> (++) (borderAndBackgroundView position data (size element2))

        Column data children ->
            List.foldl
                (\child state ->
                    { vertices = viewHelper focus state.position state.vertices child
                    , position =
                        Coord.xy 0 (Coord.yRaw (size child) + Quantity.unwrap data.spacing)
                            |> Coord.plus state.position
                    }
                )
                { position = Coord.plus data.padding.topLeft position
                , vertices = vertices
                }
                children
                |> .vertices
                |> (++) (borderAndBackgroundView position data (size element2))

        Quads data ->
            data.vertices position ++ vertices

        Empty ->
            vertices


borderAndBackgroundView :
    Coord unit
    -> { a | borderAndBackground : BorderAndBackground unit }
    -> Coord unit
    -> List Vertex
borderAndBackgroundView position data size2 =
    case data.borderAndBackground of
        NoBorderOrBackground ->
            []

        BackgroundOnly color ->
            Sprite.rectangle color position size2

        BorderAndBackground { borderWidth, borderColor, backgroundColor } ->
            Sprite.rectangle borderColor position size2
                ++ Sprite.rectangle
                    backgroundColor
                    (Coord.plus ( borderWidth, borderWidth ) position)
                    (size2 |> Coord.minus (Coord.multiply (Coord.xy 2 2) ( borderWidth, borderWidth )))


size : Element id units -> Coord units
size element2 =
    case element2 of
        Text data ->
            data.cachedSize

        TextInput data _ ->
            TextInput.size data.width

        Button data _ ->
            data.cachedSize

        Row data _ ->
            data.cachedSize

        Column data _ ->
            data.cachedSize

        Quads data ->
            data.size

        Empty ->
            Coord.origin


rowSize : { a | spacing : Quantity Int units, padding : Padding units } -> List (Element id units) -> Coord units
rowSize data children =
    List.foldl
        (\child ( x, y ) ->
            let
                size2 =
                    size child
            in
            ( Coord.xRaw size2 + Quantity.unwrap data.spacing + x
            , max (Coord.yRaw size2) y
            )
        )
        ( 0, 0 )
        children
        |> Coord.tuple
        |> Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight)


columnSize : { a | spacing : Quantity Int units, padding : Padding units } -> List (Element id units) -> Coord units
columnSize data children =
    List.foldl
        (\child ( x, y ) ->
            let
                size2 =
                    size child
            in
            ( max (Coord.xRaw size2) x
            , Coord.yRaw size2 + Quantity.unwrap data.spacing + y
            )
        )
        ( 0, 0 )
        children
        |> Coord.tuple
        |> Coord.plus (Coord.plus data.padding.topLeft data.padding.bottomRight)
