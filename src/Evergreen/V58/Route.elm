module Evergreen.V58.Route exposing (..)

import Evergreen.V58.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V58.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V58.Id.SecretId InviteToken)
