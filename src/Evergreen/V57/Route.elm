module Evergreen.V57.Route exposing (..)

import Evergreen.V57.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V57.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V57.Id.SecretId InviteToken)
