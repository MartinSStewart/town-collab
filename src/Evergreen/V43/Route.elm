module Evergreen.V43.Route exposing (..)

import Evergreen.V43.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V43.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V43.Id.SecretId InviteToken)
