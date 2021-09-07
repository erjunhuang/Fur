#include "UnityCG.cginc"

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat3 float3x3
#define mat4 float4x4
/*#define texture(tex,uv) SAMPLE_TEXTURE2D(tex,sampler_##tex,uv)
#define TextureDefine(name) TEXTURE2D(name);        SAMPLER(sampler_##name)*/
#define texture(tex,uv) tex2D(tex,uv)
#define mix(a,b,c) lerp(a,b,c)
#define world unity_ObjectToWorld
#define wvp UNITY_MATRIX_MVP
#define wv UNITY_MATRIX_MV
#define CameraPos _WorldSpaceCameraPos
#define fract frac
#define game_light_intensity (1/PI)
#define game_light_diffuse _MainLightColor
#define _InverseView UNITY_MATRIX_I_V
#define _ViewMatrix UNITY_MATRIX_V
#define lvp _MainLightWorldToShadow[0]
#define ShadowMap4 _MainLightShadowmapTexture
#define sampler__MainLightShadowmapTexture sampler_MainLightShadowmapTexture
#define FrameTime _Time.y
#define TexTransform0 float4x4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)

#define sam_other0_0 _NoiseMap
#define sam_other1_1 _MainTex
#define sam_other2_2 _MaskMap

/*   TextureDefine(_SamplerDiffuse0);
   TextureDefine(_SampleNORMAL1);
   TextureDefine(_SamplerFlickerNoise2);
   TextureDefine(_SamplerMatcapMix3);
   TextureDefine(SamplerWenluMasks5);
   TextureDefine(SamplerSkinMasks6);
   TextureDefine(_SamplerMasks7);*/

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
    float4 v_texture0 : TEXCOORD1;
    float3 v_texture2 : TEXCOORD2;
    float3 tangent_ws : TEXCOORD3;
    float3 binormal_ws : TEXCOORD4;
};

uniform float _FurLength;
uniform float _GravityStrength;

uniform vec4 u_dir_light_attr[5];
uniform float light_strength_mod;
uniform vec4 AddColor;
uniform float FurUVTilling;
uniform float FurUVOffset;
uniform vec4 _SpecColor1;
uniform vec4 _SpecColor2;
uniform float _SpecShift1;
uniform float _SpecShift2;
uniform float _SpecSmooth1;
uniform float _SpecSmooth2;
uniform float _Glossiness1;
uniform float _Glossiness2;
uniform vec4 _OcclusionColor;
uniform float _FresnelLV;
uniform float _Thickness;
uniform float _LightFilter;
uniform float _Blur;
uniform float _FurLightExposure;
uniform sampler2D sam_other0_0;
uniform sampler2D sam_other1_1;
uniform sampler2D sam_other2_2;

uniform vec4 _u_dir_light_attr_0;
uniform vec4 _u_dir_light_attr_1;
uniform vec4 _u_dir_light_attr_2;
uniform vec4 _u_dir_light_attr_3;
uniform vec4 _u_dir_light_attr_4;

