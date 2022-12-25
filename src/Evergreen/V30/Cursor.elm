module Evergreen.V30.Cursor exposing (..)

import Evergreen.V30.Shaders
import WebGL


type alias CursorMeshes = 
    { defaultSprite : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , pointerSprite : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , dragScreenSprite : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , pinchSprite : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , eyeDropperSprite : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    }