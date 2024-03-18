module NpcName exposing
    ( Error(..)
    , NpcName(..)
    , fromString
    , names
    , toString
    )

import List.Nonempty exposing (Nonempty(..))
import String.Nonempty exposing (NonemptyString(..))


type NpcName
    = PersonName NonemptyString


type Error
    = PersonNameTooShort


fromString : String -> Result Error NpcName
fromString text =
    case String.Nonempty.fromString text of
        Just name ->
            PersonName name |> Ok

        Nothing ->
            Err PersonNameTooShort


toString : NpcName -> String
toString (PersonName a) =
    String.Nonempty.toString a


names : Nonempty NpcName
names =
    [ "Sven Svensson"
    , "Alice Alicesson"
    , "James Jamesson"
    , "Zane Umbra"
    , "Mr. Smiggles"
    , "Sir Bob"
    , "Dorey Doe"
    ]
        |> List.filterMap (\text -> fromString text |> Result.toMaybe)
        |> List.Nonempty.fromList
        |> Maybe.withDefault (Nonempty (PersonName (NonemptyString 'A' "")) [])
