module Evergreen.V100.Route exposing (..)

import Evergreen.V100.Id


type PageRoute
    = WorldRoute
    | MailEditorRoute
    | AdminRoute
    | InviteTreeRoute


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (Evergreen.V100.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V100.Id.SecretId InviteToken)
