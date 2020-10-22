Shader "Unlit/RippleEffect"
{
   Properties 
   {
      _InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
      _Frequency("Frequency", Float) = 10
      _Amplitude("Amplitude", Range(0,2)) = 1
      _Phase("Phase", Range(0,1)) = 0.1
   }

   Category 
   {
      Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
      Blend SrcAlpha OneMinusSrcAlpha
      Cull Off Lighting Off ZWrite Off 
      SubShader 
      {
         Pass 
         {
         
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            sampler2D _CameraDepthTexture;
            float _InvFade;
            float _Frequency;
            float _Amplitude;
            float _Phase;
            
            struct appdata_t {
               float4 vertex : POSITION;
               fixed4 color : COLOR;
               float2 texcoord : TEXCOORD0;
            };

            struct v2f {
               float4 vertex : SV_POSITION;
               fixed4 color : COLOR;
               float2 texcoord : TEXCOORD0;
               float4 projPos : TEXCOORD1;
            };
            
            float4 _MainTex_ST;

            v2f vert (appdata_t v)
            {
               v2f o;
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.projPos = ComputeScreenPos (o.vertex);
               o.color = v.color;
               o.texcoord = v.texcoord;
               return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               float2 tapPoint = 0.5;

               float oblique = .25;
               float modifiedTime = _Phase * 10;
               float centerLight = 2;
               float aspectRatio = _ScreenParams.x/_ScreenParams.y;
               float2 distVec = i.texcoord - tapPoint;
               distVec.x *= aspectRatio;
               float dist = length(distVec);
    
               float multiplier = (dist < 1.0) ? ((dist-1.0)*(dist-1.0)) : 0.0;
               float addend = (sin(_Frequency * dist - modifiedTime)+centerLight) * 0.5 * multiplier;
               float2 distOffset = addend * oblique;  
               // ztest
               float zbuf = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
               float partZ = i.projPos.z;
               float zalpha = saturate((zbuf - partZ + 1e-2f)*10000);
               // soft particle
               float fade = saturate (_InvFade * (zbuf-partZ)) * zalpha;
               float alpha = distance(distOffset, 0.0) * 2;

               alpha *= (1-_Phase);
               alpha *= lerp(pow(1-dist*2, 8), 2, _Phase);
               alpha *= _Amplitude;
               
               distOffset *= alpha;
               distOffset *= 0.5;
               distOffset += 0.5;
 
               return float4(distOffset.x, distOffset.y, 1, fade * alpha);
            }
            ENDCG 
         }
      }  
   }
}