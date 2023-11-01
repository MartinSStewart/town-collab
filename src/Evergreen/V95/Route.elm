module Evergreen.V95.Route exposing (..)

import Evergreen.V95.Id


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
    = LoginToken2 (Evergreen.V95.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V95.Id.SecretId InviteToken)
