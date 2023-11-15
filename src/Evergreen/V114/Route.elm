module Evergreen.V114.Route exposing (..)

import Evergreen.V114.Id


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
    = LoginToken2 (Evergreen.V114.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V114.Id.SecretId InviteToken)
