module Evergreen.V83.Route exposing (..)

import Evergreen.V83.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V83.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V83.Id.SecretId InviteToken)
