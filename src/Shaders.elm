module Shaders exposing
    ( DebrisVertex
    , InstancedVertex
    , MapOverlayVertex
    , RenderData
    , ScissorBox
    , blend
    , clearDepth
    , debrisVertexShader
    , depthTest
    , drawBackground
    , drawWaterReflection
    , fragmentShader
    , instancedVertexShader
    , mapSize
    , mapSquare
    , noUserIdSelected
    , opacityAndUserId
    , scissorBox
    , triangleFan
    , vertexShader
    , worldGenUserId
    , worldMapFragmentShader
    , worldMapOverlayFragmentShader
    , worldMapOverlayVertexShader
    , worldMapVertexShader
    )

import Bitwise
import Color exposing (Color)
import Coord exposing (Coord)
import Dict exposing (Dict)
import Effect.WebGL exposing (Shader)
import Effect.WebGL.Settings exposing (Setting)
import Effect.WebGL.Settings.Blend as Blend
import Effect.WebGL.Settings.DepthTest
import Id exposing (Id, UserId)
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 exposing (Vec3)
import Math.Vector4 as Vec4 exposing (Vec4)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Random
import Sprite exposing (Vertex)
import TimeOfDay
import Units exposing (TerrainUnit)
import WebGL.Texture


type alias InstancedVertex =
    { localPosition : Vec2
    , index : Float
    }


type alias RenderData =
    { nightFactor : Float
    , texture : WebGL.Texture.Texture
    , lights : WebGL.Texture.Texture
    , depth : WebGL.Texture.Texture
    , staticViewMatrix : Mat4
    , viewMatrix : Mat4
    , time : Float
    , scissors : ScissorBox
    , screenSize : Vec2
    }


noUserIdSelected : number
noUserIdSelected =
    -2


worldGenUserId : Id UserId
worldGenUserId =
    Id.fromInt -1


opacityAndUserId : Float -> Id UserId -> Float
opacityAndUserId opacity userId =
    opacity
        * Sprite.opaque
        |> round
        |> toFloat
        |> (+) (Id.toInt userId |> Bitwise.shiftLeftBy 4 |> toFloat)


triangleFan : List attributes -> Effect.WebGL.Mesh attributes
triangleFan vertices =
    --let
    --    _ =
    --        Debug.log "new triangleFan" ""
    --in
    Effect.WebGL.triangleFan vertices


blend : Setting
blend =
    Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha


halfMapSize : Quantity number TerrainUnit
halfMapSize =
    Quantity.unsafe 11


mapSize : Quantity number TerrainUnit
mapSize =
    Quantity.multiplyBy 2 halfMapSize


mapSquare : Effect.WebGL.Mesh { position : Vec2, vcoord2 : Vec2 }
mapSquare =
    let
        size =
            Quantity.unwrap halfMapSize
    in
    Effect.WebGL.triangleFan
        [ { position = Vec2.vec2 0 0
          , vcoord2 = Vec2.vec2 -size -size
          }
        , { position = Vec2.vec2 1 0
          , vcoord2 = Vec2.vec2 size -size
          }
        , { position = Vec2.vec2 1 1
          , vcoord2 = Vec2.vec2 size size
          }
        , { position = Vec2.vec2 0 1
          , vcoord2 = Vec2.vec2 -size size
          }
        ]


reflectionDepth : Float
reflectionDepth =
    0.05


sunMesh : Effect.WebGL.Mesh Vertex
sunMesh =
    Sprite.spriteWithZ
        1
        Color.black
        Color.black
        (Coord.xy -24 -24)
        reflectionDepth
        (Coord.xy 48 48)
        (Coord.xy 640 23)
        (Coord.xy 48 48)
        |> Sprite.toMesh


moonMesh : Effect.WebGL.Mesh Vertex
moonMesh =
    Sprite.spriteWithZ
        1
        Color.black
        Color.black
        (Coord.xy -21 -21)
        reflectionDepth
        (Coord.xy 42 42)
        (Coord.xy 591 145)
        (Coord.xy 42 42)
        |> Sprite.toMesh


