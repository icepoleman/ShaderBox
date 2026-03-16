Shader "Unlit/swirl"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SwirlStrength ("Swirl Strength", Range(-10, 10)) = 3
        _SwirlRadius ("Swirl Radius", Range(0.1, 2)) = 0.5
        _CenterX ("Center X", Range(0, 1)) = 0.5
        _CenterY ("Center Y", Range(0, 1)) = 0.5
        [Toggle] _Animate ("Animate", Float) = 0
        _AnimateSpeed ("Animate Speed", Range(0, 5)) = 1
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
            float _SwirlStrength;
            float _SwirlRadius;
            float _CenterX;
            float _CenterY;
            float _Animate;
            float _AnimateSpeed;

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
                float2 center = float2(_CenterX, _CenterY);
                float2 uv = i.uv - center;
                
                // 計算到中心的距離和角度
                float dist = length(uv);
                float angle = atan2(uv.y, uv.x);
                
                // 計算扭曲量 - 越靠近中心扭曲越強
                float swirlAmount = 1.0 - saturate(dist / _SwirlRadius);
                swirlAmount = swirlAmount * swirlAmount; // 平滑過渡
                
                // 動態扭曲
                float strength = _SwirlStrength;
                if (_Animate > 0.5)
                {
                    strength *= sin(_Time.y * _AnimateSpeed);
                }
                
                // 旋轉角度
                angle += swirlAmount * strength;
                
                // 計算新的 UV
                float2 newUV = float2(cos(angle), sin(angle)) * dist + center;
                
                // 取樣貼圖
                fixed4 col = tex2D(_MainTex, newUV);
                
                // 丟棄透明像素
                clip(col.a - 0.01);
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
