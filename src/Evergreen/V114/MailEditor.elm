module Evergreen.V114.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V114.Animal
import Evergreen.V114.Color
import Evergreen.V114.Coord
import Evergreen.V114.DisplayName
import Evergreen.V114.Id
import Evergreen.V114.Sprite
import Evergreen.V114.Tile
import Pixels


type Image
    = Stamp Evergreen.V114.Color.Colors
    | SunglassesEmoji Evergreen.V114.Color.Colors
    | NormalEmoji Evergreen.V114.Color.Colors
    | SadEmoji Evergreen.V114.Color.Colors
    | Man Evergreen.V114.Color.Colors
    | TileImage Evergreen.V114.Tile.TileGroup Int Evergreen.V114.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V114.Color.Colors
    | DragCursor Evergreen.V114.Color.Colors
    | PinchCursor Evergreen.V114.Color.Colors
    | Line Int Evergreen.V114.Color.Color
    | Animal Evergreen.V114.Animal.AnimalType Evergreen.V114.Color.Colors


type Content
    = ImageType (Evergreen.V114.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V114.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId)
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
    , from : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , to : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , to : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId)
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
    | TextTool (Evergreen.V114.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V114.Id.Id Evergreen.V114.Id.UserId, Evergreen.V114.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
