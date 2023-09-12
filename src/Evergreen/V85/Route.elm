module Evergreen.V85.Route exposing (..)

import Evergreen.V85.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V85.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V85.Id.SecretId InviteToken)
