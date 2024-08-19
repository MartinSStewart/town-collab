module DisplayName exposing
    ( DisplayName(..)
    , Error(..)
    , default
    , fromString
    , nameAndId
    , nameAndId2
    , toString
    )

import Id exposing (Id, UserId)
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString(..))


type DisplayName
    = DisplayName NonemptyString


type Error
    = DisplayNameTooShort
    | DisplayNameTooLong


minLength : number
minLength =
    2


maxLength : number
maxLength =
    10


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


default : DisplayName
default =
    DisplayName (NonemptyString 'U' "nnamed")


nameAndId : DisplayName -> Id UserId -> String
nameAndId name userId =
    toString name ++ "#" ++ String.fromInt (Id.toInt userId)


nameAndId2 : Id UserId -> SeqDict (Id UserId) { a | name : DisplayName } -> String
nameAndId2 userId users =
    case SeqDict.get userId users of
        Just user ->
            nameAndId user.name userId

        Nothing ->
            "Not found"