float _FUR_OFFSET;
v2f vert(appdata v)
{
    v2f o;
    float4 position = v.position;
    float4 texcoord0 = v.texcoord0;
    float4 normal = v.normal;
    float4 tangent = v.tangent;

    float local_1 = _FUR_OFFSET;
    float local_2 = 100.0;
    float local_3 = (local_1 / local_2);
    float local_4 = 0.0;
    float local_5 = 1.0;
    float local_6 = (-local_5);
    vec3 local_7 = vec3(local_4, local_6, local_4);
    vec3 local_8 = (local_7 * _GravityStrength);
    vec3 local_9 = normal.xyz;
    float local_11 = (local_5 - _GravityStrength);
    vec3 local_12 = (local_9 * local_11);
    vec3 local_13 = (local_8 + local_12);
    vec3 local_14 = vec3(local_3, local_3, local_3);
    vec3 local_15 = mix(local_9, local_13, local_14);
    vec3 local_16 = vec3(_FurLength, _FurLength, _FurLength);
    vec3 local_17 = (local_15 * local_16);
    vec3 local_18 = vec3(local_3, local_3, local_3);
    vec3 local_19 = (local_17 * local_18);
    vec3 local_20 = position.xyz;
    float local_21 = position.w;
    vec3 local_22 = (local_20 + local_19);
    vec4 local_23 = vec4(local_22.x, local_22.y, local_22.z, local_21);

    //vec4 local_24 = (WorldViewProjection * local_23);
    vec4 local_24 = mul(wvp, local_23);

    (o.gl_Position = local_24);

    //vec4 local_25 = (World * local_23);
    vec4 local_25 = mul(world, local_23);

    (o.position_ws = local_25);

    //mat3 local_26 = mat3(World);
    //vec3 local_27 = (local_26 * local_9);
    mat3 local_26 = (mat3)(world);
    vec3 local_27 = mul(local_26, local_9);

    vec3 local_28 = normalize(local_27);
    (o.v_texture2 = local_28);
    vec2 local_29 = texcoord0.xy;
    vec4 local_31 = vec4(local_29.x, local_29.y, local_5, local_4);
    //vec4 local_32 = (TexTransform0 * local_31);
    vec4 local_32 = mul(TexTransform0, local_31);
    vec2 local_33 = local_32.xy;
    vec4 local_35 = vec4(local_33.x, local_33.y, local_4, local_4);
    (o.v_texture0 = local_35);
    vec3 local_36 = tangent.xyz;

    //vec3 local_38 = (local_26 * local_36);
    vec3 local_38 = mul(local_26, local_36);

    vec3 local_39 = normalize(local_38);
    float local_40 = length(local_36);
    float local_41 = 1.0;
    float local_42 = step(local_40, local_41);
    vec3 local_43 = cross(local_28, local_39);
    float local_44 = 2.0;
    float local_45 = (local_42 * local_44);
    float local_46 = (local_45 - local_41);
    vec3 local_47 = vec3(local_46, local_46, local_46);
    vec3 local_48 = (local_43 * local_47);
    (o.tangent_ws = local_39);
    (o.binormal_ws = local_48);
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    float4 position_ws = i.position_ws;
    float4 v_texture0 = i.v_texture0;
    float3 v_texture2 = i.v_texture2;
    float3 tangent_ws = i.tangent_ws;
    float3 binormal_ws = i.binormal_ws;

    float local_1 = _FUR_OFFSET;
    float local_2 = 100.0;
    float local_3 = (local_1 / local_2);
    vec2 local_4 = v_texture0.xy;
    vec3 local_6 = normalize(v_texture2);

    //int local_7 = 1;
    //vec4 local_8 = u_dir_light_attr[local_7];
    vec4 local_8 = _u_dir_light_attr_1;

    //int local_9 = 3;
    //vec4 local_10 = u_dir_light_attr[local_9];
    vec4 local_10 = _u_dir_light_attr_3;

    vec3 local_11 = local_10.xyz;
    vec3 local_13 = (-local_11);
    vec3 local_14 = normalize(local_13);
    vec3 local_15 = CameraPos.xyz;
    vec3 local_17 = position_ws.xyz;
    vec3 local_19 = (local_15 - local_17);
    vec3 local_20 = normalize(local_19);
    vec3 local_21 = local_8.xyz;
    vec3 local_23 = vec3(light_strength_mod, light_strength_mod, light_strength_mod);
    vec3 local_24 = (local_21 / local_23);
    float local_26 = (local_3 * FurUVOffset);
    float local_27 = 0.1;
    float local_28 = (local_26 * local_27);
    vec2 local_29 = vec2(local_28, local_28);
    vec2 local_30 = (local_4 + local_29);
    vec4 local_31 = texture(sam_other1_1, local_30);
    vec3 local_32 = local_31.xyz;
    vec3 local_34;
    {
    float local_36 = 0.001;
    vec3 local_37 = vec3(local_36, local_36, local_36);
    vec3 local_38 = max(local_32, local_37);
    float local_39 = 2.2;
    vec3 local_40 = vec3(local_39, local_39, local_39);
    vec3 local_41 = pow(local_38, local_40);
    (local_34 = local_41);
    }
    vec2 local_43 = vec2(FurUVTilling, FurUVTilling);
    vec2 local_44 = (local_4 * local_43);
    vec2 local_45 = (local_44 + local_29);
    vec4 local_46 = texture(sam_other0_0, local_45);
    vec4 local_47 = texture(sam_other2_2, local_4);
    float local_48 = local_46.x;
    float local_52 = 1.0;
    float local_53 = local_47.x;
    float local_57 = (local_52 - local_53);
    float local_58 = 0.2;
    float local_59 = step(local_1, local_58);
    float local_60 = mix(local_57, local_53, local_59);
    float local_61 = dot(local_6, local_20);
    float local_62 = clamp(local_61, 0.0, 1.0);
    float local_63 = dot(local_6, local_14);
    float local_64 = clamp(local_63, 0.0, 1.0);
    float local_66 = local_6.y;
    float local_68 = 0.25;
    float local_69 = (local_66 * local_68);
    float local_70 = 0.34999999;
    float local_71 = (local_69 + local_70);
    float local_72 = clamp(local_71, 0.0, 1.0);
    vec3 local_73 = vec3(local_72, local_72, local_72);
    float local_74 = (local_3 * local_3);
    float local_75 = 0.039999999;
    float local_76 = (local_74 + local_75);
    vec3 local_77 = _OcclusionColor.xyz;
    vec3 local_79 = (local_77 * local_73);
    vec3 local_80 = vec3(local_76, local_76, local_76);
    vec3 local_81 = mix(local_79, local_73, local_80);
    float local_89 = (local_64 + _LightFilter);
    float local_90 = (local_89 + local_3);
    float local_91 = clamp(local_90, 0.0, 1.0);
    float local_92 = (local_91 * _FurLightExposure);
    vec3 local_93 = vec3(local_92, local_92, local_92);
    vec3 local_94 = (local_93 * local_24);
    vec3 local_95;
    float local_100 = 0.5;
    float local_101 = (-local_100);
    float local_102 = (local_101 + _SpecShift1);
    vec3 local_103;
    {
    vec3 local_105 = (local_102 * local_6);
    vec3 local_106 = (binormal_ws + local_105);
    vec3 local_107 = normalize(local_106);
    (local_103 = local_107);
    }
    float local_109 = (local_48 + _SpecShift2);
    vec3 local_110;
    {
    vec3 local_112 = (local_109 * local_6);
    vec3 local_113 = (binormal_ws + local_112);
    vec3 local_114 = normalize(local_113);
    (local_110 = local_114);
    }
    float local_116;
    {
    vec3 local_118 = (local_14 + local_20);
    vec3 local_119 = normalize(local_118);
    float local_120 = dot(local_103, local_119);
    float local_121 = 1.0;
    float local_122 = (local_120 * local_120);
    float local_123 = (local_121 - local_122);
    float local_124 = sqrt(local_123);
    float local_125 = (-local_121);
    float local_126 = 0.0;
    float local_127 = smoothstep(local_125, local_126, local_120);
    float local_128 = pow(local_124, _SpecSmooth1);
    float local_129 = (local_127 * local_128);
    float local_130 = clamp(local_129, 0.0, 1.0);
    (local_116 = local_130);
    }
    float local_132;
    {
    vec3 local_134 = (local_14 + local_20);
    vec3 local_135 = normalize(local_134);
    float local_136 = dot(local_110, local_135);
    float local_137 = 1.0;
    float local_138 = (local_136 * local_136);
    float local_139 = (local_137 - local_138);
    float local_140 = sqrt(local_139);
    float local_141 = (-local_137);
    float local_142 = 0.0;
    float local_143 = smoothstep(local_141, local_142, local_136);
    float local_144 = pow(local_140, _SpecSmooth2);
    float local_145 = (local_143 * local_144);
    float local_146 = clamp(local_145, 0.0, 1.0);
    (local_132 = local_146);
    }
    vec3 local_148 = _SpecColor1.xyz;
    vec3 local_150;
    {
    float local_152 = 0.001;
    vec3 local_153 = vec3(local_152, local_152, local_152);
    vec3 local_154 = max(local_148, local_153);
    float local_155 = 2.2;
    vec3 local_156 = vec3(local_155, local_155, local_155);
    vec3 local_157 = pow(local_154, local_156);
    (local_150 = local_157);
    }
    vec3 local_159 = _SpecColor2.xyz;
    vec3 local_161;
    {
    float local_163 = 0.001;
    vec3 local_164 = vec3(local_163, local_163, local_163);
    vec3 local_165 = max(local_159, local_164);
    float local_166 = 2.2;
    vec3 local_167 = vec3(local_166, local_166, local_166);
    vec3 local_168 = pow(local_165, local_167);
    (local_161 = local_168);
    }
    vec3 local_170 = (local_150 * local_116);
    vec3 local_171 = (local_170 * _Glossiness1);
    vec3 local_172 = (local_161 * local_132);
    vec3 local_173 = (local_172 * _Glossiness2);
    vec3 local_174 = (local_171 * local_48);
    vec3 local_175 = (local_174 * local_48);
    vec3 local_176 = (local_173 * local_48);
    vec3 local_177 = (local_176 * local_48);
    vec3 local_178 = (local_175 + local_177);
    (local_95 = local_178);
    float local_179 = (local_3 * local_3);
    float local_180 = (local_3 * local_60);
    float local_181 = (local_180 * local_52);
    float local_182 = (local_179 + local_181);
    float local_183 = (local_48 - local_182);
    float local_184 = (local_183 * _Thickness);
    float local_185 = clamp(local_184, 0.0, 1.0);
    float local_186 = dot(local_6, local_20);
    float local_187 = (local_52 - local_186);
    float local_188 = (local_187 - _Blur);
    float local_189 = clamp(local_188, 0.0, 1.0);
    float local_190 = (local_185 * local_189);
    float local_191 = (local_190 * local_53);
    vec3 local_192 = (local_34 * local_81);
    vec3 local_193 = (local_192 * local_94);
    vec3 local_194 = (local_95 + local_193);
    vec4 local_195 = vec4(local_194.x, local_194.y, local_194.z, local_191);
    vec4 local_196;
    (local_196 = local_195);
    vec4 local_223;
    (local_223 = local_196);
    vec4 local_227 = (local_223 * AddColor);
    //(gFragColor = local_227);
    fixed4 gFragColor = local_227;
    return gFragColor;
}