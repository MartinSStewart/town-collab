module Evergreen.V116.Route exposing (..)

import Evergreen.V116.Id


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
    = LoginToken2 (Evergreen.V116.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V116.Id.SecretId InviteToken)
