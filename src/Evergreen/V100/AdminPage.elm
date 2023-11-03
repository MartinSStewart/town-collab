module Evergreen.V100.AdminPage exposing (..)

import Evergreen.V100.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId)
    | DeleteMailButton (Evergreen.V100.Id.Id Evergreen.V100.Id.MailId)
    | ResetUpdateDurationButton


type alias Model =
    { mailPage : Int
    }
