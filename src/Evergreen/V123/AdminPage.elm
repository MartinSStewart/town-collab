module Evergreen.V123.AdminPage exposing (..)

import Evergreen.V123.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId)
    | DeleteMailButton (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
