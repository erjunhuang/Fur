#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _DetailAlbedoMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _Parallax;
half _OcclusionStrength;
half _ClearCoatMask;
half _ClearCoatSmoothness;
half _DetailAlbedoMapScale;
half _DetailNormalMapScale;
half _Surface;

uniform half _FurLength;
uniform half _GravityStrength;
uniform half4 _AddColor;
uniform half _FurUVOffset;
uniform half4 _SpecColor1;
uniform half4 _SpecColor2;
uniform half _SpecShift1;
uniform half _SpecShift2;
uniform half _SpecSmooth1;
uniform half _SpecSmooth2;
uniform half _Glossiness1;
uniform half _Glossiness2;
uniform half4 _OcclusionColor;
uniform half _FresnelLV;
uniform half _Thickness;
uniform half _LightFilter;
uniform half _Blur;
uniform half _FurLightExposure;
uniform half4 _SSSColor;
uniform half4 _LightDir;
CBUFFER_END

half _FUR_OFFSET;
sampler2D _NoiseMap; float4 _NoiseMap_ST;
//sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _MaskMap; float4 _MaskMap_ST;

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED
UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
UNITY_DOTS_INSTANCED_PROP(float, _Cutoff)
UNITY_DOTS_INSTANCED_PROP(float, _Smoothness)
UNITY_DOTS_INSTANCED_PROP(float, _Metallic)
UNITY_DOTS_INSTANCED_PROP(float, _BumpScale)
UNITY_DOTS_INSTANCED_PROP(float, _Parallax)
UNITY_DOTS_INSTANCED_PROP(float, _OcclusionStrength)
UNITY_DOTS_INSTANCED_PROP(float, _ClearCoatMask)
UNITY_DOTS_INSTANCED_PROP(float, _ClearCoatSmoothness)
UNITY_DOTS_INSTANCED_PROP(float, _DetailAlbedoMapScale)
UNITY_DOTS_INSTANCED_PROP(float, _DetailNormalMapScale)
UNITY_DOTS_INSTANCED_PROP(float, _Surface)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

#define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseColor)
#define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__SpecColor)
#define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__EmissionColor)
#define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Cutoff)
#define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Smoothness)
#define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Metallic)
#define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__BumpScale)
#define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Parallax)
#define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__OcclusionStrength)
#define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__ClearCoatMask)
#define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__ClearCoatSmoothness)
#define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__DetailAlbedoMapScale)
#define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__DetailNormalMapScale)
#define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Surface)
#endif

TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_ClearCoatMap);       SAMPLER(sampler_ClearCoatMap);

#ifdef _SPECULAR_SETUP
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

#ifdef _METALLICSPECGLOSSMAP //有图片
    specGloss = SAMPLE_METALLICSPECULAR(uv); //是高光流就采高光流的图片 金属流就采金属流的图片
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;//如果开启Albedo Alpha,就会用albedoAlpha * _Smoothness去影响specGloss的a值
    #else
        specGloss.a *= _Smoothness; //其他情况 只被_Smoothness影响
    #endif
#else //没有图片的情况
    #if _SPECULAR_SETUP  
        specGloss.rgb = _SpecColor.rgb;//高光流用颜色
    #else
        specGloss.rgb = _Metallic.rrr;//金属流用值rrr
    #endif

    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;//如果开启Albedo Alpha,就会用albedoAlpha * _Smoothness去影响specGloss的a值
    #else
        specGloss.a = _Smoothness;//其他情况 只被_Smoothness影响
    #endif
#endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
#ifdef _OCCLUSIONMAP
    // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
#if defined(SHADER_API_GLES)
    return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
#else
    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
#endif
#else
    return 1.0;
#endif
}


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
half2 SampleClearCoat(float2 uv)
{
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

#if defined(_CLEARCOATMAP)
    clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
#endif

    return clearCoatMaskSmoothness;
#else
    return half2(0.0, 1.0);
#endif  // _CLEARCOAT
}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
#if defined(_PARALLAXMAP)
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
#endif
}

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
{
    // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
    // detailAlbedo *= _DetailAlbedoMapScale;
    // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
    // return detailAlbedo * 2.0f;

    // A bit more optimized
    return 2.0h * detailAlbedo * scale - scale + 1.0h;
}

half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
{
#if defined(_DETAIL)
    half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;

    // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
#if defined(_DETAIL_SCALED)
    detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
#else
    detailAlbedo = 2.0h * detailAlbedo;
#endif

    return albedo * LerpWhiteTo(detailAlbedo, detailMask);
#else
    return albedo;
#endif
}

half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
{
#if defined(_DETAIL)
#if BUMP_SCALE_NOT_SUPPORTED
    half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
#else
    half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
#endif

    // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
    // For visual consistancy we going to do in all cases
    detailNormalTS = normalize(detailNormalTS);

    return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
#else
    return normalTS;
#endif
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

#if _SPECULAR_SETUP 
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = specGloss.rgb;
#else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
#endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoat = SampleClearCoat(uv);
    outSurfaceData.clearCoatMask = clearCoat.r;
    outSurfaceData.clearCoatSmoothness = clearCoat.g;
#else
    outSurfaceData.clearCoatMask = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
#endif

#if defined(_DETAIL)
    half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
    float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
    outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
    outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);

#endif
}

 

// GLES2 has limited amount of interpolators
#if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
#define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
#endif

#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

// keep this file in sync with LitGBufferPass.hlsl

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD2;
#endif

    float3 normalWS                 : TEXCOORD3;
