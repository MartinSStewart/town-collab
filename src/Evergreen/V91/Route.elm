module Evergreen.V91.Route exposing (..)

import Evergreen.V91.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V91.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V91.Id.SecretId InviteToken)
