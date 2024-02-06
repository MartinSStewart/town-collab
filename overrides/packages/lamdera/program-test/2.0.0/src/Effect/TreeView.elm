module Effect.TreeView exposing (CollapsedField(..), MsgConfig, PathNode, pathNodeToKey, treeView, treeViewDiff)

import DebugParser exposing (ElmValue(..), ExpandableValue(..))
import Dict exposing (Dict)
import Html exposing (Attribute, Html)
import Html.Attributes
import Html.Events
import Html.Lazy


type PathNode
    = FieldNode String
    | VariantNode String
    | SequenceNode Int
    | DictNode ElmValue
    | DictKeyNode ElmValue


pathNodeToKey : PathNode -> String
pathNodeToKey pathNode =
    case pathNode of
        FieldNode string ->
            "q_" ++ string

        VariantNode string ->
            "r_" ++ string

        SequenceNode int ->
            "s_" ++ String.fromInt int

        DictNode elmValue ->
            "t_" ++ elmValueToKey elmValue

        DictKeyNode elmValue ->
            "u_" ++ elmValueToKey elmValue


type CollapsedField
    = FieldIsCollapsed
    | FieldIsExpanded


type alias MsgConfig msg =
    { pressedExpandField : List PathNode -> msg
    , pressedCollapseField : List PathNode -> msg
    }


inputButton : List (Attribute msg) -> { onPress : msg, label : Html msg } -> Html msg
inputButton attributes { onPress, label } =
    Html.button
        (Html.Attributes.style "border-width" "0"
            :: Html.Attributes.style "background-color" "transparent"
            :: Html.Attributes.style "color" "inherit"
            :: Html.Attributes.style "font-size" "inherit"
            :: Html.Attributes.style "font-family" "inherit"
            :: Html.Attributes.style "font-weight" "inherit"
            :: Html.Attributes.style "padding" "0"
            :: Html.Attributes.style "margin" "0"
            :: Html.Events.onClick onPress
            :: attributes
        )
        [ label ]


htmlColumn : List (Attribute msg) -> List (Html msg) -> Html msg
htmlColumn attributes children =
    Html.div attributes children


rgb : Float -> Float -> Float -> String
rgb r g b =
    let
        a color =
            String.fromInt (round (color * 255))
    in
    "rgb(" ++ a r ++ "," ++ a g ++ "," ++ a b ++ ")"


backgroundColor : String -> Attribute msg
backgroundColor color =
    Html.Attributes.style "background-color" color


newColor : Attribute msg
newColor =
    backgroundColor (rgb 0.15 0.35 0.15)


oldColor : Attribute msg
oldColor =
    backgroundColor (rgb 0.35 0.17 0.17)


htmlEl : List (Attribute msg) -> Html msg -> Html msg
htmlEl attributes child =
    Html.div attributes [ child ]


htmlRow : List (Attribute msg) -> List (Html msg) -> Html msg
htmlRow attributes children =
    Html.div
        attributes
        (List.map
            (\item ->
                Html.div
                    [ Html.Attributes.style "display" "inline-block", Html.Attributes.style "vertical-align" "top" ]
                    [ item ]
            )
            children
        )


fontColor : String -> Attribute msg
fontColor color =
    Html.Attributes.style "color" color


borderColor : String -> Attribute msg
borderColor color =
    Html.Attributes.style "border-color" color


htmlText : String -> Html msg
htmlText text =
    Html.text text


numberText : Float -> Html msg
numberText number =
    htmlEl [ fontColor (rgb 0.7 0.4 0.5) ] (htmlText (String.fromFloat number))


stringText : String -> Html msg
stringText text =
    htmlEl [ fontColor (rgb 0.3 0.6 0.3) ] (htmlText ("\"" ++ text ++ "\""))


charText : Char -> Html msg
charText char =
    htmlEl [ fontColor (rgb 0.3 0.5 0.3) ] (htmlText ("'" ++ String.fromChar char ++ "'"))


heightFill : Attribute msg
heightFill =
    Html.Attributes.style "height" "100%"


