module Evergreen.V115.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V115.Animal
import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.DisplayName
import Evergreen.V115.Id
import Evergreen.V115.Sprite
import Evergreen.V115.Tile
import Pixels


type Image
    = Stamp Evergreen.V115.Color.Colors
    | SunglassesEmoji Evergreen.V115.Color.Colors
    | NormalEmoji Evergreen.V115.Color.Colors
    | SadEmoji Evergreen.V115.Color.Colors
    | Man Evergreen.V115.Color.Colors
    | TileImage Evergreen.V115.Tile.TileGroup Int Evergreen.V115.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V115.Color.Colors
    | DragCursor Evergreen.V115.Color.Colors
    | PinchCursor Evergreen.V115.Color.Colors
    | Line Int Evergreen.V115.Color.Color
    | Animal Evergreen.V115.Animal.AnimalType Evergreen.V115.Color.Colors


type Content
    = ImageType (Evergreen.V115.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V115.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId)
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
    , from : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , to : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , to : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId)
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
    | TextTool (Evergreen.V115.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V115.Id.Id Evergreen.V115.Id.UserId, Evergreen.V115.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
