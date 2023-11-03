module Evergreen.V99.Route exposing (..)

import Evergreen.V99.Id


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
    = LoginToken2 (Evergreen.V99.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V99.Id.SecretId InviteToken)
