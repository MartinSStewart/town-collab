module Evergreen.V60.Route exposing (..)

import Evergreen.V60.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V60.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V60.Id.SecretId InviteToken)