starColor : Color
starColor =
    Color.rgb255 200 200 255


randomStars : Random.Generator (List (List Vertex))
randomStars =
    Random.map4
        (\x y opacity star ->
            Sprite.textWithZAndOpacityAndUserId
                (opacityAndUserId opacity (Id.fromInt 0))
                starColor
                1
                star
                0
                (Coord.xy x y)
                reflectionDepth
        )
        (Random.int -4000 4000)
        (Random.int -4000 4000)
        (Random.float 0.1 1)
        (Random.weighted ( 0.5, "." ) [ ( 0.1, "¤" ), ( 0.1, "*" ), ( 0.1, "´" ), ( 0.1, "`" ), ( 0.1, "×" ) ])
        |> Random.list 2500


starsMesh : Effect.WebGL.Mesh Vertex
starsMesh =
    Random.step randomStars (Random.initialSeed 123)
        |> Tuple.first
        |> List.concat
        |> Sprite.toMesh


clearDepth : Float -> Vec4 -> ScissorBox -> Effect.WebGL.Entity
clearDepth nightFactor color scissors =
    Effect.WebGL.entityWith
        [ Effect.WebGL.Settings.DepthTest.always { write = True, near = 0, far = 1 }
        , blend
        , scissorBox scissors
        ]
        fillVertexShader
        fillFragmentShader
        viewportSquare
        { color = color, night = nightFactor }


viewportSquare : Effect.WebGL.Mesh { x : Float, y : Float }
viewportSquare =
    Effect.WebGL.triangleFan
        [ { x = -1, y = -1 }
        , { x = 1, y = -1 }
        , { x = 1, y = 1 }
        , { x = -1, y = 1 }
        ]


fillVertexShader : Shader { x : Float, y : Float } u {}
fillVertexShader =
    [glsl|

attribute float x;
attribute float y;

void main () {
  gl_Position = vec4(vec2(x, y), 1.0, 1.0);
}

|]


fillFragmentShader : Shader {} { u | color : Vec4, night : Float } {}
fillFragmentShader =
    [glsl|
precision mediump float;
uniform vec4 color;
uniform float night;

void main () {
    vec3 nightColor = vec3(1.0, 1.0, 1.0) * (1.0 - night) + vec3(0.33, 0.4, 0.645) * night;
    
    gl_FragColor = color * vec4(nightColor, 1.0);
}
    |]


