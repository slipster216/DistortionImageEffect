Shader "Hidden/DistortionResolve"
{
	Properties
	{
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
         sampler2D _DistortionRT;
         float _DistortionScale;

			fixed4 frag (v2f i) : SV_Target
			{
            // to improve accuracy, we could bilinear upsample; however, I think it'll be fine without,
            // since errors will cause slight distortion around edges of objects being intersected by the
            // distortion. If this looks bad, we could likely do a soft-edge type effect on the distortion
            // objects to fix it cheaply..
         
            // unpack distortion
			float2 distortionUV = i.uv;
#if UNITY_UV_STARTS_AT_TOP
			distortionUV = float2(distortionUV.x, 1 - distortionUV.y);
#endif
			float2 off = tex2D(_DistortionRT, distortionUV) * 2 - 1;
            // distort UVs
            float2 uv = i.uv + off.xy * _DistortionScale;
            // that's it..
				return tex2D(_MainTex, uv);
			}
			ENDCG
		}
	}
}
