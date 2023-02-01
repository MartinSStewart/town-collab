module Evergreen.V54.Route exposing (..)

import Evergreen.V54.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V54.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V54.Id.SecretId InviteToken)
