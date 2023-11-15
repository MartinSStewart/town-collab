module Evergreen.V114.AdminPage exposing (..)

import Evergreen.V114.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId)
    | DeleteMailButton (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
