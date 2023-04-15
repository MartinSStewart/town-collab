module Evergreen.V75.Route exposing (..)

import Evergreen.V75.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V75.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V75.Id.SecretId InviteToken)