widthEach : { left : Int, top : Int, right : Int, bottom : Int } -> Attribute msg
widthEach widths =
    Html.Attributes.style
        "border-width"
        (String.fromInt widths.left
            ++ "px "
            ++ String.fromInt widths.top
            ++ "px "
            ++ String.fromInt widths.right
            ++ "px "
            ++ String.fromInt widths.bottom
            ++ "px"
        )


alignTop : Attribute msg
alignTop =
    Html.Attributes.style "top" "0px"


centerY : List (Attribute msg)
centerY =
    [ Html.Attributes.style "top" "auto", Html.Attributes.style "bottom" "auto" ]


emptyDict : Html msg
emptyDict =
    htmlEl [ fontColor (rgb 0.5 0.5 0.5) ] (htmlText "<empty dict>")


collapsedValueDiff : ElmValue -> ElmValue -> Html msg
collapsedValueDiff oldValue newValue =
    if oldValue == newValue then
        collapsedValue newValue

    else
        htmlEl [ newColor ] (collapsedValue newValue)


collapsedValue : ElmValue -> Html msg
collapsedValue value =
    htmlEl
        [ fontColor (rgb 0.5 0.5 0.5) ]
        (htmlText
            (case value of
                Plain _ ->
                    "<primitive>"

                Expandable expandableValue ->
                    case expandableValue of
                        ElmSequence sequenceType elmValues ->
                            case sequenceType of
                                DebugParser.SeqSet ->
                                    "<set, " ++ items (List.length elmValues)

                                DebugParser.SeqList ->
                                    "<list, " ++ items (List.length elmValues)

                                DebugParser.SeqArray ->
                                    "<array, " ++ items (List.length elmValues)

                                DebugParser.SeqTuple ->
                                    "<tuple " ++ String.fromInt (List.length elmValues) ++ ">"

                        ElmType variant _ ->
                            "<" ++ variant ++ ">"

                        ElmRecord _ ->
                            "<record>"

                        ElmDict list ->
                            "<dict, " ++ items (List.length list)
            )
        )


items : Int -> String
items count =
    if count == 1 then
        "1 item>"

    else
        String.fromInt count ++ " items>"


variantText variant =
    htmlEl [ fontColor (rgb 0.5 0.4 0.9) ] (htmlText variant)


plainValueToString : DebugParser.PlainValue -> Html msg
plainValueToString value =
    case value of
        DebugParser.ElmString string ->
            stringText string

        DebugParser.ElmChar char ->
            charText char

        DebugParser.ElmNumber float ->
            numberText float

        DebugParser.ElmBool bool ->
            if bool then
                htmlText "True"

            else
                htmlText "False"

        DebugParser.ElmFunction ->
            htmlText "<function>"

        DebugParser.ElmInternals ->
            htmlText "<internal>"

        DebugParser.ElmUnit ->
            htmlText "()"

        DebugParser.ElmFile string ->
            htmlText ("<file named " ++ string ++ ">")

        DebugParser.ElmBytes int ->
            htmlText ("<" ++ String.fromInt int ++ " bytes>")


singleLineView : ElmValue -> Html msg
singleLineView value =
    case value of
        Plain plainValue ->
            plainValueToString plainValue

        Expandable expandableValue ->
            case expandableValue of
                ElmSequence sequenceType _ ->
                    let
                        ( startChar, endChar ) =
                            sequenceStartEnd sequenceType
                    in
                    startChar ++ " ... " ++ endChar |> htmlText

                ElmType variant elmValues ->
                    (variantText variant :: List.map singleLineView elmValues)
                        |> List.intersperse (Html.text " ")
                        |> htmlRow []

                ElmRecord _ ->
                    htmlText "{ ... }"

                ElmDict _ ->
                    htmlText "{{ ... }}"


sequenceStartEnd : DebugParser.SequenceType -> ( String, String )
sequenceStartEnd sequenceType =
    case sequenceType of
        DebugParser.SeqSet ->
            ( "{|", "|}" )

        DebugParser.SeqList ->
            ( "[", "]" )

        DebugParser.SeqArray ->
            ( "[|", "|]" )

        DebugParser.SeqTuple ->
            ( "(", ")" )


