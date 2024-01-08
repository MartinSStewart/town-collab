module Effect.WebGL.Texture exposing
    ( Texture, load, Error(..), size
    , loadWith, Options, defaultOptions, loadBytesWith, rgb, rgba, alpha, luminance, luminanceAlpha
    , Resize, linear, nearest
    , nearestMipmapLinear, nearestMipmapNearest
    , linearMipmapNearest, linearMipmapLinear
    , Bigger, Smaller
    , Wrap, repeat, clampToEdge, mirroredRepeat
    , nonPowerOfTwoOptions
    )

{-|


# Texture

@docs Texture, load, Error, size


# Custom Loading

@docs loadWith, Options, defaultOptions, loadBytesWith, rgb, rgba, alpha, luminance, luminanceAlpha


## Resizing

@docs Resize, linear, nearest
@docs nearestMipmapLinear, nearestMipmapNearest
@docs linearMipmapNearest, linearMipmapLinear
@docs Bigger, Smaller


## Wrapping

@docs Wrap, repeat, clampToEdge, mirroredRepeat


# Things You Shouldn’t Do

@docs nonPowerOfTwoOptions

-}

import Bytes exposing (Bytes)
import Effect.Command exposing (FrontendOnly)
import Effect.Internal
import Effect.Task exposing (Task)
import WebGLFix.Texture


