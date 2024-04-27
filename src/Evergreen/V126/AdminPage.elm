module Evergreen.V126.AdminPage exposing (..)

import Evergreen.V126.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId)
    | DeleteMailButton (Evergreen.V126.Id.Id Evergreen.V126.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
