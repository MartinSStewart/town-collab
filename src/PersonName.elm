module PersonName exposing
    ( Error(..)
    , PersonName(..)
    , fromString
    , maxLength
    , minLength
    , toString
    )

import String.Nonempty exposing (NonemptyString(..))


type PersonName
    = PersonName NonemptyString


type Error
    = DisplayNameTooShort
    | DisplayNameTooLong


minLength : number
minLength =
    2


maxLength : number
maxLength =
    16


fromString : String -> Result Error PersonName
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed < minLength then
        Err DisplayNameTooShort

    else if String.length trimmed > maxLength then
        Err DisplayNameTooLong

    else
        case String.Nonempty.fromString trimmed of
            Just nonempty ->
                Ok (PersonName nonempty)

            Nothing ->
                Err DisplayNameTooShort


toString : PersonName -> String
toString (PersonName groupName) =
    String.Nonempty.toString groupName
