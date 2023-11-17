module Evergreen.V116.AdminPage exposing (..)

import Evergreen.V116.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId)
    | DeleteMailButton (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