isSingleLine : ElmValue -> Bool
isSingleLine elmValue =
    case elmValue of
        Plain _ ->
            True

        Expandable expandable ->
            case expandable of
                ElmSequence _ elmValues ->
                    List.isEmpty elmValues

                ElmType _ elmValues ->
                    List.isEmpty elmValues

                ElmRecord _ ->
                    False

                ElmDict dict ->
                    List.isEmpty dict


indexedMap2 : (Int -> a -> b -> c) -> List a -> List b -> List c
indexedMap2 func listA listB =
    List.map2 Tuple.pair listA listB
        |> List.indexedMap (\index ( a, b ) -> func index a b)


treeViewDiff : MsgConfig msg -> Int -> List PathNode -> Dict (List String) CollapsedField -> ElmValue -> ElmValue -> Html msg
treeViewDiff msgConfig depth currentPath collapsedFields oldValue value =
    case ( oldValue, value ) of
        ( Plain oldPlainValue, Plain plainValue ) ->
            if plainValue == oldPlainValue then
                plainValueToString plainValue

            else
                htmlColumn
                    []
                    [ plainValueToString oldPlainValue |> htmlEl [ oldColor ]
                    , plainValueToString plainValue |> htmlEl [ newColor ]
                    ]

        ( Expandable oldExpandableValue, Expandable expandableValue ) ->
            case ( oldExpandableValue, expandableValue ) of
                ( ElmSequence _ oldElmValues, ElmSequence sequenceType elmValues ) ->
                    if List.isEmpty oldElmValues && List.isEmpty elmValues then
                        let
                            ( startChar, endChar ) =
                                sequenceStartEnd sequenceType
                        in
                        htmlText (startChar ++ endChar)

                    else
                        let
                            ( startChar, endChar ) =
                                sequenceStartEnd sequenceType

                            lengthDiff : Int
                            lengthDiff =
                                List.length elmValues - List.length oldElmValues

                            newItems : List (Html msg)
                            newItems =
                                if lengthDiff > 0 then
                                    List.reverse elmValues
                                        |> List.take lengthDiff
                                        |> List.reverse
                                        |> List.indexedMap
                                            (\index a ->
                                                htmlEl [ newColor ] (treeView msgConfig (depth + 1) (SequenceNode index :: currentPath) collapsedFields a)
                                            )

                                else
                                    List.reverse oldElmValues
                                        |> List.take -lengthDiff
                                        |> List.reverse
                                        |> List.indexedMap
                                            (\index a ->
                                                htmlEl [ oldColor ] (treeView msgConfig (depth + 1) (SequenceNode index :: currentPath) collapsedFields a)
                                            )

                            pairedItems : List (Html msg)
                            pairedItems =
                                indexedMap2
                                    (\index old new ->
                                        treeViewDiff msgConfig (depth + 1) (SequenceNode index :: currentPath) collapsedFields old new
                                    )
                                    oldElmValues
                                    elmValues
                        in
                        htmlColumn
                            []
                            (List.indexedMap
                                (\index a ->
                                    if index == 0 then
                                        htmlRow []
                                            [ htmlEl
                                                [ alignTop ]
                                                (htmlText (String.padRight 2 ' ' startChar))
                                            , a
                                            ]

                                    else
                                        htmlRow []
                                            [ htmlEl
                                                [ alignTop ]
                                                (htmlText ", ")
                                            , a
                                            ]
                                )
                                (pairedItems ++ newItems)
                                ++ [ htmlText endChar ]
                            )

                ( ElmType oldVariant oldElmValues, ElmType variant elmValues ) ->
                    if oldVariant == variant then
                        case ( oldElmValues, elmValues ) of
                            ( [ oldSingle ], [ single ] ) ->
                                if isSingleLine single then
                                    htmlRow
                                        []
                                        [ htmlEl [ alignTop ] (variantText variant)
                                        , htmlText " "
                                        , treeViewDiff
                                            msgConfig
                                            (depth + 1)
                                            (VariantNode variant :: currentPath)
                                            collapsedFields
                                            oldSingle
                                            single
                                        ]

                                else
                                    htmlColumn
                                        []
                                        [ variantText variant
                                        , htmlEl
                                            [ tabAmount ]
                                            (treeViewDiff
                                                msgConfig
                                                (depth + 1)
                                                (VariantNode variant :: currentPath)
                                                collapsedFields
                                                oldSingle
                                                single
                                            )
                                        ]

                            _ ->
                                htmlColumn
                                    []
                                    [ variantText variant
                                    , htmlColumn
                                        [ tabAmount ]
                                        (List.map2
                                            (treeViewDiff msgConfig (depth + 1) (VariantNode variant :: currentPath) collapsedFields)
                                            oldElmValues
                                            elmValues
                                        )
                                    ]

                    else
                        htmlColumn
                            []
                            [ htmlEl [ oldColor ] (treeView msgConfig (depth + 1) (VariantNode oldVariant :: currentPath) collapsedFields oldValue)
                            , htmlEl [ newColor ] (treeView msgConfig (depth + 1) (VariantNode variant :: currentPath) collapsedFields value)
                            ]

                ( ElmRecord oldRecord, ElmRecord record ) ->
                    htmlColumn
                        []
                        (List.map2
                            (\( _, oldElmValue ) ( fieldName, elmValue ) ->
                                let
                                    nextPath =
                                        FieldNode fieldName :: currentPath
                                in
                                if isSingleLine elmValue then
                                    htmlRow []
                                        [ htmlEl [ alignTop ] (htmlText (fieldName ++ ": "))
                                        , treeViewDiff msgConfig (depth + 1) nextPath collapsedFields oldElmValue elmValue
                                        ]

                                else if isCollapsed depth elmValue nextPath collapsedFields then
                                    htmlRow []
                                        [ inputButton
                                            [ alignTop ]
                                            { onPress = msgConfig.pressedExpandField nextPath
                                            , label = htmlText (fieldName ++ ": ")
                                            }
                                        , Html.Lazy.lazy2 collapsedValueDiff oldElmValue elmValue
                                        ]

                                else
                                    htmlColumn []
                                        [ inputButton
                                            []
                                            { onPress = msgConfig.pressedCollapseField nextPath
                                            , label = htmlText (fieldName ++ ": ")
                                            }
                                        , htmlEl
                                            [ tabAmount ]
                                            (treeViewDiff msgConfig (depth + 1) nextPath collapsedFields oldElmValue elmValue)
                                        ]
                            )
                            oldRecord
                            record
                        )

                ( ElmDict oldDict, ElmDict dict ) ->
                    if List.isEmpty oldDict && List.isEmpty dict then
                        emptyDict

                    else
                        let
                            oldDict2 : Dict String ( ElmValue, ElmValue )
                            oldDict2 =
                                List.map (\( key, value2 ) -> ( elmValueToKey key, ( key, value2 ) )) oldDict |> Dict.fromList

                            dict2 : Dict String ( ElmValue, ElmValue )
                            dict2 =
                                List.map (\( key, value2 ) -> ( elmValueToKey key, ( key, value2 ) )) dict |> Dict.fromList

                            merge =
                                Dict.merge
                                    (\_ ( key, old ) state ->
                                        htmlColumn
                                            [ oldColor ]
                                            [ dictKey msgConfig depth currentPath collapsedFields key
                                            , htmlEl
                                                [ tabAmount ]
                                                (treeView msgConfig (depth + 1) (DictNode key :: currentPath) collapsedFields old)
                                            ]
                                            :: state
                                    )
                                    (\_ ( key, old ) ( _, new ) state ->
                                        htmlColumn
                                            []
                                            [ dictKey msgConfig depth currentPath collapsedFields key
                                            , htmlEl
                                                [ tabAmount ]
                                                (treeViewDiff
                                                    msgConfig
                                                    (depth + 1)
                                                    (DictNode key :: currentPath)
                                                    collapsedFields
                                                    old
                                                    new
                                                )
                                            ]
                                            :: state
                                    )
                                    (\_ ( key, new ) state ->
                                        htmlColumn
                                            [ newColor ]
                                            [ dictKey msgConfig depth currentPath collapsedFields key
                                            , htmlEl
                                                [ tabAmount ]
                                                (treeView
                                                    msgConfig
                                                    (depth + 1)
                                                    (DictNode key :: currentPath)
                                                    collapsedFields
                                                    new
                                                )
                                            ]
                                            :: state
                                    )
                                    oldDict2
                                    dict2
                                    []
                        in
                        htmlColumn [] merge

                _ ->
                    htmlText "Error, old and new types don't match"

        _ ->
            htmlText "Error, old and new types don't match"


