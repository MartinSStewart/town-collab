module Evergreen.V124.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V124.Animal
import Evergreen.V124.Color
import Evergreen.V124.Coord
import Evergreen.V124.DisplayName
import Evergreen.V124.Id
import Evergreen.V124.Sprite
import Evergreen.V124.Tile
import Pixels


type Image
    = Stamp Evergreen.V124.Color.Colors
    | SunglassesEmoji Evergreen.V124.Color.Colors
    | NormalEmoji Evergreen.V124.Color.Colors
    | SadEmoji Evergreen.V124.Color.Colors
    | Man Evergreen.V124.Color.Colors
    | TileImage Evergreen.V124.Tile.TileGroup Int Evergreen.V124.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V124.Color.Colors
    | DragCursor Evergreen.V124.Color.Colors
    | PinchCursor Evergreen.V124.Color.Colors
    | Line Int Evergreen.V124.Color.Color
    | Animal Evergreen.V124.Animal.AnimalType Evergreen.V124.Color.Colors


type Content
    = ImageType (Evergreen.V124.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V124.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId)
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
    , from : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , to : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , to : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId)
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
    | TextTool (Evergreen.V124.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V124.Id.Id Evergreen.V124.Id.UserId, Evergreen.V124.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V124.Id.Id Evergreen.V124.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
