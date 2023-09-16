module Lamdera.Wire exposing (andMapDecode, andThenDecode, decodeArray, decodeBool, decodeBytes, decodeChar, decodeDict, decodeFloat, decodeFloat64, decodeInt, decodeInt64, decodeList, decodeMaybe, decodeNever, decodeOrder, decodePair, decodeResult, decodeSet, decodeString, decodeTriple, decodeUnit, encodeArray, encodeBool, encodeBytes, encodeChar, encodeDict, encodeFloat, encodeFloat64, encodeInt, encodeInt64, encodeList, encodeMaybe, encodeNever, encodeOrder, encodePair, encodeResult, encodeSequence, encodeSequenceWithoutLength, encodeSet, encodeString, encodeTriple, encodeUnit, endianness, failDecode, failEncode, identityFloatToInt, intDivBy, signedToUnsigned, succeedDecode, unsignedToSigned, Decoder, Encoder, bytesEncode, bytesDecode, intListFromBytes, intListToBytes, decodeSequence, decodeEndianness, encodeEndianness)

{-| Lamdera.Wire contains all the built-in codecs used by Wire.

@DEPRECATED use Wire2

@docs andMapDecode, andThenDecode, decodeArray, decodeBool, decodeBytes, decodeChar, decodeDict, decodeFloat, decodeFloat64, decodeInt, decodeInt64, decodeList, decodeMaybe, decodeNever, decodeOrder, decodePair, decodeResult, decodeSet, decodeString, decodeTriple, decodeUnit, encodeArray, encodeBool, encodeBytes, encodeChar, encodeDict, encodeFloat, encodeFloat64, encodeInt, encodeInt64, encodeList, encodeMaybe, encodeNever, encodeOrder, encodePair, encodeResult, encodeSequence, encodeSequenceWithoutLength, encodeSet, encodeString, encodeTriple, encodeUnit, endianness, failDecode, failEncode, identityFloatToInt, intDivBy, signedToUnsigned, succeedDecode, unsignedToSigned, Decoder, Encoder, bytesEncode, bytesDecode, intListFromBytes, intListToBytes, decodeSequence, decodeEndianness, encodeEndianness

-}

import Array exposing (Array)
import Bytes as B
import Bytes.Decode as D exposing (Decoder)
import Bytes.Encode as E exposing (Encoder)
import Dict exposing (Dict)
import Set exposing (Set)


{-| -}
type alias Decoder a =
    D.Decoder a


{-| -}
type alias Encoder =
    E.Encoder


{-| -}
bytesEncode : E.Encoder -> B.Bytes
bytesEncode =
    E.encode


{-| -}
bytesDecode : D.Decoder a -> B.Bytes -> Maybe a
bytesDecode =
    D.decode


{-| -}
andMapDecode : Decoder a -> Decoder (a -> b) -> Decoder b
andMapDecode d d2 =
    D.andThen (\v -> D.map v d) d2


{-| -}
andThenDecode : (a -> Decoder b) -> Decoder a -> Decoder b
andThenDecode =
    D.andThen


{-| -}
endianness : B.Endianness
endianness =
    B.LE


{-| -}
succeedDecode : a -> Decoder a
succeedDecode =
    D.succeed


{-| -}
failDecode : Decoder a
failDecode =
    D.fail


{-| -}
failEncode : a -> Encoder
failEncode a =
    encodeSequenceWithoutLength []


{-| -}
encodeFloat64 : Float -> Encoder
encodeFloat64 f =
    E.float64 endianness f


{-| -}
decodeFloat64 : Decoder Float
decodeFloat64 =
    D.float64 endianness


{-| -}
intDivBy : Int -> Int -> Int
intDivBy b a =
    let
        v =
            toFloat a / toFloat b
    in
    if v < 0 then
        -(floor -v)

    else
        floor v



