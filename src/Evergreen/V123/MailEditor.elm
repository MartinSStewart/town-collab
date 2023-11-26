module Evergreen.V123.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V123.Animal
import Evergreen.V123.Color
import Evergreen.V123.Coord
import Evergreen.V123.DisplayName
import Evergreen.V123.Id
import Evergreen.V123.Sprite
import Evergreen.V123.Tile
import Pixels


type Image
    = Stamp Evergreen.V123.Color.Colors
    | SunglassesEmoji Evergreen.V123.Color.Colors
    | NormalEmoji Evergreen.V123.Color.Colors
    | SadEmoji Evergreen.V123.Color.Colors
    | Man Evergreen.V123.Color.Colors
    | TileImage Evergreen.V123.Tile.TileGroup Int Evergreen.V123.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V123.Color.Colors
    | DragCursor Evergreen.V123.Color.Colors
    | PinchCursor Evergreen.V123.Color.Colors
    | Line Int Evergreen.V123.Color.Color
    | Animal Evergreen.V123.Animal.AnimalType Evergreen.V123.Color.Colors


type Content
    = ImageType (Evergreen.V123.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V123.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId)
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
    , from : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , to : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , to : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId)
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
    | TextTool (Evergreen.V123.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V123.Id.Id Evergreen.V123.Id.UserId, Evergreen.V123.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V123.Id.Id Evergreen.V123.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
