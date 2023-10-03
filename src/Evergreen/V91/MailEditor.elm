module Evergreen.V91.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V91.Animal
import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.DisplayName
import Evergreen.V91.Id
import Evergreen.V91.Shaders
import Evergreen.V91.Tile
import Pixels


type Image
    = Stamp Evergreen.V91.Color.Colors
    | SunglassesEmoji Evergreen.V91.Color.Colors
    | NormalEmoji Evergreen.V91.Color.Colors
    | SadEmoji Evergreen.V91.Color.Colors
    | Man Evergreen.V91.Color.Colors
    | TileImage Evergreen.V91.Tile.TileGroup Int Evergreen.V91.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V91.Color.Colors
    | DragCursor Evergreen.V91.Color.Colors
    | PinchCursor Evergreen.V91.Color.Colors
    | Line Int Evergreen.V91.Color.Color
    | Animal Evergreen.V91.Animal.AnimalType Evergreen.V91.Color.Colors


type Content
    = ImageType (Evergreen.V91.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V91.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId)
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
    , from : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , to : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , to : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId)
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
    | TextTool (Evergreen.V91.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V91.Id.Id Evergreen.V91.Id.UserId, Evergreen.V91.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
