module Evergreen.V125.AdminPage exposing (..)

import Evergreen.V125.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId)
    | DeleteMailButton (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton
    | RegenerateGridCellCacheButton


type alias Model =
    { mailPage : Int
    }
