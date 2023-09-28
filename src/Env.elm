module Env exposing (adminEmail, adminEmail2, adminUserId, domain, isProduction, postmarkApiKey, secretKey)

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


isProduction_ : String
isProduction_ =
    "False"


isProduction : Bool
isProduction =
    case String.toLower isProduction_ |> String.trim of
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
    domain2


domain2 : String
domain2 =
    "http://localhost:8000"


secretKey : String
secretKey =
    "abc"
