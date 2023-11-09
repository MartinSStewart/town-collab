module Evergreen.V109.AdminPage exposing (..)

import Evergreen.V109.Id


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int
    | RestoreMailButton (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId)
    | DeleteMailButton (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId)
    | ResetUpdateDurationButton
    | ResetTileCountButton


type alias Model =
    { mailPage : Int
    }
