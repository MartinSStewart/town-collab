module Evergreen.V42.Route exposing (..)

import Evergreen.V42.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V42.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V42.Id.SecretId InviteToken)
