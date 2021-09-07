#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define TexTransform0 float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

struct appdata
{
    float4 position : POSITION;
    float4 texcoord0 : TEXCOORD0;
    float4 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct v2f
{
    float4 gl_Position : SV_POSITION;
    float4 position_ws : TEXCOORD0;
    float4 uv : TEXCOORD1;
    float3 normal_ws : TEXCOORD2;
    float3 tangent_ws : TEXCOORD3;
    float3 binormal_ws : TEXCOORD4;
};

uniform float _FurLength;
uniform float _GravityStrength;

uniform float4 u_dir_light_attr[5];
uniform float light_strength_mod;
uniform float4 AddColor;
uniform float FurUVTilling;
uniform float FurUVOffset;
uniform float4 _SpecColor1;
uniform float4 _SpecColor2;
uniform float _SpecShift1;
uniform float _SpecShift2;
uniform float _SpecSmooth1;
uniform float _SpecSmooth2;
uniform float _Glossiness1;
uniform float _Glossiness2;
uniform float4 _OcclusionColor;
uniform float _FresnelLV;
uniform float _Thickness;
uniform float _LightFilter;
uniform float _Blur;
uniform float _FurLightExposure;
 
sampler2D _NoiseMap; float4 _NoiseMap_ST;
sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _MaskMap; float4 _MaskMap_ST;

uniform float4 _u_dir_light_attr_0;
uniform float4 _u_dir_light_attr_1;
uniform float4 _u_dir_light_attr_2;
uniform float4 _u_dir_light_attr_3;
uniform float4 _u_dir_light_attr_4;

float _FUR_OFFSET;

v2f vert(appdata v)
{
    v2f o;
    float4 position = v.position;
    float4 texcoord0 = v.texcoord0;
    float4 normal = v.normal;
    float4 tangent = v.tangent;

    float fur_a = (_FUR_OFFSET / 100.0);
    float3 _Gravity = float3(0.0f, -1.0f, 0.0f);
    float3 direction = _Gravity * _GravityStrength + normal.rgb * (1.0f - _GravityStrength);

    float3 real_direction = lerp(normal.rgb, direction, float3(fur_a, fur_a, fur_a));
    float3 offset = real_direction * float3(_FurLength, _FurLength, _FurLength) * float3(fur_a, fur_a, fur_a);

    float4 modelPos = float4(position.xyz + offset, position.w);

    o.gl_Position = mul(mul(unity_MatrixVP, unity_ObjectToWorld), modelPos);

    o.position_ws = mul(unity_ObjectToWorld, modelPos);
    float3 world_Normal = normalize(mul((float3x3)unity_ObjectToWorld, normal.rgb));
    float3 world_Tangent = normalize(mul((float3x3)unity_ObjectToWorld, tangent.xyz));
    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    half3 world_Binormal = cross(world_Normal, world_Tangent) * tangentSign;
    //float tangentW = step(length(tangent.xyz), 1) * 2 - 1;
   //half3 world_Binormal = cross(world_Normal, world_Tangent) * float3(tangentW, tangentW, tangentW);

    o.normal_ws = world_Normal;
    o.tangent_ws = world_Tangent;
    o.binormal_ws = world_Binormal;

    float4 texTransform = mul(TexTransform0, float4(texcoord0.xy, 1, 0));
    o.uv = float4(texTransform.x, texTransform.y, 0, 0);
    return o;
}

half4 frag(v2f i) : SV_Target
{
    float4 position_ws = i.position_ws;
    float2 uv = i.uv.xy;
    float3 normal_ws = i.normal_ws;
    float3 tangent_ws = i.tangent_ws;
    float3 binormal_ws = i.binormal_ws;

    float fur_a = (_FUR_OFFSET / 100.0);
    float fur_Offset = (fur_a * FurUVOffset) * 0.1;
    float2 offset = float2(fur_Offset, fur_Offset);

    uv = uv + offset;

    float2 noiseUV = (uv * float2(FurUVTilling, FurUVTilling) + offset);
     
    float4 albedo = tex2D(_MainTex, uv);
    float mask = tex2D(_MaskMap, uv);
    float noise = tex2D(_NoiseMap, noiseUV);

    float3 world_Normal = normalize(normal_ws);
    float3 lightDir = normalize(-_u_dir_light_attr_3.xyz);
    float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos.xyz - position_ws.xyz);
     
    float rim = clamp(dot(world_Normal, worldSpaceViewDir), 0.0, 1.0);

    float hight = saturate((world_Normal.y * 0.25) + 0.34999999);
    float3 SH = float3(hight, hight, hight);
    float Occlusion = (fur_a * fur_a + 0.039999999);
    float3 SHL = lerp(_OcclusionColor.xyz * SH, SH, float3(Occlusion, Occlusion, Occlusion));

    float3 lightStrengthMod = float3(light_strength_mod, light_strength_mod, light_strength_mod);
    float3 Lamp0Color = (_u_dir_light_attr_1.xyz / lightStrengthMod);
    float ndotl = saturate(dot(world_Normal, lightDir));
    float DirLightA = saturate(ndotl + _LightFilter + fur_a);
    DirLightA = DirLightA * _FurLightExposure;
    float3 DirLightB = float3(DirLightA, DirLightA, DirLightA) * Lamp0Color;

    float3 T1 = binormal_ws + (-0.5 + _SpecShift1) * world_Normal;
    T1 = normalize(T1);

    float3 T2 = binormal_ws + (noise + _SpecShift2) * world_Normal;
    T2 = normalize(T2);

    float3 H = (lightDir + worldSpaceViewDir);
    H = normalize(H);
    float tdoth1 = dot(T1, H);
    float spec1 = saturate(smoothstep(-1.0, 0, tdoth1) * pow(sqrt(1.0 - tdoth1 * tdoth1), _SpecSmooth1));

    float tdoth2 = dot(T2, H);
    float spec2 = saturate(smoothstep(-1.0, 0, tdoth2) * pow(sqrt(1.0 - tdoth2 * tdoth2), _SpecSmooth2));

    float3 gammga = float3(2.2, 2.2, 2.2);

    albedo.rgb = max(albedo.rgb, float3(0.001, 0.001, 0.001));
    albedo.rgb = pow(albedo.rgb, gammga);

    float3 _SpecColor1_linear = max(_SpecColor1.xyz, float3(0.001, 0.001, 0.001));
    _SpecColor1_linear = pow(_SpecColor1_linear, gammga);

    float3 _SpecColor2_linear = max(_SpecColor2.xyz, float3(0.001, 0.001, 0.001));
    _SpecColor2_linear = pow(_SpecColor2_linear, gammga);

    float3 specular1 = _SpecColor1_linear * spec1 * _Glossiness1;
    float3 specular2 = _SpecColor2_linear * spec2 * _Glossiness2;
    float3 specular = specular1 * noise * noise + specular2 * noise * noise;

    float FurMask = lerp(1.0 - mask, mask, step(_FUR_OFFSET, 0.2));
    float alpha = (noise - (fur_a * fur_a + fur_a * FurMask)) * _Thickness;
    float color_a = saturate(alpha);
    float ndotv = 1.0 - dot(world_Normal, worldSpaceViewDir);
    float color_b = color_a * saturate(ndotv - _Blur);
    float final_alpha = (color_b * mask);

    float3 final_rgb = (specular + albedo.rgb * SHL * DirLightB);
    float4 final_color = float4(final_rgb.rgb, final_alpha) * AddColor;
    return final_color;
}