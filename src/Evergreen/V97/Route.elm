module Evergreen.V97.Route exposing (..)

import Evergreen.V97.Id


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
    = LoginToken2 (Evergreen.V97.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V97.Id.SecretId InviteToken)
