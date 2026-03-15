Shader "Custom/SpriteDistortion2D"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _DistortionStrength ("Distortion Strength", Range(0, 0.1)) = 0.02
        _DistortionSpeed ("Distortion Speed", Range(0, 20)) = 5
        _ChromaticAberration ("Chromatic Aberration", Range(0, 0.05)) = 0.01
        [Toggle] _Enabled ("Effect Enabled", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "PreviewType"="Sprite"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _DistortionStrength;
            float _DistortionSpeed;
            float _ChromaticAberration;
            float _Enabled;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                
                // 效果關閉時直接返回原圖
                if (_Enabled < 0.5)
                {
                    return tex2D(_MainTex, uv) * i.color;
                }
                
                // 扭曲抖動效果
                float time = _Time.y * _DistortionSpeed;
                float2 distortion;
                distortion.x = sin(uv.y * 20 + time) * _DistortionStrength;
                distortion.y = cos(uv.x * 20 + time * 1.3) * _DistortionStrength;
                
                // 加入隨機抖動
                distortion.x += sin(time * 7.5) * _DistortionStrength * 0.5;
                distortion.y += cos(time * 6.3) * _DistortionStrength * 0.5;
                
                float2 distortedUV = uv + distortion;
                
                // RGB 色差分離
                float2 redOffset = float2(_ChromaticAberration, 0);
                float2 blueOffset = float2(-_ChromaticAberration, 0);
                
                // 也加入垂直方向的輕微偏移
                redOffset.y = _ChromaticAberration * 0.5;
                blueOffset.y = -_ChromaticAberration * 0.5;
                
                fixed4 col;
                col.r = tex2D(_MainTex, distortedUV + redOffset).r;
                col.g = tex2D(_MainTex, distortedUV).g;
                col.b = tex2D(_MainTex, distortedUV + blueOffset).b;
                col.a = tex2D(_MainTex, distortedUV).a;
                
                return col * i.color;
            }
            ENDCG
        }
    }
}
