module WebGLFix.Internal exposing
    ( Option(..)
    , Setting(..)
    , enableOption
    , enableSetting
    )

import Elm.Kernel.WebGLFix


type Option
    = Alpha Bool
    | Depth Float
    | Stencil Int
    | Antialias
    | ClearColor Float Float Float Float
    | PreserveDrawingBuffer


enableOption : () -> Option -> ()
enableOption ctx option =
    case option of
        Alpha _ ->
            Elm.Kernel.WebGLFix.enableAlpha ctx option

        Depth _ ->
            Elm.Kernel.WebGLFix.enableDepth ctx option

        Stencil _ ->
            Elm.Kernel.WebGLFix.enableStencil ctx option

        Antialias ->
            Elm.Kernel.WebGLFix.enableAntialias ctx option

        ClearColor _ _ _ _ ->
            Elm.Kernel.WebGLFix.enableClearColor ctx option

        PreserveDrawingBuffer ->
            Elm.Kernel.WebGLFix.enablePreserveDrawingBuffer ctx option


type Setting
    = Blend Int Int Int Int Int Int Float Float Float Float
    | DepthTest Int Bool Float Float
    | StencilTest Int Int Int Int Int Int Int Int Int Int Int
    | Scissor Int Int Int Int
    | ColorMask Bool Bool Bool Bool
    | CullFace Int
    | PolygonOffset Float Float
    | SampleCoverage Float Bool
    | SampleAlphaToCoverage


enableSetting : () -> Setting -> ()
enableSetting cache setting =
    case setting of
        Blend _ _ _ _ _ _ _ _ _ _ ->
            Elm.Kernel.WebGLFix.enableBlend cache setting

        DepthTest _ _ _ _ ->
            Elm.Kernel.WebGLFix.enableDepthTest cache setting

        StencilTest _ _ _ _ _ _ _ _ _ _ _ ->
            Elm.Kernel.WebGLFix.enableStencilTest cache setting

        Scissor _ _ _ _ ->
            Elm.Kernel.WebGLFix.enableScissor cache setting

        ColorMask _ _ _ _ ->
            Elm.Kernel.WebGLFix.enableColorMask cache setting

        CullFace _ ->
            Elm.Kernel.WebGLFix.enableCullFace cache setting

        PolygonOffset _ _ ->
            Elm.Kernel.WebGLFix.enablePolygonOffset cache setting

        SampleCoverage _ _ ->
            Elm.Kernel.WebGLFix.enableSampleCoverage cache setting

        SampleAlphaToCoverage ->
            Elm.Kernel.WebGLFix.enableSampleAlphaToCoverage cache
