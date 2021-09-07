Shader "Engine/Character/Fur"
{
    Properties
    {   
        [Header(Map)]
        [Space(10)]
        _NoiseMap("NoiseMap", 2D) = "white" {}
        _MainTex("MainTex", 2D) = "white" {}
        _MaskMap("MaskMap", 2D) = "white" {}

        [Header(Sculpt)]
        [Space(10)]
        _FurLength("FurLength",float) = 0.025000000372529
        _GravityStrength("GravityStrength",float) = 0.300000011920928
        _FurUVTilling("FurUVTilling",float) = 3.5
        _FurUVOffset("FurUVOffset",float) = 0.00499999988824129
        _Thickness("Thickness",float) = 2
        _Blur("Blur",Range(0,1)) = 0

        [Header(AO)]
        [Space(10)]
        _OcclusionColor("OcclusionColor",Color) = (0.682399988174438,0.635299980640411,0.619599997997283,1)

        [Header(Light)]
        [Space(10)]
        _LightDir("LightDir",vector) = (0.579228103160858,-0.573576092720031,-0.579228103160858,0.00100000004749745)
        _AddColor("AddColor",Color) = (1,1,1,1)

        [Header(SSS)]
        [Space(10)]
        [HDR]_SSSColor("SSS Color",Color) = (1,1,1,1)
        [Gamma]_LightFilter("LightFilter",float) = 0.5
        _FurLightExposure("FurLightExposure",float) = 5
        
        [Header(Specular)]
        [Space(10)]
        _SpecColor1("SpecColor1",Color) = (0.702000021934509,0.643100023269653,0.651000022888183,0)
        _SpecColor2("SpecColor2",Color) = (0.603900015354156,0.529399991035461,0.600000023841857,0)
        _SpecShift1("SpecShift1",float) = 0.100000001490116
        _SpecShift2("SpecShift2",float) = 0.200000002980232
        _SpecSmooth1("SpecSmooth1",float) = 200
        _SpecSmooth2("SpecSmooth2",float) = 60
        _Glossiness1("Glossiness1",float) = 0.200000002980232
        _Glossiness2("Glossiness2",float) = 0.100000001490116
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "FurRendererBase"}
            ZWrite On
            ZTest LEqual
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "FurSurface.cginc"
            ENDHLSL
        }
        Pass
        {
            Tags{ "LightMode" = "FurRendererLayer"}
            ZWrite On
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "FurSurface.cginc"
            ENDHLSL
        }
         
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            ENDHLSL
        }
    }
}
