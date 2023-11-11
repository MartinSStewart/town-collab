module PersonName exposing
    ( Error(..)
    , PersonName(..)
    )

import String.Nonempty exposing (NonemptyString)


type PersonName
    = PersonName NonemptyString


type Error
    = DisplayNameTooShort
