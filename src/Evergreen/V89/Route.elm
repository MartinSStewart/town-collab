module Evergreen.V89.Route exposing (..)

import Evergreen.V89.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V89.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V89.Id.SecretId InviteToken)
