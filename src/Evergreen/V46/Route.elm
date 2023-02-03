module Evergreen.V46.Route exposing (..)

import Evergreen.V46.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V46.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V46.Id.SecretId InviteToken)
