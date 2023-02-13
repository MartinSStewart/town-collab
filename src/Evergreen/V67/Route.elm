module Evergreen.V67.Route exposing (..)

import Evergreen.V67.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V67.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V67.Id.SecretId InviteToken)
