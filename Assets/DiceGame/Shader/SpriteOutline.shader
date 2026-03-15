Shader "Custom/SpriteOutline2D"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (1,0,0,1)
        _OutlineSize ("Outline Size (px)", Range(0,16)) = 1
        _OutlinePulseSpeed ("Outline Pulse Speed", Range(0,10)) = 3
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
            float4 _OutlineColor;
            float _OutlineSize;
            float _OutlinePulseSpeed;
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

                float2 texel = _MainTex_TexelSize.xy * _OutlineSize;

                // 取樣周圍 Alpha (8方向 + 額外取樣點讓外框更厚)
                float alpha = 0;
                // 上下左右
                alpha += tex2D(_MainTex, i.uv + float2(texel.x, 0)).a;
                alpha += tex2D(_MainTex, i.uv + float2(-texel.x, 0)).a;
                alpha += tex2D(_MainTex, i.uv + float2(0, texel.y)).a;
                alpha += tex2D(_MainTex, i.uv + float2(0, -texel.y)).a;
                // 對角線
                alpha += tex2D(_MainTex, i.uv + float2(texel.x, texel.y)).a;
                alpha += tex2D(_MainTex, i.uv + float2(-texel.x, texel.y)).a;
                alpha += tex2D(_MainTex, i.uv + float2(texel.x, -texel.y)).a;
                alpha += tex2D(_MainTex, i.uv + float2(-texel.x, -texel.y)).a;

                // 有鄰近像素 → 畫描邊
                if (alpha > 0)
                {
                    // 透明度在 0.5 ~ 1.0 之間來回變化（更明顯的效果）
                    float pulse = sin(_Time.y * _OutlinePulseSpeed);
                    float pulseAlpha = 0.75 + 0.25 * pulse; // 0.5 ~ 1.0
                    float4 outlineCol = _OutlineColor;
                    outlineCol.a = pulseAlpha;
                    return outlineCol;
                }

                return col;
            }
            ENDCG
        }
    }
}
