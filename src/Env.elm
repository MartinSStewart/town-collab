module Env exposing (..)

-- The Env.elm file is for per-environment configuration.
-- See https://dashboard.lamdera.app/docs/environment for more info.

import EmailAddress exposing (EmailAddress)
import Id exposing (Id, UserId)
import Postmark


adminUserId_ : String
adminUserId_ =
    "0"


adminUserId : Maybe (Id UserId)
adminUserId =
    String.toInt adminUserId_ |> Maybe.map Id.fromInt


isProduction2 : String
isProduction2 =
    "False"


isProduction : Bool
isProduction =
    case String.toLower isProduction2 |> String.trim of
        "true" ->
            True

        "false" ->
            False

        _ ->
            False


adminEmail2 : String
adminEmail2 =
    "a@a.se"


adminEmail : Maybe EmailAddress
adminEmail =
    EmailAddress.fromString adminEmail2


postmarkApiKey_ : String
postmarkApiKey_ =
    ""


postmarkApiKey =
    Postmark.apiKey postmarkApiKey_


domain : String
domain =
    "http://localhost:8000"


secretKey : String
secretKey =
    "abc"
