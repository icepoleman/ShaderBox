Shader "Unlit/OldGame"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            // make fog work
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

            // Game Boy 4-color green palette
            static const fixed3 GB_COLORS[4] = {
                fixed3(0.059, 0.220, 0.059),  // Darkest:  #0f380f
                fixed3(0.188, 0.384, 0.188),  // Dark:     #306230
                fixed3(0.545, 0.674, 0.059),  // Light:    #8bac0f
                fixed3(0.608, 0.737, 0.059)   // Lightest: #9bbc0f
            };

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
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // discard transparent pixels
                clip(col.a - 0.01);
                
                // convert to grayscale using luminance
                float gray = dot(col.rgb, float3(0.299, 0.587, 0.114));
                
                // quantize to 4 levels and select Game Boy color
                int index = (int)(saturate(gray) * 3.99);
                fixed3 gbColor = GB_COLORS[index];
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, fixed4(gbColor, col.a));
                return fixed4(gbColor, col.a);
            }
            ENDCG
        }
    }
}
