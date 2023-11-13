module Evergreen.V113.Route exposing (..)

import Evergreen.V113.Id


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
    = LoginToken2 (Evergreen.V113.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V113.Id.SecretId InviteToken)
