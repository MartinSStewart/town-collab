module Evergreen.V50.Route exposing (..)

import Evergreen.V50.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V50.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V50.Id.SecretId InviteToken)
