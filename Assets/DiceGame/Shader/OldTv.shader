Shader "Unlit/OldTv"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScanlineCount ("Scanline Count", Range(50, 800)) = 240
        _ScanlineIntensity ("Scanline Intensity", Range(0, 1)) = 0.3
        _ScanlineSpeed ("Scanline Speed", Range(0, 10)) = 2
        _ScanlineWidth ("Scanline Width", Range(0.1, 0.9)) = 0.5
        _Brightness ("Brightness", Range(0.5, 2)) = 1.0
        _Flicker ("Flicker Intensity", Range(0, 0.1)) = 0.02
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
            float _ScanlineCount;
            float _ScanlineIntensity;
            float _ScanlineSpeed;
            float _ScanlineWidth;
            float _Brightness;
            float _Flicker;

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
                // 取樣原始貼圖
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // 丟棄透明像素
                clip(col.a - 0.01);
                
                // 掃描線效果 - 往上移動
                float scanlineY = i.uv.y * _ScanlineCount + _Time.y * _ScanlineSpeed;
                float scanline = frac(scanlineY);
                
                // 使用 smoothstep 產生平滑的線條
                float scanlineMask = smoothstep(0, _ScanlineWidth * 0.5, scanline) * 
                                     smoothstep(_ScanlineWidth, _ScanlineWidth * 0.5, scanline);
                scanlineMask = 1.0 - scanlineMask * _ScanlineIntensity;
                
                // 閃爍效果
                float flicker = 1.0 + sin(_Time.y * 60.0) * _Flicker;
                
                // 套用效果
                col.rgb *= scanlineMask * _Brightness * flicker;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
