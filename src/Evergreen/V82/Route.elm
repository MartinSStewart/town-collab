module Evergreen.V82.Route exposing (..)

import Evergreen.V82.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V82.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V82.Id.SecretId InviteToken)
