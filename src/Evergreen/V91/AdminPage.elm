module Evergreen.V91.AdminPage exposing (..)

import Evergreen.V91.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId)
    | DeleteMailButton (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId)


type alias Model =
    { mailPage : Int
    }
