module Evergreen.V81.Route exposing (..)

import Evergreen.V81.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V81.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V81.Id.SecretId InviteToken)
