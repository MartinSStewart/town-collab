module Evergreen.V111.Route exposing (..)

import Evergreen.V111.Id


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
    = LoginToken2 (Evergreen.V111.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V111.Id.SecretId InviteToken)
