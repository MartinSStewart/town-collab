module Evergreen.V52.Route exposing (..)

import Evergreen.V52.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V52.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V52.Id.SecretId InviteToken)
