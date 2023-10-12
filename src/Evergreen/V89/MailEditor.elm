module Evergreen.V89.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V89.Animal
import Evergreen.V89.Color
import Evergreen.V89.Coord
import Evergreen.V89.DisplayName
import Evergreen.V89.Id
import Evergreen.V89.Shaders
import Evergreen.V89.Tile
import Pixels


type Image
    = Stamp Evergreen.V89.Color.Colors
    | SunglassesEmoji Evergreen.V89.Color.Colors
    | NormalEmoji Evergreen.V89.Color.Colors
    | SadEmoji Evergreen.V89.Color.Colors
    | Man Evergreen.V89.Color.Colors
    | TileImage Evergreen.V89.Tile.TileGroup Int Evergreen.V89.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V89.Color.Colors
    | DragCursor Evergreen.V89.Color.Colors
    | PinchCursor Evergreen.V89.Color.Colors
    | Line Int Evergreen.V89.Color.Color
    | Animal Evergreen.V89.Animal.AnimalType Evergreen.V89.Color.Colors


type Content
    = ImageType (Evergreen.V89.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V89.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }
    | MailDeletedByAdmin
        { previousStatus : MailStatus2
        , deletedAt : Effect.Time.Posix
        }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , to : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , to : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId)
    | TextToolButton
    | ExportButton
    | ImportButton
    | CloseMailViewButton


type alias ImagePlacer_ =
    { imageIndex : Int
    , rotationIndex : Int
    }


type TextUnit
    = TextUnit Never


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool
    | TextTool (Evergreen.V89.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V89.Id.Id Evergreen.V89.Id.UserId, Evergreen.V89.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V89.Id.Id Evergreen.V89.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }