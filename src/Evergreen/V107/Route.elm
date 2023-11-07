module Evergreen.V107.Route exposing (..)

import Evergreen.V107.Id


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
    = LoginToken2 (Evergreen.V107.Id.SecretId LoginToken)
    | InviteToken2 (Evergreen.V107.Id.SecretId InviteToken)
