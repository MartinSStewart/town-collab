module Evergreen.V84.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V84.Animal
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.DisplayName
import Evergreen.V84.Id
import Evergreen.V84.Shaders
import Evergreen.V84.Tile
import Pixels


type Image
    = Stamp Evergreen.V84.Color.Colors
    | SunglassesEmoji Evergreen.V84.Color.Colors
    | NormalEmoji Evergreen.V84.Color.Colors
    | SadEmoji Evergreen.V84.Color.Colors
    | Man Evergreen.V84.Color.Colors
    | TileImage Evergreen.V84.Tile.TileGroup Int Evergreen.V84.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V84.Color.Colors
    | DragCursor Evergreen.V84.Color.Colors
    | PinchCursor Evergreen.V84.Color.Colors
    | Line Int Evergreen.V84.Color.Color
    | Animal Evergreen.V84.Animal.AnimalType Evergreen.V84.Color.Colors


type Content
    = ImageType (Evergreen.V84.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V84.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , to : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V84.Id.Id Evergreen.V84.Id.MailId)
    | TextToolButton
    | ExportButton
    | ImportButton


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
    | TextTool (Evergreen.V84.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V84.Id.Id Evergreen.V84.Id.UserId, Evergreen.V84.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V84.Id.Id Evergreen.V84.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , to : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    }
