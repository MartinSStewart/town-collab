module Evergreen.V52.Cursor exposing (..)

import Evergreen.V52.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    }
