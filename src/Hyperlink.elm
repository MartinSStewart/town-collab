module Hyperlink exposing
    ( Hyperlink(..)
    , decoder
    , encoder
    , exampleCom
    , fromString
    , maxLength
    , toString
    , toUrl
    )

import Bytes.Decode
import Bytes.Encode
import StringExtra


type Hyperlink
    = Hyperlink String


maxLength : number
maxLength =
    255


fromString : String -> Hyperlink
fromString text =
    String.trim text
        |> StringExtra.dropPrefix "https://"
        |> StringExtra.dropPrefix "http://"
        |> String.left maxLength
        |> Hyperlink


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
    hyperlink


toUrl : Hyperlink -> String
toUrl (Hyperlink hyperlink) =
    "https://" ++ hyperlink


exampleCom : Hyperlink
exampleCom =
    Hyperlink "example.com"