//#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
//#endif
    float3 viewDirWS                : TEXCOORD5;

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    float3 viewDirTS                : TEXCOORD8;
#endif

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif

    half3 viewDirWS = SafeNormalize(input.viewDirWS);
#if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
#else
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}

half3 DirectKajiyaSpecular(half3 bitangent,half3 normalWS, half3 halfAngle, half noise)
{
    half3 T1 = bitangent + (-0.5 + _SpecShift1) * normalWS;
    T1 = normalize(T1);

    half3 T2 = bitangent + (noise + _SpecShift2) * normalWS;
    T2 = normalize(T2);

    half tdoth1 = dot(T1, halfAngle);
    half spec1 = saturate(smoothstep(-1.0, 0, tdoth1) * pow(sqrt(1.0 - tdoth1 * tdoth1), _SpecSmooth1));

    half tdoth2 = dot(T2, halfAngle);
    half spec2 = saturate(smoothstep(-1.0, 0, tdoth2) * pow(sqrt(1.0 - tdoth2 * tdoth2), _SpecSmooth2));

    half3 _SpecColor1_linear = max(_SpecColor1.xyz, half3(0.001, 0.001, 0.001));
    half3 _SpecColor2_linear = max(_SpecColor2.xyz, half3(0.001, 0.001, 0.001));

    half3 specular1 = _SpecColor1_linear * spec1 * _Glossiness1;
    half3 specular2 = _SpecColor2_linear * spec2 * _Glossiness2;
    half3 specular = specular1 + specular2;
    return specular * noise * noise;
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float fur_a = (_FUR_OFFSET / 100.0);
    float3 _Gravity = float3(0.0f, -1.0f, 0.0f);
    float3 direction = _Gravity * _GravityStrength + input.normalOS.rgb * (1.0f - _GravityStrength);

    float3 real_direction = lerp(input.normalOS.rgb, direction, float3(fur_a, fur_a, fur_a));
    float3 offset = real_direction * float3(_FurLength, _FurLength, _FurLength) * float3(fur_a, fur_a, fur_a);

  /*  float4 modelPos = float4(position.xyz + offset, position.w);
    o.gl_Position = mul(mul(unity_MatrixVP, unity_ObjectToWorld), modelPos);*/

    input.positionOS.xyz += offset;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
    output.viewDirWS = viewDirWS;
//#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
//#endif
//#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
//#endif

#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    float fur_a = (_FUR_OFFSET / 100.0);
    float fur_Offset = (fur_a * _FurUVOffset) * 0.1;
    float2 offset = float2(fur_Offset, fur_Offset);
    input.uv = input.uv + offset;
    float2 noiseUV = (input.uv.xy * _NoiseMap_ST.xy + _NoiseMap_ST.zw) + offset;
    float mask = tex2D(_MaskMap, input.uv);
    float noise = tex2D(_NoiseMap, noiseUV);

#if defined(_PARALLAXMAP)
#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = input.viewDirTS;
#else
    half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
#endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
#endif

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    #ifdef _SPECULARHIGHLIGHTS_OFF
        bool specularHighlightsOff = true;
    #else
        bool specularHighlightsOff = false;
    #endif

    BRDFData brdfData;

    // NOTE: can modify alpha
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    BRDFData brdfDataClearCoat = (BRDFData)0;
    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
    half3 globalIllumination = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                        inputData.bakedGI, surfaceData.occlusion,
                                        inputData.normalWS, inputData.viewDirectionWS);

    half3 color = globalIllumination;
    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    half3 radiance = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    #ifndef _SPECULARHIGHLIGHTS_OFF
        //#define UNITY_BRANCH [branch] 在进行if条件语句时使用动态分支进行处理,太多的话有时候会报错。
        [branch] if (!specularHighlightsOff)
        {
            brdf += brdfData.specular * DirectBRDFSpecular(brdfData, inputData.normalWS, mainLight.direction, inputData.viewDirectionWS);
        }
    #endif // _SPECULARHIGHLIGHTS_OFF
     
    half sgn = input.tangentWS.w;      // should be either +1 or -1
    half3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3 halfAngle = normalize(mainLight.direction + inputData.viewDirectionWS);
    brdf += DirectKajiyaSpecular(bitangent, input.normalWS, halfAngle, noise);

    brdf = brdf * radiance;
    color += brdf;

    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                             light,
                                             inputData.normalWS, inputData.viewDirectionWS,
                                             surfaceData.clearCoatMask, specularHighlightsOff);
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += surfaceData.emission;

    half4 final_color = half4(color, surfaceData.alpha);

    final_color.rgb = MixFog(final_color.rgb, inputData.fogCoord);
    final_color.a = OutputAlpha(final_color.a, _Surface);

    float FurMask = lerp(1.0 - mask, mask, step(_FUR_OFFSET, 0.2));
    float alpha = (noise - (fur_a * fur_a + fur_a * FurMask)) * _Thickness;
    float color_a = saturate(alpha);
    float ndotv = 1.0 - dot(normalize(input.normalWS), normalize(input.viewDirWS));
    float color_b = color_a * saturate(ndotv - _Blur);
    float final_alpha = (color_b * mask);

    final_color.a = fur_a == 0 ?  1 : final_alpha;
    //final_color.rgba = fur_a  == 0 ? half4(final_color.rgb, final_color.a) : half4(lerp(final_color.rgb * _OcclusionColor.rgb, final_color.rgb, fur_a), final_color.a);

    final_color.rgba = half4(lerp(final_color.rgb * brdfData.diffuse.rgb, final_color.rgb, fur_a), final_color.a);
    return final_color;
}
