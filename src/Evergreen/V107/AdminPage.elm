module Evergreen.V107.AdminPage exposing (..)

import Evergreen.V107.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId)
    | DeleteMailButton (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId)
    | ResetUpdateDurationButton


type alias Model =
    { mailPage : Int
    }
