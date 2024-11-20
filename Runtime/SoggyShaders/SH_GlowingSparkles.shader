Shader "Unlit/testing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            //MY AWESOME SHADER

            static const int nParticles = 150;
            static const float size = 0.001;
            static const float softness = 150.0;
            static const float4 bgColor = float4(0.0,0.0,0.0,1.0);

            float random (int i){
            return frac(sin(float(i)*43.0)*4790.234);   
            }

            float softEdge(float edge, float amt){
                return clamp(1.0 / (clamp(edge, 1.0/amt, 1.0)*amt), 0.,1.);
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float2 uv = i.uv;
                float2 tc = uv;
                
                fixed4 color = bgColor;
                
                //float4 tex = texture(iChannel0, tc);
                float np = float(nParticles);
                for(int i = 0; i< nParticles; i++){
                    float2 tc = uv;
                    
                    float r = random(i);
                    float r2 = random(i+nParticles);
                    float r3 = random(i+nParticles*2);
            
                    tc.x -= sin(_Time.y*1.125 + r*30.0)*r;
                    tc.y -= cos(_Time.y*1.125 + r*40.0)*r2*0.5;
                                
                    float l = length(tc - float2(0.5, 0.5));// - r*size;
                    tc -= float2(0.5, 0.5)*1.0;
                    tc = mul(tc, 2.0) - 1.0;
                    tc = mul(1.0, tc);
                    tc = mul(tc, 0.5 + 0.5);
                    
                    float4 orb = float4(r, r2, r3, softEdge(l, softness));
                    orb.rgb = mul(1.5, orb.rgb); // boost it
                    
                    color = lerp(color, orb, orb.a);
                }
                return color;
            }

            //MY AWESOME SHADER

            ENDCG
        }
    }
}
