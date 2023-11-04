module Evergreen.V106.AdminPage exposing (..)

import Evergreen.V106.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId)
    | DeleteMailButton (Evergreen.V106.Id.Id Evergreen.V106.Id.MailId)
    | ResetUpdateDurationButton


type alias Model =
    { mailPage : Int
    }
