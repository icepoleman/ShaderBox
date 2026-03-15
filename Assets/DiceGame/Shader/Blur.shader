Shader "Custom/UIBlur_5Tap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize ("Blur Size", Range(0, 0.02)) = 0.003
        _Color ("Tint", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float4 _MainTex_ST;
            float _BlurSize;
            float4 _Color;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.color = IN.color * _Color;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;
                float blur = _BlurSize;

                half4 col = 0;

                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2( blur, 0));
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(-blur, 0));
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(0,  blur));
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(0, -blur));

                col /= 5.0;

                col *= IN.color;

                return col;
            }

            ENDHLSL
        }
    }
}