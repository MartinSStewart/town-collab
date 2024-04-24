module NpcName exposing
    ( Error(..)
    , NpcName(..)
    , fromString
    , sven
    , toString
    )

import String.Nonempty exposing (NonemptyString(..))


type NpcName
    = NpcName NonemptyString


type Error
    = NameIsTooShort
    | NameIsTooLong


fromString : String -> Result Error NpcName
fromString text =
    case String.Nonempty.fromString text of
        Just name ->
            if String.length text > 20 then
                Err NameIsTooLong

            else
                NpcName name |> Ok

        Nothing ->
            Err NameIsTooShort


toString : NpcName -> String
toString (NpcName a) =
    String.Nonempty.toString a


sven : NpcName
sven =
    NonemptyString 'S' "ven Svensson" |> NpcName
