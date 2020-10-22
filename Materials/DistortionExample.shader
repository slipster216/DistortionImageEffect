// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/DistortionExample"
{
   Properties 
   {
      _InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
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

            float Hash( float2 p )
            {
               float h = dot(p, float2(127.1,311.7));
               return frac(sin(h)*43758.5453123);
            }

            float Noise2D(float2 p )
            {
               float2 i = floor( p );
               float2 f = frac( p );

               float2 u = f*f*(3.0-2.0*f);
          
               float cLowerLeft = Hash( i + float2(0.0,0.0));
               float cLowerRight = Hash( i + float2(1.0,0.0));
               float cUpperLeft = Hash( i + float2(0.0,1.0));
               float cUpperRight = Hash( i + float2(1.0,1.0));
               
      
               float nLower = lerp(cLowerLeft, cLowerRight, u.x);
               float nUpper = lerp(cUpperLeft, cUpperRight, u.x);
               float noise = lerp(nLower, nUpper, u.y);
               return noise;
            }
            
           
            float FBM( float2 p)
            {
               float f = 0;
               float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );
               f  = 0.5000*Noise2D( p ); 
               p = mul(m, p);
               f += 0.2500*Noise2D( p );
               p = mul(m, p);
               f += 0.1250*Noise2D( p );
               return f;
            }


            fixed4 frag (v2f i) : SV_Target
            {
            
               // To tired to open photoshop, just math it.. way too much ALU for mobile,
               // but easy enough to do something similar with textures. Just use a normal map..
               
               float amp = FBM(i.texcoord*5.27 + _Time.y) * 0.5 + 0.5;
               float n1 = FBM(i.texcoord*3 + amp*5);
               float n2 = FBM(i.texcoord*5.421 - amp*5); 
               
               float ramp = distance(i.texcoord, float2(0.5, 0.5))*2;
               ramp *= ramp;
               ramp *= ramp;
               ramp = 1 - ramp;
               amp *= ramp;
               n1 *= amp;
               n2 *= amp;
               n1 = n1 * 2 - 1;
               n2 = n2 * 2 - 1;
               float alpha = ramp + n2;
               float4 normal = float4(normalize(float3(0.5 + n1, 0.5 + n2, 1)), alpha);
               
               // ztest
               float zbuf = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
               float partZ = i.projPos.z;
               float zalpha = saturate((zbuf - partZ + 1e-2f)*10000);
               // soft particle
               float fade = saturate (_InvFade * (zbuf-partZ));
               normal.a *= zalpha * fade;
               // must premultiply alpha, or will not clip correctly!
               normal.rgb *= normal.a;
           
               return normal;
            }
            ENDCG 
         }
      }  
   }
}