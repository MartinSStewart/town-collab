module Evergreen.V115.AdminPage exposing (..)

import Evergreen.V115.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId)
    | DeleteMailButton (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
