module Evergreen.V50.Cursor exposing (..)

import Evergreen.V50.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    }
