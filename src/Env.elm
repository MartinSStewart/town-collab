module Env exposing (..)

-- The Env.elm file is for per-environment configuration.
-- See https://dashboard.lamdera.app/docs/environment for more info.

import EmailAddress exposing (EmailAddress)
import Id exposing (Id, UserId)
import SendGrid


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


adminEmail_ : String
adminEmail_ =
    ""


adminEmail : Maybe EmailAddress
adminEmail =
    EmailAddress.fromString adminEmail_


sendGridKey_ : String
sendGridKey_ =
    ""


sendGridKey : SendGrid.ApiKey
sendGridKey =
    SendGrid.apiKey sendGridKey_


domain : String
domain =
    "localhost:8000"


notifyAdminWaitInHours : String
notifyAdminWaitInHours =
    "0.05"


confirmationEmailKey : String
confirmationEmailKey =
    "abc"
