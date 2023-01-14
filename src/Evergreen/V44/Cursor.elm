module Evergreen.V44.Cursor exposing (..)

import Evergreen.V44.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V44.Shaders.Vertex
    }