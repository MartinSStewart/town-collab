module Evergreen.V44.Route exposing (..)

import Evergreen.V44.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V44.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V44.Id.SecretId InviteToken)
