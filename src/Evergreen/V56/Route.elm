module Evergreen.V56.Route exposing (..)

import Evergreen.V56.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V56.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V56.Id.SecretId InviteToken)
