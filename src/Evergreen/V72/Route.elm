module Evergreen.V72.Route exposing (..)

import Evergreen.V72.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V72.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V72.Id.SecretId InviteToken)
