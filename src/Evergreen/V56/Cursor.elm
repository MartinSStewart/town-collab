module Evergreen.V56.Cursor exposing (..)

import Evergreen.V56.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    }
