Shader "Unlit/SH_HueSaturateBrighten"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HueShiftTex ("HueShiftTexture", 2D) = "white" {}
        _HueShift ("HueShift", Range(0, 10)) = 0
        _Saturation ("Saturation", Range(0, 5)) = 0
        _Brightness ("Brightness", Range(-1, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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

            sampler2D _MainTex, _HueShiftTex;
            float4 _MainTex_ST;

            float _HueShift, _Saturation, _Brightness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float3 HueShift(float3 color, float hueshift)
            {
                float3x3 RGB_YIQ = 
                    float3x3 (0.299, 0.587, 0.114,
                              0.5959, -0.275, -0.3213,
                              0.2115, -0.5227, 0.3112);

                    float3x3 YIQ_RGB = 
                    float3x3 (1, 0.956, 0.619,
                              1, -0.272, -0.647,
                              1, -1.106, 1.702);
                
                    float3 YIQ = mul(RGB_YIQ, color);
                    float hue = atan2(YIQ.z, YIQ.y) + hueshift;
                    float chroma = length(float2(YIQ.y, YIQ.z)) * _Saturation;

                    float Y = YIQ + _Brightness;
                    float I = chroma * cos(hue);
                    float Q = chroma * sin(hue);

                    float3 shiftYIQ = float3(Y, I, Q);

                    float3 newRGB = mul(YIQ_RGB, shiftYIQ);

                return newRGB;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed hue = tex2D(_HueShiftTex, i.uv).r;
                col.rgb = HueShift(col.rgb, _HueShift + hue);
                return col;
            }
            ENDCG
        }
    }
}
