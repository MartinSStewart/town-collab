module Evergreen.V69.Route exposing (..)

import Evergreen.V69.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V69.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V69.Id.SecretId InviteToken)
