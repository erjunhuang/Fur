Shader "Engine/Character/RestoreFur"
{
    Properties
    {   
        _NoiseMap("NoiseMap", 2D) = "white" {}
        _MainTex("MainTex", 2D) = "white" {}
        _MaskMap("MaskMap", 2D) = "white" {}
        _FurLength("FurLength",float) = 0.025000000372529
        _GravityStrength("GravityStrength",float) = 0.300000011920928

        _u_dir_light_attr_0("_u_dir_light_attr_0",vector) = (0,0,0,0)
        _u_dir_light_attr_1("_u_dir_light_attr_1",vector) = (1.25,1.25,1.25,3)
        _u_dir_light_attr_2("_u_dir_light_attr_2",vector) = (0,0,0,0)
        _u_dir_light_attr_3("_u_dir_light_attr_3",vector) = (0.579228103160858,-0.573576092720031,-0.579228103160858,0.00100000004749745)
        _u_dir_light_attr_4("_u_dir_light_attr_4",vector) = (1,0,0,0)
        light_strength_mod("light_strength_mod",float) = 1.14999997615814

        AddColor("AddColor",Color) = (1,1,1,1)
        FurUVTilling("FurUVTilling",float) = 3.5
        FurUVOffset("FurUVOffset",float) = 0.00499999988824129
        _SpecColor1("SpecColor1",Color) = (0.702000021934509,0.643100023269653,0.651000022888183,0)
        _SpecColor2("SpecColor2",Color) = (0.603900015354156,0.529399991035461,0.600000023841857,0)
        _SpecShift1("SpecShift1",float) = 0.100000001490116
        _SpecShift2("SpecShift2",float) = 0.200000002980232
        _SpecSmooth1("SpecSmooth1",float) = 200
        _SpecSmooth2("SpecSmooth2",float) = 60
        _Glossiness1("Glossiness1",float) = 0.200000002980232
        _Glossiness2("Glossiness2",float) = 0.100000001490116
        _OcclusionColor("OcclusionColor",Color) = (0.682399988174438,0.635299980640411,0.619599997997283,1)
        _Thickness("Thickness",float) = 2
        _LightFilter("LightFilter",float) = 0.5
        _Blur("Blur",float) = 0
        _FurLightExposure("FurLightExposure",float) = 5
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "RestoreFurSurface.cginc"
            ENDCG
        }
        Pass
        {   
            Tags{ "LightMode" = "FurRendererLayer"}
            ZWrite On
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "RestoreFurSurface.cginc"
            ENDCG
        }

        //Pass
        //{
        //    Tags{ "LightMode" = "FurRendererBase"}
        //    ZWrite On
        //    ZTest LEqual
        //    Blend One Zero
        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag
        //    #include "RealFurSurface.cginc"
        //    ENDHLSL
        //}
        //Pass
        //{
        //    Tags{ "LightMode" = "FurRendererLayer"}
        //    ZWrite On
        //    ZTest LEqual
        //    Blend SrcAlpha OneMinusSrcAlpha
        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag
        //    #include "RealFurSurface.cginc"
        //    ENDHLSL
        //}
    }
}
