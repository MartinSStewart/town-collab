module Evergreen.V123.Route exposing (..)

import Evergreen.V123.Id


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
    = LoginToken2 (Evergreen.V123.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V123.Id.SecretId InviteToken)
