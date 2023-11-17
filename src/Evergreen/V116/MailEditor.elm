module Evergreen.V116.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V116.Animal
import Evergreen.V116.Color
import Evergreen.V116.Coord
import Evergreen.V116.DisplayName
import Evergreen.V116.Id
import Evergreen.V116.Sprite
import Evergreen.V116.Tile
import Pixels


type Image
    = Stamp Evergreen.V116.Color.Colors
    | SunglassesEmoji Evergreen.V116.Color.Colors
    | NormalEmoji Evergreen.V116.Color.Colors
    | SadEmoji Evergreen.V116.Color.Colors
    | Man Evergreen.V116.Color.Colors
    | TileImage Evergreen.V116.Tile.TileGroup Int Evergreen.V116.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V116.Color.Colors
    | DragCursor Evergreen.V116.Color.Colors
    | PinchCursor Evergreen.V116.Color.Colors
    | Line Int Evergreen.V116.Color.Color
    | Animal Evergreen.V116.Animal.AnimalType Evergreen.V116.Color.Colors


type Content
    = ImageType (Evergreen.V116.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V116.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId)
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
    , from : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , to : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , to : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId)
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
    | TextTool (Evergreen.V116.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V116.Id.Id Evergreen.V116.Id.UserId, Evergreen.V116.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
