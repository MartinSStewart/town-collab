module Evergreen.V88.AdminPage exposing (..)


type Hover
    = ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ResetConnectionsButton
    | CloseAdminPage
    | AdminMailPageButton Int


type alias Model =
    { mailPage : Int
    }
