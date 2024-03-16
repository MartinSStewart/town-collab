module Evergreen.V125.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V125.Animal
import Evergreen.V125.Color
import Evergreen.V125.Coord
import Evergreen.V125.DisplayName
import Evergreen.V125.Id
import Evergreen.V125.Sprite
import Evergreen.V125.Tile
import Pixels


type Image
    = Stamp Evergreen.V125.Color.Colors
    | SunglassesEmoji Evergreen.V125.Color.Colors
    | NormalEmoji Evergreen.V125.Color.Colors
    | SadEmoji Evergreen.V125.Color.Colors
    | Man Evergreen.V125.Color.Colors
    | TileImage Evergreen.V125.Tile.TileGroup Int Evergreen.V125.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V125.Color.Colors
    | DragCursor Evergreen.V125.Color.Colors
    | PinchCursor Evergreen.V125.Color.Colors
    | Line Int Evergreen.V125.Color.Color
    | Animal Evergreen.V125.Animal.AnimalType Evergreen.V125.Color.Colors


type Content
    = ImageType (Evergreen.V125.Coord.Coord Pixels.Pixels) Image
    | TextType (Evergreen.V125.Coord.Coord Pixels.Pixels) String


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId)
    | MailReceived2
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed2
        { deliveryTime : Effect.Time.Posix
        }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId)
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
    , from : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , to : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , to : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId)
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
    | TextTool (Evergreen.V125.Coord.Coord TextUnit)


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V125.Id.Id Evergreen.V125.Id.UserId, Evergreen.V125.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V125.Id.Id Evergreen.V125.Id.MailId)
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }
