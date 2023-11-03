module Evergreen.V99.AdminPage exposing (..)

import Evergreen.V99.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId)
    | DeleteMailButton (Evergreen.V99.Id.Id Evergreen.V99.Id.MailId)


type alias Model =
    { mailPage : Int
    }
