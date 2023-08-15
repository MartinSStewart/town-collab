module Unsafe exposing (emailAddress, url)

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


{-| Be very careful when using this!
-}
unreachable : () -> a
unreachable () =
    unreachable ()
