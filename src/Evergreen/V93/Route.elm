module Evergreen.V93.Route exposing (..)

import Evergreen.V93.Id


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
    = LoginToken2 (Evergreen.V93.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V93.Id.SecretId InviteToken)
