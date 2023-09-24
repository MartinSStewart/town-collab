module Evergreen.V88.Route exposing (..)

import Evergreen.V88.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V88.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V88.Id.SecretId InviteToken)
