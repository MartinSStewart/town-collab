module Evergreen.V112.AdminPage exposing (..)

import Evergreen.V112.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId)
    | DeleteMailButton (Evergreen.V112.Id.Id Evergreen.V112.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
