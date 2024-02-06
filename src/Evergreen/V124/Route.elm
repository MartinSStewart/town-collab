module Evergreen.V124.Route exposing (..)

import Evergreen.V124.Id


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
    = LoginToken2 (Evergreen.V124.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V124.Id.SecretId InviteToken)
