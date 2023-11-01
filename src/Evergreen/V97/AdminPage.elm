module Evergreen.V97.AdminPage exposing (..)

import Evergreen.V97.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId)
    | DeleteMailButton (Evergreen.V97.Id.Id Evergreen.V97.Id.MailId)


type alias Model =
    { mailPage : Int
    }
