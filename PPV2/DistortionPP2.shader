Shader "Hidden/Custom/DistortionPP2"
{
    HLSLINCLUDE

        #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

        TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
        TEXTURE2D_SAMPLER2D(gDistortionBuffer, sampler_gDistortionBuffer);
	    float _Scale;

        float4 Frag(VaryingsDefault i) : SV_Target
        {
            // unpack distortion
            float2 off = SAMPLE_TEXTURE2D(gDistortionBuffer, sampler_gDistortionBuffer, i.texcoord) * 2 - 1;
            // distort UVs
            float2 uv = i.texcoord + off.xy * _Scale;
            // that's it..
			return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
        }

    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

                #pragma vertex VertDefault
                #pragma fragment Frag

            ENDHLSL
        }
    }
}