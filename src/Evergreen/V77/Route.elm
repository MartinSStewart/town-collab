module Evergreen.V77.Route exposing (..)

import Evergreen.V77.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V77.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V77.Id.SecretId InviteToken)
