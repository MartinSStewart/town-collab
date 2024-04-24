module Name exposing
    ( Error(..)
    , Name(..)
    , fromString
    , sven
    , toString
    )

import String.Nonempty exposing (NonemptyString(..))


type Name
    = Name NonemptyString


type Error
    = NameIsTooShort
    | NameIsTooLong


fromString : String -> Result Error Name
fromString text =
    case String.Nonempty.fromString text of
        Just name ->
            if String.length text > 20 then
                Err NameIsTooLong

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
