module Evergreen.V109.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V109.Animal
import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.DisplayName
import Evergreen.V109.Id
import Evergreen.V109.Sprite
import Evergreen.V109.Tile
import Pixels


type Image
    = Stamp Evergreen.V109.Color.Colors
    | SunglassesEmoji Evergreen.V109.Color.Colors
    | NormalEmoji Evergreen.V109.Color.Colors
    | SadEmoji Evergreen.V109.Color.Colors
    | Man Evergreen.V109.Color.Colors
    | TileImage Evergreen.V109.Tile.TileGroup Int Evergreen.V109.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V109.Color.Colors
    | DragCursor Evergreen.V109.Color.Colors
    | PinchCursor Evergreen.V109.Color.Colors
    | Line Int Evergreen.V109.Color.Color
    | Animal Evergreen.V109.Animal.AnimalType Evergreen.V109.Color.Colors


type Content
    = ImageType (Evergreen.V109.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V109.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId)
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
    , from : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , to : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , to : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId)
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
    | TextTool (Evergreen.V109.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V109.Id.Id Evergreen.V109.Id.UserId, Evergreen.V109.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
