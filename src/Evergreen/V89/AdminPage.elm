module Evergreen.V89.AdminPage exposing (..)

import Evergreen.V89.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId)
    | DeleteMailButton (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId)


type alias Model =
    { mailPage : Int
    }
