module Evergreen.V113.AdminPage exposing (..)

import Evergreen.V113.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId)
    | DeleteMailButton (Evergreen.V113.Id.Id Evergreen.V113.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
