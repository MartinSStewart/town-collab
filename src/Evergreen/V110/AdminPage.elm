module Evergreen.V110.AdminPage exposing (..)

import Evergreen.V110.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId)
    | DeleteMailButton (Evergreen.V110.Id.Id Evergreen.V110.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton


type alias Model =
    { mailPage : Int
    }
