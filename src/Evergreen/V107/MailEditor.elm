module Evergreen.V107.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V107.Animal
import Evergreen.V107.Color
import Evergreen.V107.Coord
import Evergreen.V107.DisplayName
import Evergreen.V107.Id
import Evergreen.V107.Sprite
import Evergreen.V107.Tile
import Pixels


type Image
    = Stamp Evergreen.V107.Color.Colors
    | SunglassesEmoji Evergreen.V107.Color.Colors
    | NormalEmoji Evergreen.V107.Color.Colors
    | SadEmoji Evergreen.V107.Color.Colors
    | Man Evergreen.V107.Color.Colors
    | TileImage Evergreen.V107.Tile.TileGroup Int Evergreen.V107.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V107.Color.Colors
    | DragCursor Evergreen.V107.Color.Colors
    | PinchCursor Evergreen.V107.Color.Colors
    | Line Int Evergreen.V107.Color.Color
    | Animal Evergreen.V107.Animal.AnimalType Evergreen.V107.Color.Colors


type Content
    = ImageType (Evergreen.V107.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V107.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId)
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
    , from : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , to : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , to : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId)
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
    | TextTool (Evergreen.V107.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V107.Id.Id Evergreen.V107.Id.UserId, Evergreen.V107.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V107.Id.Id Evergreen.V107.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
