module Evergreen.V48.Route exposing (..)

import Evergreen.V48.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V48.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V48.Id.SecretId InviteToken)