drawBackground :
    RenderData
    -> Dict ( Int, Int ) { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    -> List Effect.WebGL.Entity
drawBackground { nightFactor, viewMatrix, texture, lights, depth, time, scissors, screenSize } meshes =
    Dict.toList meshes
        |> List.map
            (\( _, mesh ) ->
                Effect.WebGL.entityWith
                    [ Effect.WebGL.Settings.cullFace Effect.WebGL.Settings.back
                    , Effect.WebGL.Settings.DepthTest.default
                    , blend
                    , scissorBox scissors
                    ]
                    vertexShader
                    fragmentShader
                    mesh.background
                    { view = viewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , color = Vec4.vec4 1 1 1 1
                    , userId = noUserIdSelected
                    , time = time
                    , night = nightFactor
                    , lights = lights
                    , depth = depth
                    , screenSize = screenSize
                    , waterReflection = 0
                    }
            )


depthTest : Setting
depthTest =
    Effect.WebGL.Settings.DepthTest.lessOrEqual { write = True, near = 0, far = 1 }


type alias ScissorBox =
    { left : Int, bottom : Int, width : Int, height : Int }


scissorBox : ScissorBox -> Setting
scissorBox { left, bottom, width, height } =
    Effect.WebGL.Settings.scissor left bottom width height


drawWaterReflection : Bool -> RenderData -> { a | windowSize : Coord Pixels, zoomFactor : Int } -> List Effect.WebGL.Entity
drawWaterReflection includeSunOrMoon { staticViewMatrix, nightFactor, texture, lights, depth, time, scissors, screenSize } model =
    Effect.WebGL.entityWith
        [ Effect.WebGL.Settings.cullFace Effect.WebGL.Settings.back
        , depthTest
        , blend
        , scissorBox scissors
        ]
        vertexShader
        fragmentShader
        starsMesh
        { view = staticViewMatrix
        , texture = texture
        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
        , color = Vec4.vec4 2 2 2 nightFactor
        , userId = noUserIdSelected
        , time = time
        , night = nightFactor
        , lights = lights
        , depth = depth
        , screenSize = screenSize
        , waterReflection = 1
        }
        :: (if includeSunOrMoon then
                [ Effect.WebGL.entityWith
                    [ Effect.WebGL.Settings.cullFace Effect.WebGL.Settings.back
                    , depthTest
                    , blend
                    , scissorBox scissors
                    ]
                    vertexShader
                    fragmentShader
                    (if TimeOfDay.isDayTime nightFactor then
                        sunMesh

                     else
                        moonMesh
                    )
                    { view = Coord.translateMat4 (TimeOfDay.sunMoonPosition model nightFactor) staticViewMatrix
                    , texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , color = Vec4.vec4 1 1 1 1
                    , userId = noUserIdSelected
                    , time = time
                    , night = nightFactor
                    , lights = lights
                    , depth = depth
                    , screenSize = screenSize
                    , waterReflection = 1
                    }
                ]

            else
                []
           )


vertexShader :
    Shader
        Vertex
        { u | view : Mat4, textureSize : Vec2, userId : Float }
        { vcoord : Vec2
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        , position2 : Vec2
        , z2 : Float
        }
vertexShader =
    [glsl|
attribute float x;
attribute float y;
attribute float z;
attribute float texturePosition;
attribute float opacityAndUserId;
attribute float primaryColor;
attribute float secondaryColor;
uniform mat4 view;
uniform vec2 textureSize;
uniform float userId;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;
varying vec2 position2;
varying float z2;

int OR(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 || mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);

            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

vec3 floatColorToVec3(float color) {
    int colorInt = int(color);
    float blue = float(AND(colorInt, 0xFF)) / 255.0;
    float green = float(AND(RShift(colorInt, 8.0), 0xFF)) / 255.0;
    float red = float(AND(RShift(colorInt, 16.0), 0xFF)) / 255.0;
    return vec3(red, green, blue);
}

void main () {
    gl_Position = view * vec4(vec3(x, y, z), 1.0);

    float y2 = floor(texturePosition / textureSize.x);
    vcoord = vec2(texturePosition - y2 * textureSize.x, y2) / textureSize;
    opacity = float(AND(int(opacityAndUserId), 0xF)) / 15.0;
    isSelected = userId == float(RShift(int(opacityAndUserId), 4.0)) ? 1.0 : 0.0;


    primaryColor2 = floatColorToVec3(primaryColor);
    secondaryColor2 = floatColorToVec3(secondaryColor);
    position2 = vec2(x, y);
    z2 = z;
}|]


instancedVertexShader :
    Shader
        InstancedVertex
        { u
            | view : Mat4
            , textureSize : Vec2
            , userId : Float
            , position0 : Vec3
            , size0 : Vec2
            , texturePosition0 : Float
            , opacityAndUserId0 : Float
            , primaryColor0 : Float
            , secondaryColor0 : Float
        }
        { vcoord : Vec2
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        , position2 : Vec2
        , z2 : Float
        }
instancedVertexShader =
    [glsl|
attribute vec2 localPosition;
attribute float index;
uniform mat4 view;
uniform vec2 textureSize;
uniform float userId;
uniform vec3 position0;
uniform vec2 size0;
uniform float texturePosition0;
uniform float opacityAndUserId0;
uniform float primaryColor0;
uniform float secondaryColor0;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;
varying vec2 position2;
varying float z2;

int OR(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 || mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);

            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

vec3 floatColorToVec3(float color) {
    int colorInt = int(color);
    float blue = float(AND(colorInt, 0xFF)) / 255.0;
    float green = float(AND(RShift(colorInt, 8.0), 0xFF)) / 255.0;
    float red = float(AND(RShift(colorInt, 16.0), 0xFF)) / 255.0;
    return vec3(red, green, blue);
}

void main () {
    vec2 localPosition2 = localPosition * size0;

    gl_Position = view * vec4(position0 + vec3(localPosition2.xy, 0.0), 1.0);



    float y2 = floor(texturePosition0 / textureSize.x);
    vcoord = (vec2(texturePosition0 - y2 * textureSize.x, y2) + localPosition2) / textureSize;
    opacity = float(AND(int(opacityAndUserId0), 0xF)) / 15.0;
    isSelected = userId == float(RShift(int(opacityAndUserId0), 4.0)) ? 1.0 : 0.0;


    primaryColor2 = floatColorToVec3(primaryColor0);
    secondaryColor2 = floatColorToVec3(secondaryColor0);
    position2 = position0.xy + localPosition2;
    z2 = 0.0;
}|]


fragmentShader :
    Shader
        {}
        { u
            | texture : WebGL.Texture.Texture
            , lights : WebGL.Texture.Texture
            , depth : WebGL.Texture.Texture
            , time : Float
            , color : Vec4
            , night : Float
            , screenSize : Vec2
            , waterReflection : Float
        }
        { vcoord : Vec2
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        , position2 : Vec2
        , z2 : Float
        }
fragmentShader =
    [glsl|
#extension GL_EXT_frag_depth : enable
precision mediump float;
uniform sampler2D texture;
uniform sampler2D lights;
uniform sampler2D depth;
uniform float time;
uniform vec4 color;
uniform float night;
uniform vec2 screenSize;
uniform float waterReflection;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;
varying vec2 position2;
varying float z2;

vec3 primaryColor = vec3(1.0, 0.0, 1.0);
vec3 primaryColorMidShade = vec3(233.0 / 255.0, 45.0 / 255.0, 231.0 / 255.0);
vec3 primaryColorShade = vec3(209.0 / 255.0, 64.0 / 255.0, 206.0 / 255.0);
vec3 secondaryColor = vec3(0.0, 1.0, 1.0);
vec3 secondaryColorMidShade = vec3(0.0 / 255.0, 229.0 / 255.0, 229.0 / 255.0);
vec3 secondaryColorShade = vec3(96.0 / 255.0, 209.0 / 255.0, 209.0 / 255.0);

void main () {
    vec2 vcoord2 =
        waterReflection == 1.0
            ? vcoord + vec2(
                floor(0.8 * sin(2.0 + time * 3.0 + floor(gl_FragCoord.y / 6.0) * 6.0 / 30.0 )) / 2048.0,
                floor(0.6 * sin(time * 3.0 +  floor(gl_FragCoord.y / 6.0) * 6.0  / 30.0 )) / 2048.0)
            : vcoord;

    vec4 textureColor = texture2D(texture, vcoord2);

    gl_FragDepthEXT = texture2D(depth, vcoord2).x + z2;

    if (textureColor.a == 0.0) {
        discard;
    }
    vec4 highlight =
        vec4(1.3, 1.0, 1.0, 0.0) * (mod(-time + floor(position2.x + position2.y) / 40.0, 1.0)) - vec4(0.4, 0.4, 0.4, 0.0);

    vec4 textureColor2 =
        textureColor.xyz == primaryColor
            ? vec4(primaryColor2, opacity)
            : textureColor.xyz == primaryColorMidShade
                ? vec4(primaryColor2 * 0.9, opacity)
                : textureColor.xyz == primaryColorShade
                    ? vec4(primaryColor2 * 0.8, opacity)
                    : textureColor.xyz == secondaryColor
                        ? vec4(secondaryColor2, opacity)
                        : textureColor.xyz == secondaryColorMidShade
                            ? vec4(secondaryColor2 * 0.9, opacity)
                            : textureColor.xyz == secondaryColorShade
                                ? vec4(secondaryColor2 * 0.8, opacity)
                                : vec4(textureColor.xyz, opacity);

    vec3 nightColor = vec3(1.0, 1.0, 1.0) * (1.0 - night) + vec3(0.33, 0.4, 0.645) * night;

    float lightHdrAdjustment = (1.0 / 0.95) * (night - 0.05);

    vec3 light =
        night > 0.5
            ? (texture2D(lights, vcoord2).xyz * vec3(2.0, 2.0, 1.5) + 1.0) * lightHdrAdjustment
            : vec3(1.0, 1.0, 1.0);

    gl_FragColor = textureColor2 * vec4(nightColor, 1.0) * vec4(max(light, vec3(1.0, 1.0, 1.0)), 1.0) * color + 0.6 * isSelected * highlight;
}|]


type alias DebrisVertex =
    { position : Vec2
    , texturePosition : Float
    , initialSpeed : Vec2
    , startTime : Float
    , primaryColor : Float
    , secondaryColor : Float
    }


debrisVertexShader :
    Shader
        DebrisVertex
        { u | view : Mat4, time2 : Float, textureSize : Vec2 }
        { vcoord : Vec2
        , opacity : Float
        , primaryColor2 : Vec3
        , secondaryColor2 : Vec3
        , isSelected : Float
        , position2 : Vec2
        , z2 : Float
        }
debrisVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 initialSpeed;
attribute float texturePosition;
attribute float startTime;
attribute float primaryColor;
attribute float secondaryColor;
uniform mat4 view;
uniform float time2;
uniform vec2 textureSize;
varying vec2 vcoord;
varying float opacity;
varying vec3 primaryColor2;
varying vec3 secondaryColor2;
varying float isSelected;
varying vec2 position2;
varying float z2;

int OR(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 || mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);

            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

vec3 floatColorToVec3(float color) {
    int colorInt = int(color);
    float blue = float(AND(colorInt, 0xFF)) / 255.0;
    float green = float(AND(RShift(colorInt, 8.0), 0xFF)) / 255.0;
    float red = float(AND(RShift(colorInt, 16.0), 0xFF)) / 255.0;
    return vec3(red, green, blue);
}

void main () {
    float seconds = time2 - startTime;
    gl_Position = view * vec4(position + vec2(0, 800.0 * seconds * seconds) + initialSpeed * seconds, 0.0, 1.0);
    float y = floor(texturePosition / textureSize.x);
    vcoord = vec2(texturePosition - y * textureSize.x, y) / textureSize;
    opacity = 1.0;
    isSelected = 0.0;
    primaryColor2 = floatColorToVec3(primaryColor);
    secondaryColor2 = floatColorToVec3(secondaryColor);
    position2 = position;
    z2 = 0.0;
}|]


