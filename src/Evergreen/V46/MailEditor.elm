module Evergreen.V46.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V46.Color
import Evergreen.V46.Coord
import Evergreen.V46.DisplayName
import Evergreen.V46.Id
import Evergreen.V46.Shaders
import Evergreen.V46.Tile
import Pixels


type Image
    = Stamp Evergreen.V46.Color.Colors
    | SunglassesEmoji Evergreen.V46.Color.Colors
    | NormalEmoji Evergreen.V46.Color.Colors
    | SadEmoji Evergreen.V46.Color.Colors
    | Cow Evergreen.V46.Color.Colors
    | Man Evergreen.V46.Color.Colors
    | TileImage Evergreen.V46.Tile.TileGroup Int Evergreen.V46.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V46.Color.Colors
    | DragCursor Evergreen.V46.Color.Colors
    | PinchCursor Evergreen.V46.Color.Colors


type alias Content =
    { position : Evergreen.V46.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V46.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , to : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V46.Id.Id Evergreen.V46.Id.MailId)


type alias ImagePlacer_ =
    { imageIndex : Int
    , rotationIndex : Int
    }


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V46.Id.Id Evergreen.V46.Id.UserId, Evergreen.V46.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V46.Id.Id Evergreen.V46.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V46.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , to : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    }