elmValueToKey : ElmValue -> String
elmValueToKey elmValue =
    case elmValue of
        Plain plainValue ->
            case plainValue of
                DebugParser.ElmString string ->
                    "a_" ++ string

                DebugParser.ElmChar char ->
                    "b_" ++ String.fromChar char

                DebugParser.ElmNumber float ->
                    "c_" ++ String.fromFloat float

                DebugParser.ElmBool bool ->
                    "d_"
                        ++ (if bool then
                                "true"

                            else
                                "false"
                           )

                DebugParser.ElmFunction ->
                    "e"

                DebugParser.ElmInternals ->
                    "f"

                DebugParser.ElmUnit ->
                    "g"

                DebugParser.ElmFile string ->
                    "h_" ++ string

                DebugParser.ElmBytes int ->
                    "i_" ++ String.fromInt int

        Expandable expandableValue ->
            case expandableValue of
                ElmSequence sequenceType elmValues ->
                    "j_"
                        ++ (case sequenceType of
                                DebugParser.SeqSet ->
                                    "1"

                                DebugParser.SeqList ->
                                    "2"

                                DebugParser.SeqArray ->
                                    "3"

                                DebugParser.SeqTuple ->
                                    "4"
                           )
                        ++ String.join "_" (List.map elmValueToKey elmValues)

                ElmType string elmValues ->
                    "k_" ++ string ++ String.join "_" (List.map elmValueToKey elmValues)

                ElmRecord list ->
                    "l_" ++ String.join "_" (List.map (\( field, a ) -> field ++ "-" ++ elmValueToKey a) list)

                ElmDict list ->
                    "m_" ++ String.join "_" (List.map (\( key, value ) -> elmValueToKey key ++ "-" ++ elmValueToKey value) list)


