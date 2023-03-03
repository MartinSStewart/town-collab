module Evergreen.V74.Route exposing (..)

import Evergreen.V74.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V74.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V74.Id.SecretId InviteToken)
