module Evergreen.V82.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V82.Animal
import Evergreen.V82.Color
import Evergreen.V82.Coord
import Evergreen.V82.DisplayName
import Evergreen.V82.Id
import Evergreen.V82.Shaders
import Evergreen.V82.Tile
import Pixels


type Image
    = Stamp Evergreen.V82.Color.Colors
    | SunglassesEmoji Evergreen.V82.Color.Colors
    | NormalEmoji Evergreen.V82.Color.Colors
    | SadEmoji Evergreen.V82.Color.Colors
    | Man Evergreen.V82.Color.Colors
    | TileImage Evergreen.V82.Tile.TileGroup Int Evergreen.V82.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V82.Color.Colors
    | DragCursor Evergreen.V82.Color.Colors
    | PinchCursor Evergreen.V82.Color.Colors
    | Line Int Evergreen.V82.Color.Color
    | Animal Evergreen.V82.Animal.AnimalType Evergreen.V82.Color.Colors


type Content
    = ImageType (Evergreen.V82.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V82.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , to : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V82.Id.Id Evergreen.V82.Id.MailId)
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
    | TextTool (Evergreen.V82.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V82.Id.Id Evergreen.V82.Id.UserId, Evergreen.V82.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V82.Id.Id Evergreen.V82.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , to : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    }
