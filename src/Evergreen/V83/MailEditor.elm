module Evergreen.V83.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V83.Animal
import Evergreen.V83.Color
import Evergreen.V83.Coord
import Evergreen.V83.DisplayName
import Evergreen.V83.Id
import Evergreen.V83.Shaders
import Evergreen.V83.Tile
import Pixels


type Image
    = Stamp Evergreen.V83.Color.Colors
    | SunglassesEmoji Evergreen.V83.Color.Colors
    | NormalEmoji Evergreen.V83.Color.Colors
    | SadEmoji Evergreen.V83.Color.Colors
    | Man Evergreen.V83.Color.Colors
    | TileImage Evergreen.V83.Tile.TileGroup Int Evergreen.V83.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V83.Color.Colors
    | DragCursor Evergreen.V83.Color.Colors
    | PinchCursor Evergreen.V83.Color.Colors
    | Line Int Evergreen.V83.Color.Color
    | Animal Evergreen.V83.Animal.AnimalType Evergreen.V83.Color.Colors


type Content
    = ImageType (Evergreen.V83.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V83.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , to : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V83.Id.Id Evergreen.V83.Id.MailId)
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
    | TextTool (Evergreen.V83.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V83.Id.Id Evergreen.V83.Id.UserId, Evergreen.V83.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V83.Id.Id Evergreen.V83.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }


type alias BackendMail =
    { content : List Content
    , status : MailStatus
    , from : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , to : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    }
