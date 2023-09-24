module Evergreen.V88.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V88.Animal
import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.DisplayName
import Evergreen.V88.Id
import Evergreen.V88.Shaders
import Evergreen.V88.Tile
import Pixels


type Image
    = Stamp Evergreen.V88.Color.Colors
    | SunglassesEmoji Evergreen.V88.Color.Colors
    | NormalEmoji Evergreen.V88.Color.Colors
    | SadEmoji Evergreen.V88.Color.Colors
    | Man Evergreen.V88.Color.Colors
    | TileImage Evergreen.V88.Tile.TileGroup Int Evergreen.V88.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V88.Color.Colors
    | DragCursor Evergreen.V88.Color.Colors
    | PinchCursor Evergreen.V88.Color.Colors
    | Line Int Evergreen.V88.Color.Color
    | Animal Evergreen.V88.Animal.AnimalType Evergreen.V88.Color.Colors


type Content
    = ImageType (Evergreen.V88.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V88.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , to : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , to : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V88.Id.Id Evergreen.V88.Id.MailId)
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
    | TextTool (Evergreen.V88.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V88.Id.Id Evergreen.V88.Id.UserId, Evergreen.V88.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V88.Id.Id Evergreen.V88.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
