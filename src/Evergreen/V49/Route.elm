module Evergreen.V49.Route exposing (..)

import Evergreen.V49.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V49.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V49.Id.SecretId InviteToken)
