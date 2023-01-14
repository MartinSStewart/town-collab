module DisplayName exposing (DisplayName(..), Error(..), default, fromString, maxLength, minLength, toNonemptyString, toString)

import String.Nonempty exposing (NonemptyString(..))


type DisplayName
    = DisplayName NonemptyString


type Error
    = DisplayNameTooShort
    | DisplayNameTooLong


minLength : number
minLength =
    4


maxLength : number
maxLength =
    12


fromString : String -> Result Error DisplayName
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
                Ok (DisplayName nonempty)

            Nothing ->
                Err DisplayNameTooShort


toString : DisplayName -> String
toString (DisplayName groupName) =
    String.Nonempty.toString groupName


toNonemptyString : DisplayName -> NonemptyString
toNonemptyString (DisplayName groupName) =
    groupName


default : DisplayName
default =
    DisplayName (NonemptyString 'U' "nnamed")
