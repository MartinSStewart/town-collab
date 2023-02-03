module Evergreen.V48.Cursor exposing (..)

import Evergreen.V48.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    }