isCollapsed : Int -> ElmValue -> List PathNode -> Dict (List String) CollapsedField -> Bool
isCollapsed depth elmValue nextPath collapsedFields =
    case Dict.get (List.map pathNodeToKey nextPath) collapsedFields of
        Just FieldIsCollapsed ->
            True

        Just FieldIsExpanded ->
            False

        Nothing ->
            if depth > 5 then
                True

            else
                case elmValue of
                    Plain _ ->
                        False

                    Expandable value2 ->
                        case value2 of
                            ElmSequence _ list ->
                                List.length list > 5

                            ElmType _ list ->
                                List.length list > 5

                            ElmRecord list ->
                                List.length list > 5

                            ElmDict list ->
                                List.length list > 5


tabAmount : Html.Attribute msg
tabAmount =
    Html.Attributes.style "padding-left" "24px"


treeView : MsgConfig msg -> Int -> List PathNode -> Dict (List String) CollapsedField -> ElmValue -> Html msg
treeView msgConfig depth currentPath collapsedFields value =
    case value of
        Plain plainValue ->
            plainValueToString plainValue

        Expandable expandableValue ->
            case expandableValue of
                DebugParser.ElmSequence sequenceType elmValues ->
                    if List.isEmpty elmValues then
                        let
                            ( startChar, endChar ) =
                                sequenceStartEnd sequenceType
                        in
                        htmlText (startChar ++ endChar)

                    else
                        let
                            ( startChar, endChar ) =
                                sequenceStartEnd sequenceType
                        in
                        htmlColumn
                            []
                            (List.indexedMap
                                (\index new ->
                                    if index == 0 then
                                        htmlRow []
                                            [ htmlEl
                                                [ alignTop ]
                                                (htmlText (String.padRight 2 ' ' startChar))
                                            , treeView
                                                msgConfig
                                                (depth + 1)
                                                (SequenceNode index :: currentPath)
                                                collapsedFields
                                                new
                                            ]

                                    else
                                        htmlRow []
                                            [ htmlEl
                                                [ alignTop ]
                                                (htmlText ", ")
                                            , treeView
                                                msgConfig
                                                (depth + 1)
                                                (SequenceNode index :: currentPath)
                                                collapsedFields
                                                new
                                            ]
                                )
                                elmValues
                                ++ [ htmlText endChar ]
                            )

                DebugParser.ElmType variant elmValues ->
                    case elmValues of
                        [ single ] ->
                            if isSingleLine single then
                                htmlRow []
                                    [ htmlEl [ alignTop ] (variantText variant)
                                    , htmlText " "
                                    , treeView msgConfig (depth + 1) (VariantNode variant :: currentPath) collapsedFields single
                                    ]

                            else
                                htmlColumn
                                    []
                                    [ variantText variant
                                    , htmlColumn
                                        [ tabAmount ]
                                        (List.map
                                            (treeView
                                                msgConfig
                                                (depth + 1)
                                                (VariantNode variant :: currentPath)
                                                collapsedFields
                                            )
                                            elmValues
                                        )
                                    ]

                        _ ->
                            htmlColumn
                                []
                                [ variantText variant
                                , htmlColumn
                                    [ tabAmount ]
                                    (List.map
                                        (treeView
                                            msgConfig
                                            (depth + 1)
                                            (VariantNode variant :: currentPath)
                                            collapsedFields
                                        )
                                        elmValues
                                    )
                                ]

                DebugParser.ElmRecord fields ->
                    htmlColumn
                        []
                        (List.map
                            (\( fieldName, elmValue ) ->
                                let
                                    nextPath : List PathNode
                                    nextPath =
                                        FieldNode fieldName :: currentPath
                                in
                                if isSingleLine elmValue then
                                    htmlRow []
                                        [ htmlEl [ alignTop ] (htmlText (fieldName ++ ": "))
                                        , treeView msgConfig (depth + 1) nextPath collapsedFields elmValue
                                        ]

                                else if isCollapsed depth elmValue nextPath collapsedFields then
                                    htmlRow []
                                        [ inputButton
                                            [ alignTop ]
                                            { onPress = msgConfig.pressedExpandField nextPath
                                            , label = htmlText (fieldName ++ ": ")
                                            }
                                        , collapsedValue elmValue
                                        ]

                                else
                                    htmlColumn []
                                        [ inputButton
                                            []
                                            { onPress = msgConfig.pressedCollapseField nextPath
                                            , label = htmlText (fieldName ++ ": ")
                                            }
                                        , htmlEl
                                            [ tabAmount ]
                                            (treeView msgConfig (depth + 1) nextPath collapsedFields elmValue)
                                        ]
                            )
                            fields
                        )

                DebugParser.ElmDict dict ->
                    if List.isEmpty dict then
                        emptyDict

                    else
                        htmlColumn
                            []
                            (List.map
                                (\( key, value2 ) ->
                                    htmlColumn
                                        []
                                        [ dictKey msgConfig depth currentPath collapsedFields key
                                        , htmlEl
                                            [ tabAmount ]
                                            (treeView msgConfig (depth + 1) (DictNode key :: currentPath) collapsedFields value2)
                                        ]
                                )
                                dict
                            )


