module Hyperlink exposing
    ( Hyperlink(..)
    , decoder
    , encoder
    , exampleCom
    , fromString
    , maxLength
    , toString
    )

import Bytes.Decode
import Bytes.Encode
import Parser exposing ((|.), (|=), Parser)
import StringExtra


type Hyperlink
    = Hyperlink String


maxLength : number
maxLength =
    255


fromString : String -> Result String Hyperlink
fromString text =
    let
        text2 : String
        text2 =
            String.trim text
                |> StringExtra.dropPrefix "https://"
                |> StringExtra.dropPrefix "http://"
    in
    if String.length text2 > maxLength then
        Err "Link is too long"

    else
        case Parser.run hyperlinkParser text2 of
            Ok _ ->
                Ok (Hyperlink text2)

            Err _ ->
                Err "Invalid link"


hyperlinkParser : Parser ()
hyperlinkParser =
    Parser.succeed ()
        |. Parser.chompUntil "."


encoder : Hyperlink -> Bytes.Encode.Encoder
encoder (Hyperlink text) =
    Bytes.Encode.sequence
        [ Bytes.Encode.unsignedInt8 (Bytes.Encode.getStringWidth text)
        , Bytes.Encode.string text
        ]


decoder : Bytes.Decode.Decoder Hyperlink
decoder =
    Bytes.Decode.andThen Bytes.Decode.string Bytes.Decode.unsignedInt8 |> Bytes.Decode.map Hyperlink


toString : Hyperlink -> String
toString (Hyperlink hyperlink) =
    "https://" ++ hyperlink


exampleCom : Hyperlink
exampleCom =
    Hyperlink "example.com"
