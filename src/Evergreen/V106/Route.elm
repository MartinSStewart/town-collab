module Evergreen.V106.Route exposing (..)

import Evergreen.V106.Id


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
    = LoginToken2 (Evergreen.V106.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V106.Id.SecretId InviteToken)
