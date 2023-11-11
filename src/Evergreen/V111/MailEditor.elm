module Evergreen.V111.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V111.Animal
import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.DisplayName
import Evergreen.V111.Id
import Evergreen.V111.Sprite
import Evergreen.V111.Tile
import Pixels


type Image
    = Stamp Evergreen.V111.Color.Colors
    | SunglassesEmoji Evergreen.V111.Color.Colors
    | NormalEmoji Evergreen.V111.Color.Colors
    | SadEmoji Evergreen.V111.Color.Colors
    | Man Evergreen.V111.Color.Colors
    | TileImage Evergreen.V111.Tile.TileGroup Int Evergreen.V111.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V111.Color.Colors
    | DragCursor Evergreen.V111.Color.Colors
    | PinchCursor Evergreen.V111.Color.Colors
    | Line Int Evergreen.V111.Color.Color
    | Animal Evergreen.V111.Animal.AnimalType Evergreen.V111.Color.Colors


type Content
    = ImageType (Evergreen.V111.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V111.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId)
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
    , from : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , to : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , to : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId)
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
    | EraserTool
    | TextTool (Evergreen.V111.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V111.Id.Id Evergreen.V111.Id.UserId, Evergreen.V111.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V111.Id.Id Evergreen.V111.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
