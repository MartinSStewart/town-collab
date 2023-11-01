module Evergreen.V95.AdminPage exposing (..)

import Evergreen.V95.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId)
    | DeleteMailButton (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId)


type alias Model =
    { mailPage : Int
    }
