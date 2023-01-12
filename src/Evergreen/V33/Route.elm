module Evergreen.V33.Route exposing (..)

import Evergreen.V33.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V33.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V33.Id.SecretId InviteToken)
