module Evergreen.V115.Route exposing (..)

import Evergreen.V115.Id


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
    = LoginToken2 (Evergreen.V115.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V115.Id.SecretId InviteToken)
