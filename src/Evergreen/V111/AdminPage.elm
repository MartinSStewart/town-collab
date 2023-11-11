module Evergreen.V111.AdminPage exposing (..)

import Evergreen.V111.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId)
    | DeleteMailButton (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