--
{-
   varint format:
   0-216   1 byte    value = B0
   217-248 2 bytes   value = 216 + 256 * (B0 - 216) + B1
   249-255 3-9 bytes value = (B0 - 249 + 2) little-endian bytes following B0.

   and then:
   Integers are mapped to positive integers, so that positive integers become positive even numbers (2n) and negative integers become positive odd numbers. (-2n-1)
   This is the same as moving the sign bit from the most significant position to the least significant. Otherwise, varint will encode negative numbers as large integers.

   inspiration:
   https://github.com/dominictarr/signed-varint
   IeSQLite4:
   0-184   1 byte    value = B0
   185-248 2 bytes   value = 185 + 256 * (B0 - 185) + B1
   249-255 3-9 bytes value = (B0 - 249 + 2) little-endian bytes following B0.

   NOTE: Elm (js) uses F64 to represent ints, so not all values are available, and since we use the least significant bit for sign bit, large numbers become positive, even larger numbers become even, even larger become multiples of 4, etc.
-}


{-| -}
encodeInt64 : Int -> Encoder
encodeInt64 i =
    let
        n =
            signedToUnsigned i

        n0 =
            modBy 256 n

        n1 =
            modBy 256 (n |> intDivBy 256)

        n2 =
            modBy 256 (n |> intDivBy 256 |> intDivBy 256)

        n3 =
            modBy 256 (n |> intDivBy 256 |> intDivBy 256 |> intDivBy 256)

        ei e =
            E.sequence <| List.map E.unsignedInt8 e
    in
    if n <= 215 then
        ei <| [ n ]

    else if n <= 9431 then
        ei <| [ 216 + ((n - 216) |> intDivBy 256), modBy 256 (n - 216) ]

    else if n < 256 * 256 then
        ei <| [ 252, n1, n0 ]

    else if n < 256 * 256 * 256 then
        ei <| [ 253, n2, n1, n0 ]

    else if n < 256 * 256 * 256 * 256 then
        ei <| [ 254, n3, n2, n1, n0 ]

    else
        E.sequence [ E.unsignedInt8 255, encodeFloat64 (toFloat i) ]


{-| -}
signedToUnsigned : Int -> Int
signedToUnsigned i =
    if i < 0 then
        -2 * i - 1

    else
        2 * i


{-| -}
unsignedToSigned : Int -> Int
unsignedToSigned i =
    if modBy 2 i == 1 then
        (i + 1) |> intDivBy -2

    else
        i |> intDivBy 2


{-| -}
decodeInt64 : Decoder Int
decodeInt64 =
    let
        d =
            andMapDecode D.unsignedInt8
    in
    D.unsignedInt8
        |> D.andThen
            (\n0 ->
                if n0 <= 215 then
                    D.succeed n0 |> D.map unsignedToSigned

                else if n0 < 252 then
                    D.succeed (\b0 -> (n0 - 216) * 256 + b0 + 216) |> d |> D.map unsignedToSigned

                else if n0 == 252 then
                    D.succeed (\b0 b1 -> b0 * 256 + b1) |> d |> d |> D.map unsignedToSigned

                else if n0 == 253 then
                    D.succeed (\b0 b1 b2 -> (b0 * 256 + b1) * 256 + b2) |> d |> d |> d |> D.map unsignedToSigned

                else if n0 == 254 then
                    D.succeed (\b0 b1 b2 b3 -> ((b0 * 256 + b1) * 256 + b2) * 256 + b3) |> d |> d |> d |> d |> D.map unsignedToSigned

                else
                    decodeFloat64 |> D.map identityFloatToInt
            )


{-| `floor` is one of few functions that turn integer floats in js into typed integers in Elm, e.g. the Float `3` into the Int `3`.
-}
identityFloatToInt : Float -> Int
identityFloatToInt =
    floor


{-| -}
encodeString : String -> Encoder
encodeString s =
    E.sequence
        [ encodeInt64 (E.getStringWidth s)
        , E.string s
        ]


{-| -}
decodeString : Decoder String
decodeString =
    decodeInt64
        |> D.andThen D.string


