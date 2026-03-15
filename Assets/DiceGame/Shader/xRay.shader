Shader "Unlit/xRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Contrast ("Contrast", Range(0.5, 3)) = 1.5
        _NoiseIntensity ("Noise Intensity", Range(0, 0.2)) = 0.05
        _ColorCold ("Cold Color", Color) = (0, 0, 0.5, 1)
        _ColorMid1 ("Mid Color 1", Color) = (0.5, 0, 0.8, 1)
        _ColorMid2 ("Mid Color 2", Color) = (0.8, 0, 0.2, 1)
        _ColorWarm ("Warm Color", Color) = (1, 0.5, 0, 1)
        _ColorHot ("Hot Color", Color) = (1, 1, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Contrast;
            float _NoiseIntensity;
            float4 _ColorCold;
            float4 _ColorMid1;
            float4 _ColorMid2;
            float4 _ColorWarm;
            float4 _ColorHot;

            // 簡易噪音
            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }

            // 熱像儀顏色映射 (5段漸變)
            fixed3 thermalColor(float t, fixed3 cold, fixed3 mid1, fixed3 mid2, fixed3 warm, fixed3 hot)
            {
                fixed3 c;
                if (t < 0.25)
                {
                    c = lerp(cold, mid1, t / 0.25);
                }
                else if (t < 0.5)
                {
                    c = lerp(mid1, mid2, (t - 0.25) / 0.25);
                }
                else if (t < 0.75)
                {
                    c = lerp(mid2, warm, (t - 0.5) / 0.25);
                }
                else
                {
                    c = lerp(warm, hot, (t - 0.75) / 0.25);
                }
                return c;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // 丟棄透明像素
                clip(col.a - 0.01);
                
                // 轉換為灰階 (模擬溫度/亮度)
                float heat = dot(col.rgb, float3(0.299, 0.587, 0.114));
                
                // 套用對比度
                heat = saturate((heat - 0.5) * _Contrast + 0.5);
                
                // 加入噪點模擬熱像儀噪訊
                float noise = hash(i.uv * 500.0 + _Time.y * 10.0) * 2.0 - 1.0;
                heat = saturate(heat + noise * _NoiseIntensity);
                
                // 映射到熱像儀顏色
                fixed3 thermal = thermalColor(heat, _ColorCold.rgb, _ColorMid1.rgb, _ColorMid2.rgb, _ColorWarm.rgb, _ColorHot.rgb);
                
                UNITY_APPLY_FOG(i.fogCoord, fixed4(thermal, col.a));
                return fixed4(thermal, col.a);
            }
            ENDCG
        }
    }
}
