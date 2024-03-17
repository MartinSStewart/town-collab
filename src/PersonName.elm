module PersonName exposing
    ( Error(..)
    , PersonName(..)
    , fromString
    , names
    , toString
    )

import List.Nonempty exposing (Nonempty(..))
import String.Nonempty exposing (NonemptyString(..))


type PersonName
    = PersonName NonemptyString


type Error
    = PersonNameTooShort


fromString : String -> Result Error PersonName
fromString text =
    case String.Nonempty.fromString text of
        Just name ->
            PersonName name |> Ok

        Nothing ->
            Err PersonNameTooShort


toString : PersonName -> String
toString (PersonName a) =
    String.Nonempty.toString a


names : Nonempty PersonName
names =
    [ "Sven Svensson"
    , "Alice Alicesson"
    , "James Jamesson"
    , "Zane Umbra"
    ]
        |> List.filterMap (\text -> fromString text |> Result.toMaybe)
        |> List.Nonempty.fromList
        |> Maybe.withDefault (Nonempty (PersonName (NonemptyString 'A' "")) [])
