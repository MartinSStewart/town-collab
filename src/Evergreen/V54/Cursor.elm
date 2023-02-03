module Evergreen.V54.Cursor exposing (..)

import Evergreen.V54.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V54.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V54.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V54.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V54.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V54.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V54.Shaders.Vertex
    }
