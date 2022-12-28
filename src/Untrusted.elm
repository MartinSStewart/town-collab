module Untrusted exposing
    ( Untrusted(..)
    , Validation(..)
    , emailAddress
    , toString
    , untrust
    )

import EmailAddress exposing (EmailAddress)


{-| We can't be sure a value we got from the frontend hasn't been tampered with.
In cases where an opaque type uses code to give some kind of guarantee (for example
MaxAttendees makes sure the max number of attendees is at least 2) we wrap the value in Unstrusted to
make sure we don't forget to validate the value again on the backend.
-}
type Untrusted a
    = Untrusted a


type Validation a
    = Valid a
    | Invalid


toString : (a -> String) -> Untrusted a -> String
toString toStringFunc (Untrusted a) =
    toStringFunc a


fromResult : Result e a -> Validation a
fromResult result =
    case result of
        Ok ok ->
            Valid ok

        Err _ ->
            Invalid


fromMaybe : Maybe a -> Validation a
fromMaybe maybe =
    case maybe of
        Just value ->
            Valid value

        Nothing ->
            Invalid


untrust : a -> Untrusted a
untrust =
    Untrusted


emailAddress : Untrusted EmailAddress -> Validation EmailAddress
emailAddress (Untrusted a) =
    EmailAddress.toString a |> EmailAddress.fromString |> fromMaybe
