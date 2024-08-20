module Evergreen.V134.Route exposing (..)

import Evergreen.V134.Id


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
    = LoginToken2 (Evergreen.V134.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V134.Id.SecretId InviteToken)
