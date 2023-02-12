module Evergreen.V62.Route exposing (..)

import Evergreen.V62.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V62.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V62.Id.SecretId InviteToken)