{-| -}
encodeList : (a -> Encoder) -> List a -> Encoder
encodeList enc s =
    E.sequence
        (encodeInt64 (List.length s)
            :: List.map enc s
        )


{-| -}
decodeList : Decoder a -> Decoder (List a)
decodeList decoder =
    let
        listStep : ( Int, List a ) -> Decoder (D.Step ( Int, List a ) (List a))
        listStep ( n, xs ) =
            if n <= 0 then
                D.succeed (D.Done xs)

            else
                D.map (\x -> D.Loop ( n - 1, x :: xs )) decoder
    in
    decodeInt64
        |> D.andThen (\len -> D.loop ( len, [] ) listStep |> D.map List.reverse)


{-| -}
encodeSequence : List Encoder -> Encoder
encodeSequence s =
    E.sequence (encodeInt64 (List.length s) :: s)


{-| -}
encodeSequenceWithoutLength : List Encoder -> Encoder
encodeSequenceWithoutLength s =
    E.sequence s


{-| -}
encodeChar : Char -> Encoder
encodeChar c =
    Char.toCode c
        |> encodeInt64


{-| -}
decodeChar : Decoder Char
decodeChar =
    decodeInt64 |> D.map Char.fromCode


{-| -}
encodeUnit : () -> Encoder
encodeUnit () =
    E.sequence []


{-| -}
decodeUnit : Decoder ()
decodeUnit =
    D.succeed ()


{-| -}
encodePair : (a -> Encoder) -> (b -> Encoder) -> ( a, b ) -> Encoder
encodePair c_a c_b ( a, b ) =
    E.sequence [ c_a a, c_b b ]


{-| -}
decodePair : Decoder a -> Decoder b -> Decoder ( a, b )
decodePair c_a c_b =
    D.succeed (\a b -> ( a, b ))
        |> andMapDecode c_a
        |> andMapDecode c_b


{-| -}
encodeTriple : (a -> Encoder) -> (b -> Encoder) -> (c -> Encoder) -> ( a, b, c ) -> Encoder
encodeTriple c_a c_b c_c ( a, b, c ) =
    E.sequence [ c_a a, c_b b, c_c c ]


{-| -}
decodeTriple : Decoder a -> Decoder b -> Decoder c -> Decoder ( a, b, c )
decodeTriple c_a c_b c_c =
    D.succeed (\a b c -> ( a, b, c ))
        |> andMapDecode c_a
        |> andMapDecode c_b
        |> andMapDecode c_c


{-| -}
encodeArray : (a -> Encoder) -> Array a -> Encoder
encodeArray enc a =
    encodeList enc (Array.toList a)


{-| -}
decodeArray : Decoder a -> Decoder (Array a)
decodeArray a =
    decodeList a |> D.map Array.fromList


{-| -}
encodeBool : Bool -> Encoder
encodeBool b =
    encodeString <|
        case b of
            True ->
                "True"

            False ->
                "False"


{-| -}
decodeBool : Decoder Bool
decodeBool =
    decodeString
        |> D.andThen
            (\s ->
                case s of
                    "True" ->
                        D.succeed True

                    "False" ->
                        D.succeed False

                    _ ->
                        D.fail
            )


{-| -}
encodeInt : Int -> Encoder
encodeInt =
    encodeInt64


{-| -}
decodeInt : Decoder Int
decodeInt =
    decodeInt64


{-| -}
encodeFloat : Float -> Encoder
encodeFloat =
    encodeFloat64


{-| -}
decodeFloat : Decoder Float
decodeFloat =
    decodeFloat64


{-| -}
encodeOrder : Order -> Encoder
encodeOrder order =
    case order of
        LT ->
            encodeInt 0

        EQ ->
            encodeInt 1

        GT ->
            encodeInt 2


{-| -}
decodeOrder : Decoder Order
decodeOrder =
    decodeInt
        |> D.andThen
            (\c ->
                case c of
                    0 ->
                        succeedDecode LT

                    1 ->
                        succeedDecode EQ

                    2 ->
                        succeedDecode GT

                    _ ->
                        failDecode
            )


