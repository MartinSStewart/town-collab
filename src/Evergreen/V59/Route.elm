module Evergreen.V59.Route exposing (..)

import Evergreen.V59.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V59.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V59.Id.SecretId InviteToken)
