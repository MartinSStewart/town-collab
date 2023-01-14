module Evergreen.V45.Route exposing (..)

import Evergreen.V45.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V45.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V45.Id.SecretId InviteToken)
