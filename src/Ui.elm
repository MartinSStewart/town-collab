module Ui exposing
    ( BorderAndBackground(..)
    , Element
    , HoverType(..)
    , Padding
    , button
    , colorText
    , column
    , element
    , hover
    , noPadding
    , paddingXY
    , paddingXY2
    , row
    , size
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
    }


type Element id units
    = Text { color : Color, scale : Int, text : String }
    | TextInput { id : id, width : Quantity Int units, isValid : Bool } TextInput.Model
    | Button { id : id, padding : Padding units, label : Element id units }
    | Row (RowColumn units) (List (Element id units))
    | Column (RowColumn units) (List (Element id units))
    | Sprite { colors : Colors, size : Coord units, texturePosition : Coord Pixels, textureSize : Coord Pixels }


type BorderAndBackground units
    = NoBorderOrBackground
    | BackgroundOnly Color
    | BorderAndBackground { borderWidth : Quantity Int units, borderColor : Color, backgroundColor : Color }


type alias Padding units =
    { topLeft : Coord units, bottomRight : Coord units }


noPadding =
    { topLeft = Coord.origin, bottomRight = Coord.origin }


paddingXY x y =
    { topLeft = Coord.xy x y, bottomRight = Coord.xy x y }


paddingXY2 coord =
    { topLeft = coord, bottomRight = coord }


text : String -> Element id units
text text2 =
    Text { color = Color.black, scale = 2, text = text2 }


colorText : Color -> String -> Element id units
colorText color text2 =
    Text { color = color, scale = 2, text = text2 }


textInput : { id : id, width : Quantity Int units, isValid : Bool } -> TextInput.Model -> Element id units
textInput =
    TextInput


button : { id : id, padding : Padding units, label : Element id units } -> Element id units
button =
    Button


row :
    { spacing : Quantity Int units
    , padding : Padding units
    , borderAndBackground : BorderAndBackground units
    }
    -> List (Element id units)
    -> Element id units
row =
    Row


column :
    { spacing : Quantity Int units
    , padding : Padding units
    , borderAndBackground : BorderAndBackground units
    }
    -> List (Element id units)
    -> Element id units
column =
    Column


element :
    { padding : Padding units
    , borderAndBackground : BorderAndBackground units
    }
    -> Element id units
    -> Element id units
element { padding, borderAndBackground } element2 =
    Row
        { padding = padding
        , borderAndBackground = borderAndBackground
        , spacing = Quantity.zero
        }
        [ element2 ]


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

        Button data ->
            if Bounds.fromCoordAndSize elementPosition (size (Button data)) |> Bounds.contains point then
                InputHover { id = data.id, position = elementPosition }

            else
                NoHover

        Row data children ->
            hoverRowColumnHelper True point elementPosition data children

        Column data children ->
            hoverRowColumnHelper False point elementPosition data children

        Sprite _ ->
            NoHover


hoverRowColumnHelper :
    Bool
    -> Coord units
    -> Coord units
    -> { spacing : Quantity Int units, padding : Padding units, borderAndBackground : BorderAndBackground units }
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
            Sprite.text data.color data.scale data.text position ++ vertices

        TextInput data model ->
            TextInput.view
                position
                data.width
                (focus == Just data.id)
                data.isValid
                model
                ++ vertices

        Button data ->
            let
                size2 =
                    size (Button data)
            in
            Sprite.rectangle Color.outlineColor position size2
                ++ Sprite.rectangle
                    (if Just data.id == focus then
                        Color.highlightColor

                     else
                        Color.fillColor
                    )
                    (position |> Coord.plus (Coord.xy 2 2))
                    (size2 |> Coord.minus (Coord.xy 4 4))
                ++ viewHelper focus (Coord.plus data.padding.topLeft position) vertices data.label

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

        Sprite data ->
            Sprite.spriteWithTwoColors data.colors position data.size data.texturePosition data.textureSize


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
            Sprite.textSize data.scale data.text

        TextInput data _ ->
            TextInput.size data.width

        Button data ->
            Coord.plus
                (Coord.plus data.padding.topLeft data.padding.bottomRight)
                (size data.label)

        Row data children ->
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

        Column data children ->
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

        Sprite data ->
            data.size
