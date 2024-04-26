module Name exposing
    ( Error(..)
    , Name(..)
    , fromString
    , maxLength
    , sven
    , toString
    )

import String.Nonempty exposing (NonemptyString(..))


type Name
    = Name NonemptyString


type Error
    = NameIsTooShort
    | NameIsTooLong


maxLength : number
maxLength =
    20


minLength : number
minLength =
    2


fromString : String -> Result Error Name
fromString text =
    case String.Nonempty.fromString text of
        Just name ->
            if String.length text > maxLength then
                Err NameIsTooLong

            else if String.length text < minLength then
                Err NameIsTooShort

            else
                Name name |> Ok

        Nothing ->
            Err NameIsTooShort


toString : Name -> String
toString (Name a) =
    String.Nonempty.toString a


sven : Name
sven =
    NonemptyString 'S' "ven Svensson" |> Name
