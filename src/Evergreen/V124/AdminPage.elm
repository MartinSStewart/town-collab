module Evergreen.V124.AdminPage exposing (..)

import Evergreen.V124.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId)
    | DeleteMailButton (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