{-| Use `Texture` to pass the `sampler2D` uniform value to the shader.
You can create a texture with [`load`](#load) or [`loadWith`](#loadWith)
and measure its dimensions with [`size`](#size).
-}
type alias Texture =
    WebGLFix.Texture.Texture


{-| Loads a texture from the given url with default options.
PNG and JPEG are known to work, but other formats have not been as
well-tested yet.

The Y axis of the texture is flipped automatically for you, so it has
the same direction as in the clip-space, i.e. pointing up.

If you need to change flipping, filtering or wrapping, you can use
[`loadWith`](#loadWith).

    load url =
        loadWith defaultOptions url

-}
load : String -> Task FrontendOnly Error Texture
load =
    loadWith defaultOptions


{-| Loading a texture can result in two kinds of errors:

  - `LoadError` means the image did not load for some reason. Maybe
    it was a network problem, or maybe it was a bad file format.

  - `SizeError` means you are trying to load a weird shaped image.
    For most operations you want a rectangle where the width is a power
    of two and the height is a power of two. This is more efficient on
    the GPU and it makes mipmapping possible. You can use
    [`nonPowerOfTwoOptions`](#nonPowerOfTwoOptions) to get things working
    now, but it is way better to create power-of-two assets!

-}
type Error
    = LoadError
    | SizeError Int Int


{-| Same as load, but allows to set options.
-}
loadWith : Options -> String -> Task FrontendOnly Error Texture
loadWith options texturePath =
    Effect.Internal.LoadTexture
        options
        texturePath
        (\result ->
            case result of
                Ok ok ->
                    Effect.Internal.Succeed ok

                Err WebGLFix.Texture.LoadError ->
                    Effect.Internal.Fail LoadError

                Err (WebGLFix.Texture.SizeError width height) ->
                    Effect.Internal.Fail (SizeError width height)
        )


{-| `Options` describe how to:

  - `magnify` - how to [`Resize`](#Resize) into a bigger texture
  - `minify` - how to [`Resize`](#Resize) into a smaller texture
  - `horizontalWrap` - how to [`Wrap`](#Wrap) the texture horizontally if the width is not a power of two
  - `verticalWrap` - how to [`Wrap`](#Wrap) the texture vertically if the height is not a power of two
  - `flipY` - flip the Y axis of the texture so it has the same direction
    as the clip-space, i.e. pointing up.

You can read more about these parameters in the
[specification](https://www.khronos.org/opengles/sdk/docs/man/xhtml/glTexParameter.xml).

-}
type alias Options =
    { magnify : Resize Bigger
    , minify : Resize Smaller
    , horizontalWrap : Wrap
    , verticalWrap : Wrap
    , flipY : Bool
    , premultiplyAlpha : Bool
    }


{-| Default options for the loaded texture.

    { magnify = linear
    , minify = nearestMipmapLinear
    , horizontalWrap = repeat
    , verticalWrap = repeat
    , flipY = True
    }

-}
defaultOptions : Options
defaultOptions =
    { magnify = linear
    , minify = nearestMipmapLinear
    , horizontalWrap = repeat
    , verticalWrap = repeat
    , flipY = True
    , premultiplyAlpha = False
    }


{-| The exact options needed to load textures with weird shapes.
If your image width or height is not a power of two, you need these
options:

    { magnify = linear
    , minify = nearest
    , horizontalWrap = clampToEdge
    , verticalWrap = clampToEdge
    , flipY = True
    }

-}
nonPowerOfTwoOptions : Options
nonPowerOfTwoOptions =
    { magnify = linear
    , minify = nearest
    , horizontalWrap = clampToEdge
    , verticalWrap = clampToEdge
    , flipY = True
    , premultiplyAlpha = False
    }



-- RESIZING


{-| How to resize a texture.
-}
type alias Resize a =
    Effect.Internal.Resize a


{-| Returns the weighted average of the four texture elements that are closest
to the center of the pixel being textured.
-}
linear : Resize a
linear =
    Effect.Internal.Linear


{-| Returns the value of the texture element that is nearest
(in Manhattan distance) to the center of the pixel being textured.
-}
nearest : Resize a
nearest =
    Effect.Internal.Nearest


{-| Chooses the mipmap that most closely matches the size of the pixel being
textured and uses the `nearest` criterion (the texture element nearest to
the center of the pixel) to produce a texture value.

A mipmap is an ordered set of arrays representing the same image at
progressively lower resolutions.

This is the default value of the minify filter.

-}
nearestMipmapNearest : Resize Smaller
nearestMipmapNearest =
    Effect.Internal.NearestMipmapNearest


{-| Chooses the mipmap that most closely matches the size of the pixel being
textured and uses the `linear` criterion (a weighted average of the four
texture elements that are closest to the center of the pixel) to produce a
texture value.
-}
linearMipmapNearest : Resize Smaller
linearMipmapNearest =
    Effect.Internal.LinearMipmapNearest


{-| Chooses the two mipmaps that most closely match the size of the pixel being
textured and uses the `nearest` criterion (the texture element nearest to the
center of the pixel) to produce a texture value from each mipmap. The final
texture value is a weighted average of those two values.
-}
nearestMipmapLinear : Resize Smaller
nearestMipmapLinear =
    Effect.Internal.NearestMipmapLinear


{-| Chooses the two mipmaps that most closely match the size of the pixel being
textured and uses the `linear` criterion (a weighted average of the four
texture elements that are closest to the center of the pixel) to produce a
texture value from each mipmap. The final texture value is a weighted average
of those two values.
-}
linearMipmapLinear : Resize Smaller
linearMipmapLinear =
    Effect.Internal.LinearMipmapLinear


{-| Helps restrict `options.magnify` to only allow
[`linear`](#linear) and [`nearest`](#nearest).
-}
type alias Bigger =
    Effect.Internal.Bigger


{-| Helps restrict `options.magnify`, while also allowing
`options.minify` to use mipmapping resizes, like
[`nearestMipmapNearest`](#nearestMipmapNearest).
-}
type alias Smaller =
    Effect.Internal.Smaller


{-| Sets the wrap parameter for texture coordinate.
-}
type alias Wrap =
    Effect.Internal.Wrap


{-| Causes the integer part of the coordinate to be ignored. This is the
default value for both texture axis.
-}
repeat : Wrap
repeat =
    Effect.Internal.Repeat


{-| Causes coordinates to be clamped to the range 1 2N 1 - 1 2N, where N is
the size of the texture in the direction of clamping.
-}
clampToEdge : Wrap
clampToEdge =
    Effect.Internal.ClampToEdge


{-| Causes the coordinate c to be set to the fractional part of the texture
coordinate if the integer part is even; if the integer part is odd, then
the coordinate is set to 1 - frac, where frac represents the fractional part
of the coordinate.
-}
mirroredRepeat : Wrap
mirroredRepeat =
    Effect.Internal.MirroredRepeat


{-| Return the (width, height) size of a texture. Useful for sprite sheets
or other times you may want to use only a potion of a texture image.
-}
size : Texture -> ( Int, Int )
size =
    WebGLFix.Texture.size


{-| Building [`Texture`](#Texture) from bytes

  - [`Options`](#Options) - same as for [`loadWith`](#loadWith)
  - `(width, height)` - dimensions of new created texture
  - [`Format`](#Format) - pixel format in bytes
  - Bytes - encoded pixels, where `Bytes.width` > `width` \* `height` \* `Bytes per pixel` or you get `SizeError`
    Do not generate texture in `view`, [read more about this here](https://package.elm-lang.org/packages/elm-explorations/webgl/latest#making-the-most-of-the-gpu).

-}
loadBytesWith : Options -> ( Int, Int ) -> Format -> Bytes -> Result Error Texture
loadBytesWith options textureSize format bytes =
    let
        convertWrap wrap =
            case wrap of
                Effect.Internal.Repeat ->
                    WebGLFix.Texture.repeat

                Effect.Internal.ClampToEdge ->
                    WebGLFix.Texture.clampToEdge

                Effect.Internal.MirroredRepeat ->
                    WebGLFix.Texture.mirroredRepeat

        result : Result WebGLFix.Texture.Error WebGLFix.Texture.Texture
        result =
            WebGLFix.Texture.loadBytesWith
                { magnify =
                    case options.magnify of
                        Effect.Internal.Linear ->
                            WebGLFix.Texture.linear

                        _ ->
                            WebGLFix.Texture.nearest
                , minify =
                    case options.minify of
                        Effect.Internal.Linear ->
                            WebGLFix.Texture.linear

                        Effect.Internal.Nearest ->
                            WebGLFix.Texture.nearest

                        Effect.Internal.NearestMipmapNearest ->
                            WebGLFix.Texture.nearestMipmapNearest

                        Effect.Internal.LinearMipmapNearest ->
                            WebGLFix.Texture.linearMipmapNearest

                        Effect.Internal.NearestMipmapLinear ->
                            WebGLFix.Texture.nearestMipmapLinear

                        Effect.Internal.LinearMipmapLinear ->
                            WebGLFix.Texture.linearMipmapLinear
                , horizontalWrap = convertWrap options.horizontalWrap
                , verticalWrap = convertWrap options.verticalWrap
                , flipY = options.flipY
                , premultiplyAlpha = options.premultiplyAlpha
                }
                textureSize
                format
                bytes
    in
    case result of
        Ok texture ->
            Ok texture

        Err error ->
            case error of
                WebGLFix.Texture.LoadError ->
                    Err LoadError

                WebGLFix.Texture.SizeError w h ->
                    SizeError w h |> Err


{-| How to read bytes into pixel


## | Format | Channels | Bytes per pixel |

| rgba | 4 | 4 |
| rgb | 3 | 3 |
| luminanceAlpha | 2 | 2 |
| luminance | 1 | 1 |


## | alpha | 1 | 1 |

-}
type alias Format =
    WebGLFix.Texture.Format


{-| Single pixel is 3 bytes long and has 3 channels
-}
rgb : WebGLFix.Texture.Format
rgb =
    WebGLFix.Texture.rgb


{-| Single pixel is 4 bytes long and has 4 channels
-}
rgba : WebGLFix.Texture.Format
rgba =
    WebGLFix.Texture.rgba


{-| Single pixel is 2 bytes long and has 2 channels
-}
luminanceAlpha : WebGLFix.Texture.Format
luminanceAlpha =
    WebGLFix.Texture.luminanceAlpha


{-| Single pixel is 1 byte long and has 1 channel
-}
luminance : WebGLFix.Texture.Format
luminance =
    WebGLFix.Texture.luminance


{-| Single pixel is 1 byte long and has 1 channel
-}
alpha : WebGLFix.Texture.Format
alpha =
    WebGLFix.Texture.alpha
