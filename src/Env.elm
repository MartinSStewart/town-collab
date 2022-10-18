module Env exposing (Mode(..), adminEmail, adminEmail_, adminUserId, adminUserId_, confirmationEmailKey, domain, hyperlinkWhitelist, isProduction, isProduction_, mode, notifyAdminWaitInHours, sendGridKey, sendGridKey_, startPointAt, startPointX, startPointY)

-- The Env.elm file is for per-environment configuration.
-- See https://dashboard.lamdera.app/docs/environment for more info.

import Bounds exposing (Bounds)
import Coord exposing (Coord)
import EmailAddress exposing (EmailAddress)
import SendGrid
import Units exposing (AsciiUnit)
import User exposing (UserId)


adminUserId_ : String
adminUserId_ =
    "0"


adminUserId : Maybe UserId
adminUserId =
    String.toInt adminUserId_ |> Maybe.map User.userId


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


hyperlinkWhitelist : String
hyperlinkWhitelist =
    "www.patorjk.com/software/taag, ro-box.netlify.app, the-best-color.lamdera.app, agirg.com, yourworldoftext.com, www.yourworldoftext.com, meetdown.app, ellie-app.com"


confirmationEmailKey : String
confirmationEmailKey =
    "abc"


startPointX : String
startPointX =
    "0"


startPointY : String
startPointY =
    "0"


startPointAt : Coord AsciiUnit
startPointAt =
    Maybe.map2
        (\x y -> Coord.fromRawCoord ( x, y ))
        (String.toInt startPointX)
        (String.toInt startPointY)
        |> Maybe.withDefault (Coord.fromRawCoord ( 0, 0 ))
