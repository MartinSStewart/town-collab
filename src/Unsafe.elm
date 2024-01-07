module Unsafe exposing (displayName, emailAddress, unwrapResult, url)

import DisplayName exposing (DisplayName)
import EmailAddress exposing (EmailAddress)
import Url exposing (Url)


{-| Be very careful when using this!
-}
url : String -> Url
url urlText =
    case Url.fromString urlText of
        Just url_ ->
            url_

        Nothing ->
            unreachable ()


{-| Be very careful when using this!
-}
emailAddress : String -> EmailAddress
emailAddress text =
    case EmailAddress.fromString text of
        Just emailAddress_ ->
            emailAddress_

        Nothing ->
            unreachable ()


displayName : String -> DisplayName
displayName text =
    case DisplayName.fromString text of
        Ok value ->
            value

        Err _ ->
            unreachable ()


unwrapResult : Result e a -> a
unwrapResult result =
    case result of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


{-| Be very careful when using this!
-}
unreachable : () -> a
unreachable () =
    let
        _ =
            stackOverflow 0
    in
    unreachable ()


stackOverflow : Int -> Int
stackOverflow a =
    stackOverflow a + 1
