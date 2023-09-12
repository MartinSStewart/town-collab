module Evergreen.V85.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V85.Animal
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.DisplayName
import Evergreen.V85.Id
import Evergreen.V85.Shaders
import Evergreen.V85.Tile
import Pixels


type Image
    = Stamp Evergreen.V85.Color.Colors
    | SunglassesEmoji Evergreen.V85.Color.Colors
    | NormalEmoji Evergreen.V85.Color.Colors
    | SadEmoji Evergreen.V85.Color.Colors
    | Man Evergreen.V85.Color.Colors
    | TileImage Evergreen.V85.Tile.TileGroup Int Evergreen.V85.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V85.Color.Colors
    | DragCursor Evergreen.V85.Color.Colors
    | PinchCursor Evergreen.V85.Color.Colors
    | Line Int Evergreen.V85.Color.Color
    | Animal Evergreen.V85.Animal.AnimalType Evergreen.V85.Color.Colors


type Content
    = ImageType (Evergreen.V85.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V85.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , to : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V85.Id.Id Evergreen.V85.Id.MailId)
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
    | TextTool (Evergreen.V85.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V85.Id.Id Evergreen.V85.Id.UserId, Evergreen.V85.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V85.Id.Id Evergreen.V85.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , to : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    }
