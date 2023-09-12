module Evergreen.V84.Route exposing (..)

import Evergreen.V84.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V84.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V84.Id.SecretId InviteToken)
