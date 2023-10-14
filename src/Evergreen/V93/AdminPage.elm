module Evergreen.V93.AdminPage exposing (..)

import Evergreen.V93.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId)
    | DeleteMailButton (Evergreen.V93.Id.Id Evergreen.V93.Id.MailId)


type alias Model =
    { mailPage : Int
    }