worldMapVertexShader :
    Shader
        { position : Vec2, vcoord2 : Vec2 }
        { u | view : Mat4 }
        { vcoord : Vec2 }
worldMapVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 vcoord2;
uniform mat4 view;
varying vec2 vcoord;

void main () {
    gl_Position = view * vec4(position, 0.0, 1.0);
    vcoord = vcoord2;
}|]


worldMapFragmentShader : Shader {} { u | texture : WebGL.Texture.Texture, cellPosition : Vec2 } { vcoord : Vec2 }
worldMapFragmentShader =
    [glsl|
precision mediump float;
varying vec2 vcoord;
uniform sampler2D texture;
uniform vec2 cellPosition;

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

ivec2 getCornerOffset2d (float x, float y) {
    return x > y ? ivec2(1, 0) : ivec2(0, 1);
}

int getGrad3(int index) {
    return int(texture2D(texture, vec2(float(index) / 511.0, 2.0 / 2.0)).w * 256.0) - 1;
}

int getPermMod12(int index) {
    return int(texture2D(texture, vec2(float(index) / 511.0, 1.0 / 2.0)).w * 256.0);
}

int getPerm(int index) {
    return int(texture2D(texture, vec2(float(index) / 511.0, 0.0 / 2.0)).w * 256.0);
}

float getN2d (float x, float y, int i, int j) {
    float t = 0.5 - x * x - y * y;
    if (t < 0.0) {
        return 0.0;
    }

    int gi = getPermMod12(i + getPerm(j)) * 3;
    float t_ = t * t;
    return t_ * t_ * (float(getGrad3(gi)) * x + float(getGrad3(gi + 1)) * y);
}

int floor2(float a) {
    return int(floor(a));
}

float noise2d(float xin, float yin) {
    float f2 = 0.5 * (sqrt(3.0) - 1.0);
    float g2 = (3.0 - sqrt(3.0)) / 6.0;
    float s = (xin + yin) * f2;
    int i = floor2(xin + s);
    int j = floor2(yin + s);
    float t = float(i + j) * g2;
    float x0_ = float(i) - t;
    float y0_ = float(j) - t;
    float x0 = xin - x0_;
    float y0 = yin - y0_;
    ivec2 ij1 = getCornerOffset2d(x0, y0);
    int i1 = ij1.x;
    int j1 = ij1.y;
    float x1 = x0 - float(i1) + g2;
    float y1 = y0 - float(j1) + g2;
    float x2 = x0 - 1.0 + 2.0 * g2;
    float y2 = y0 - 1.0 + 2.0 * g2;
    int ii = AND(i, 255);
    int jj = AND(j, 255);
    float n0 = getN2d(x0, y0, ii, jj);
    float n1 = getN2d(x1, y1, (ii + i1), (jj + j1));
    float n2 = getN2d(x2, y2, (ii + 1), (jj + 1));
    return 70.0 * (n0 + n1 + n2);
}



void main () {
    float detail = 4.0;

    vec2 vcoord2 = cellPosition + vcoord;

    float x2 = floor(vcoord2.x * detail) / detail;
    float y2 = floor(vcoord2.y * detail) / detail;

    float terrainDivisionsPerCell = 4.0;
    float persistence = 2.0;
    float persistence2 = 1.0 + persistence;
    float scale = 5.0;
    float scale2 = 14.0 * scale;
    float lowFrequency = noise2d(x2 / scale2, y2 / scale2);
    float highFrequency = noise2d(x2 / scale, y2 / scale);
    float noise1 = highFrequency + (persistence * lowFrequency);
    float value = noise1 / persistence2;
    float value2 = (-highFrequency + (5.0 * lowFrequency)) / 6.0;

    vec4 treeColor = vec4(0.075, 0.471, 0.204, 1.0);
    float colorLevels = 4.0;
    float mix = floor(min(1.0, 8.0 * pow(max(0.0, value), 3.0)) * colorLevels) / colorLevels;

    gl_FragColor =
        value <= 0.0
            ? vec4( 0.6, 0.8, 1.0, 1.0)
            : (value2 > 0.45 && value2 < 0.47)
                ? vec4( 0.6, 0.5, 0.2, 1.0)
                : vec4( 0.525, 0.796, 0.384, 1.0); //* (1.0 - mix) + treeColor * mix;
}|]


