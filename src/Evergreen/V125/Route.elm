module Evergreen.V125.Route exposing (..)

import Evergreen.V125.Id


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
    = LoginToken2 (Evergreen.V125.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V125.Id.SecretId InviteToken)