{-| -}
decodeNever : Decoder Never
decodeNever =
    failDecode


{-| -}
encodeNever : Never -> Encoder
encodeNever =
    failEncode


{-| -}
encodeDict : (key -> Encoder) -> (value -> Encoder) -> Dict key value -> Encoder
encodeDict encKey encValue d =
    encodeList (encodePair encKey encValue) (Dict.toList d)


{-| -}
decodeDict : Decoder comparable -> Decoder value -> Decoder (Dict comparable value)
decodeDict decKey decValue =
    decodeList (decodePair decKey decValue) |> D.map Dict.fromList


{-| -}
encodeSet : (value -> Encoder) -> Set value -> Encoder
encodeSet encVal s =
    encodeList encVal (Set.toList s)


{-| -}
decodeSet : Decoder comparable -> Decoder (Set comparable)
decodeSet decVal =
    decodeList decVal |> D.map Set.fromList


{-| -}
encodeMaybe : (a -> Encoder) -> Maybe a -> Encoder
encodeMaybe encVal s =
    case s of
        Nothing ->
            encodeSequenceWithoutLength [ encodeInt 0 ]

        Just v ->
            encodeSequenceWithoutLength [ encodeInt 1, encVal v ]


{-| -}
decodeMaybe : Decoder a -> Decoder (Maybe a)
decodeMaybe decVal =
    decodeInt
        |> D.andThen
            (\c ->
                case c of
                    0 ->
                        succeedDecode Nothing

                    1 ->
                        decVal |> D.map Just

                    _ ->
                        failDecode
            )


{-| -}
encodeResult : (err -> Encoder) -> (val -> Encoder) -> Result err val -> Encoder
encodeResult encErr encVal s =
    case s of
        Ok v ->
            encodeSequenceWithoutLength [ encodeInt 0, encVal v ]

        Err v ->
            encodeSequenceWithoutLength [ encodeInt 1, encErr v ]


{-| -}
decodeResult : Decoder err -> Decoder val -> Decoder (Result err val)
decodeResult decErr decVal =
    decodeInt
        |> D.andThen
            (\c ->
                case c of
                    0 ->
                        decVal |> D.map Ok

                    1 ->
                        decErr |> D.map Err

                    _ ->
                        failDecode
            )


{-| -}
encodeBytes : B.Bytes -> Encoder
encodeBytes b =
    E.sequence [ encodeInt (B.width b), E.bytes b ]


{-| -}
decodeBytes : Decoder B.Bytes
decodeBytes =
    decodeInt |> D.andThen D.bytes


{-| -}
encodeEndianness : B.Endianness -> Encoder
encodeEndianness order =
    case order of
        B.LE ->
            E.unsignedInt8 0

        B.BE ->
            E.unsignedInt8 1


{-| -}
decodeEndianness : Decoder B.Endianness
decodeEndianness =
    D.unsignedInt8
        |> D.andThen
            (\c ->
                case c of
                    0 ->
                        succeedDecode B.LE

                    1 ->
                        succeedDecode B.BE

                    _ ->
                        failDecode
            )


{-| -}
intListFromBytes : B.Bytes -> List Int
intListFromBytes bytes =
    D.decode (decodeSequence (B.width bytes) D.unsignedInt8) bytes |> Maybe.withDefault [ 0, 0, 0, 0, 0 ]


{-| -}
intListToBytes : List Int -> B.Bytes
intListToBytes s =
    E.encode (E.sequence (List.map E.unsignedInt8 s))


{-| -}
decodeSequence : Int -> D.Decoder a -> D.Decoder (List a)
decodeSequence len decoder =
    let
        listStep : ( Int, List a ) -> D.Decoder (D.Step ( Int, List a ) (List a))
        listStep ( n, xs ) =
            if n <= 0 then
                D.succeed (D.Done xs)

            else
                D.map (\x -> D.Loop ( n - 1, x :: xs )) decoder
    in
    D.loop ( len, [] ) listStep |> D.map List.reverse