type alias MapOverlayVertex =
    { position : Vec2, offset : Vec2 }


worldMapOverlayVertexShader :
    Shader
        MapOverlayVertex
        { u
            | view : Mat4
            , pixelData_0_0 : Vec2
            , pixelData_1_0 : Vec2
            , pixelData_2_0 : Vec2
            , pixelData_3_0 : Vec2
            , pixelData_0_1 : Vec2
            , pixelData_1_1 : Vec2
            , pixelData_2_1 : Vec2
            , pixelData_3_1 : Vec2
            , pixelData_0_2 : Vec2
            , pixelData_1_2 : Vec2
            , pixelData_2_2 : Vec2
            , pixelData_3_2 : Vec2
            , pixelData_0_3 : Vec2
            , pixelData_1_3 : Vec2
            , pixelData_2_3 : Vec2
            , pixelData_3_3 : Vec2
        }
        { vColor : Vec4 }
worldMapOverlayVertexShader =
    [glsl|
attribute vec2 position;
attribute vec2 offset;
uniform vec2 pixelData_0_0;
uniform vec2 pixelData_1_0;
uniform vec2 pixelData_2_0;
uniform vec2 pixelData_3_0;
uniform vec2 pixelData_0_1;
uniform vec2 pixelData_1_1;
uniform vec2 pixelData_2_1;
uniform vec2 pixelData_3_1;
uniform vec2 pixelData_0_2;
uniform vec2 pixelData_1_2;
uniform vec2 pixelData_2_2;
uniform vec2 pixelData_3_2;
uniform vec2 pixelData_0_3;
uniform vec2 pixelData_1_3;
uniform vec2 pixelData_2_3;
uniform vec2 pixelData_3_3;
uniform mat4 view;
varying vec4 vColor;

int AND(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);

    int byteVal = 1;
    int result = 0;

    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){

            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;

            if(addOn){
                result += byteVal;
            }

            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

void main () {
    gl_Position = view * vec4((position + offset) * 0.25, 0.0, 1.0);
    vec2 vCoord = offset;
    float dataX =
        offset.x < 2.0 * 4.0
            ? offset.x < 1.0 * 4.0
                ? offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_0_0.x
                        : pixelData_0_1.x
                    : offset.y < 3.0 * 4.0
                        ? pixelData_0_2.x
                        : pixelData_0_3.x
                : offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_1_0.x
                        : pixelData_1_1.x
                    : offset.y < 3.0 * 4.0
                        ? pixelData_1_2.x
                        : pixelData_1_3.x
            : offset.x < 3.0 * 4.0
                ? offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_2_0.x
                        : pixelData_2_1.x
                    : offset.y < 3.0 * 4.0
                        ? pixelData_2_2.x
                        : pixelData_2_3.x
                : offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_3_0.x
                        : pixelData_3_1.x
                    : offset.y < 3.0 * 4.0
                        ? pixelData_3_2.x
                        : pixelData_3_3.x;

    float dataY =
        offset.x < 2.0 * 4.0
            ? offset.x < 1.0 * 4.0
                ? offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_0_0.y
                        : pixelData_0_1.y
                    : offset.y < 3.0 * 4.0
                        ? pixelData_0_2.y
                        : pixelData_0_3.y
                : offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_1_0.y
                        : pixelData_1_1.y
                    : offset.y < 3.0 * 4.0
                        ? pixelData_1_2.y
                        : pixelData_1_3.y
            : offset.x < 3.0 * 4.0
                ? offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_2_0.y
                        : pixelData_2_1.y
                    : offset.y < 3.0 * 4.0
                        ? pixelData_2_2.y
                        : pixelData_2_3.y
                : offset.y < 2.0 * 4.0
                    ? offset.y < 1.0 * 4.0
                        ? pixelData_3_0.y
                        : pixelData_3_1.y
                    : offset.y < 3.0 * 4.0
                        ? pixelData_3_2.y
                        : pixelData_3_3.y;
    int index = AND(3, int(vCoord.x)) + AND(3, int(vCoord.y)) * 4;
    int value = AND(1, RShift(int(dataX), float(index))) + AND(1, RShift(int(dataY), float(index))) * 2;
    vColor =
        value == 0
            ? vec4(0.0, 0.0, 0.0, 0.0)
            : value == 1
                ? vec4(0.2, 0.5, 0.2, 1.0)
                : value == 2
                    ? vec4(0.1, 0.1, 0.1, 1.0)
                    : vec4(0.7, 0.2, 0.1, 1.0);
}|]


worldMapOverlayFragmentShader : Shader {} u { vColor : Vec4 }
worldMapOverlayFragmentShader =
    [glsl|
precision mediump float;
varying vec4 vColor;

void main () {
    gl_FragColor = vColor;
}|]
