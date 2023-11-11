module Evergreen.V110.Route exposing (..)

import Evergreen.V110.Id


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
    = LoginToken2 (Evergreen.V110.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V110.Id.SecretId InviteToken)
