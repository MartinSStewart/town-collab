module Evergreen.V134.AdminPage exposing (..)

import Evergreen.V134.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId)
    | DeleteMailButton (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