dictKey : MsgConfig msg -> Int -> List PathNode -> Dict (List String) CollapsedField -> ElmValue -> Html msg
dictKey msgConfig depth currentPath collapsedFields elmValue =
    let
        row : () -> Html msg
        row () =
            htmlRow [] [ treeView msgConfig (depth + 1) (DictKeyNode elmValue :: currentPath) collapsedFields elmValue, htmlText ": " ]

        column : () -> Html msg
        column () =
            htmlRow
                []
                [ treeView msgConfig (depth + 1) (DictKeyNode elmValue :: currentPath) collapsedFields elmValue
                , Html.text " "
                , htmlEl
                    [ widthEach { left = 2, right = 0, top = 0, bottom = 0 }
                    , heightFill
                    , borderColor (rgb 0.5 0.5 0.5)
                    , fontColor (rgb 0.5 0.5 0.5)
                    ]
                    (htmlEl centerY (htmlText "(key)"))
                ]
    in
    case elmValue of
        Plain _ ->
            row ()

        Expandable expandable ->
            case expandable of
                ElmSequence _ _ ->
                    column ()

                ElmType _ elmValues ->
                    case elmValues of
                        [] ->
                            row ()

                        [ Plain _ ] ->
                            row ()

                        _ ->
                            column ()

                ElmRecord _ ->
                    column ()

                ElmDict _ ->
                    column ()
