module Evergreen.V108.AdminPage exposing (..)

import Evergreen.V108.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId)
    | DeleteMailButton (Evergreen.V108.Id.Id Evergreen.V108.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton


type alias Model =
    { mailPage : Int
    }
