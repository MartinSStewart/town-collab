module Evergreen.V112.Route exposing (..)

import Evergreen.V112.Id


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
    = LoginToken2 (Evergreen.V112.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V112.Id.SecretId InviteToken)
