module Evergreen.V126.Route exposing (..)

import Evergreen.V126.Id


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
    = LoginToken2 (Evergreen.V126.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V126.Id.SecretId InviteToken)
