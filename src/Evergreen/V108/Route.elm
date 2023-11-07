module Evergreen.V108.Route exposing (..)

import Evergreen.V108.Id


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
    = LoginToken2 (Evergreen.V108.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V108.Id.SecretId InviteToken)
