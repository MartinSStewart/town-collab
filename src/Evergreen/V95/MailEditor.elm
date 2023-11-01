module Evergreen.V95.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V95.Animal
import Evergreen.V95.Color
import Evergreen.V95.Coord
import Evergreen.V95.DisplayName
import Evergreen.V95.Id
import Evergreen.V95.Sprite
import Evergreen.V95.Tile
import Pixels


type Image
    = Stamp Evergreen.V95.Color.Colors
    | SunglassesEmoji Evergreen.V95.Color.Colors
    | NormalEmoji Evergreen.V95.Color.Colors
    | SadEmoji Evergreen.V95.Color.Colors
    | Man Evergreen.V95.Color.Colors
    | TileImage Evergreen.V95.Tile.TileGroup Int Evergreen.V95.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V95.Color.Colors
    | DragCursor Evergreen.V95.Color.Colors
    | PinchCursor Evergreen.V95.Color.Colors
    | Line Int Evergreen.V95.Color.Color
    | Animal Evergreen.V95.Animal.AnimalType Evergreen.V95.Color.Colors


type Content
    = ImageType (Evergreen.V95.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V95.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId)
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
    , from : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , to : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , to : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId)
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
    | TextTool (Evergreen.V95.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V95.Id.Id Evergreen.V95.Id.UserId, Evergreen.V95.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V95.Id.Id Evergreen.V95.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
