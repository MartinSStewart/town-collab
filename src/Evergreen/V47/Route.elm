module Evergreen.V47.Route exposing (..)

import Evergreen.V47.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V47.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V47.Id.SecretId InviteToken)
