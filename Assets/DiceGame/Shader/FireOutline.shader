Shader "Custom/FireOutline2D"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _FireColorInner ("Fire Color Inner", Color) = (1,1,0,1) // 黃色
        _FireColorOuter ("Fire Color Outer", Color) = (1,0.3,0,1) // 橘色
        _OutlineSize ("Outline Size (px)", Range(0,16)) = 2
        _FireSpeed ("Fire Speed", Range(0,20)) = 8
        _FireIntensity ("Fire Intensity", Range(0,2)) = 1
        _FlickerSpeed ("Flicker Speed", Range(0,30)) = 15
        _DistortAmount ("Distort Amount", Range(0,0.1)) = 0.02
        _DistortSpeed ("Distort Speed", Range(0,10)) = 3
        [Toggle] _OutlineEnabled ("Outline Enabled", Float) = 1
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
            float4 _FireColorInner;
            float4 _FireColorOuter;
            float _OutlineSize;
            float _FireSpeed;
            float _FireIntensity;
            float _FlickerSpeed;
            float _DistortAmount;
            float _DistortSpeed;
            float _OutlineEnabled;
            float4 _MainTex_TexelSize;

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

            // 簡易噪音函數
            float hash(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                
                float a = hash(i);
                float b = hash(i + float2(1.0, 0.0));
                float c = hash(i + float2(0.0, 1.0));
                float d = hash(i + float2(1.0, 1.0));
                
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            // 分形噪音
            float fbm(float2 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                for (int i = 0; i < 3; i++)
                {
                    value += amplitude * noise(p);
                    p *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // 原本有圖就直接畫
                if (col.a > 0)
                    return col;

                // 外框開關關閉時直接返回
                if (_OutlineEnabled < 0.5)
                    return col;

                // UV 扭曲效果
                float2 distortUV = i.uv * 8.0;
                distortUV.y -= _Time.y * _DistortSpeed;
                float2 distort = float2(
                    noise(distortUV) - 0.5,
                    noise(distortUV + float2(43.0, 17.0)) - 0.5
                ) * _DistortAmount;

                float2 texel = _MainTex_TexelSize.xy * _OutlineSize;

                // 取樣周圍 Alpha (8方向)，加入扭曲偏移
                float alpha = 0;
                // 上下左右
                alpha += tex2D(_MainTex, i.uv + float2(texel.x, 0) + distort).a;
                alpha += tex2D(_MainTex, i.uv + float2(-texel.x, 0) + distort).a;
                alpha += tex2D(_MainTex, i.uv + float2(0, texel.y) + distort).a;
                alpha += tex2D(_MainTex, i.uv + float2(0, -texel.y) + distort).a;
                // 對角線
                alpha += tex2D(_MainTex, i.uv + float2(texel.x, texel.y) + distort).a;
                alpha += tex2D(_MainTex, i.uv + float2(-texel.x, texel.y) + distort).a;
                alpha += tex2D(_MainTex, i.uv + float2(texel.x, -texel.y) + distort).a;
                alpha += tex2D(_MainTex, i.uv + float2(-texel.x, -texel.y) + distort).a;

                // 有鄰近像素 → 畫火焰描邊
                if (alpha > 0)
                {
                    // 火焰噪音效果
                    float2 fireUV = i.uv * 5.0;
                    fireUV.y -= _Time.y * _FireSpeed; // 火焰向上飄動
                    
                    float fireNoise = fbm(fireUV);
                    
                    // 額外扭曲層讓火焰形狀更不規則
                    float2 fireUV2 = i.uv * 3.0 + float2(_Time.y * 0.5, -_Time.y * _FireSpeed * 0.7);
                    float fireNoise2 = fbm(fireUV2);
                    fireNoise = fireNoise * 0.6 + fireNoise2 * 0.4;
                    
                    // 閃爍效果
                    float flicker = sin(_Time.y * _FlickerSpeed + i.uv.x * 10.0) * 0.5 + 0.5;
                    flicker = lerp(0.7, 1.0, flicker);
                    
                    // 根據噪音混合內外火焰顏色
                    float4 fireColor = lerp(_FireColorOuter, _FireColorInner, fireNoise);
                    
                    // 計算火焰強度
                    float intensity = (fireNoise * 0.5 + 0.5) * _FireIntensity * flicker;
                    
                    // 火焰邊緣隨機消失效果
                    float edgeFade = saturate(fireNoise2 * 2.0);
                    
                    // 透明度變化讓火焰邊緣更自然
                    float fireAlpha = saturate(intensity * 1.2 * edgeFade);
                    
                    fireColor.a = fireAlpha;
                    fireColor.rgb *= intensity;
                    
                    return fireColor;
                }

                return col;
            }
            ENDCG
        }
    }
}
