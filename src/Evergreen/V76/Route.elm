module Evergreen.V76.Route exposing (..)

import Evergreen.V76.Id


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V76.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V76.Id.SecretId InviteToken)
