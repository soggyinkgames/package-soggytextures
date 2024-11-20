Shader "Unlit/SH_Window"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size ("Size", float) = 1
        _T ("Time", float) = 1 //14
        _Distortion ("Distortion", range(-5, 5)) = 1
        _Blur ("Blur", range(0, 1)) = 1
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
            #define S(a, b, t) smoothstep(a, b, t) //7 define is a search a replace to in this case type s instead of smoothstep

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
            float _Size, _T, _Distortion, _Blur; //14

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float N21(float2 p) 
            {
                p = frac(p*float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            float3 Layer(float2 UV, float t) 
            {
                float2 aspect = float2(2,1); //5 squeeze my box by 2 in the x direction and 1 in the y direction
                float2 uv = UV * _Size * aspect; //1 multiply by larger numver variable, declared at the top, 5 multiply by aspect
                uv.y += t * .25; //13 counteract the movement of rectangles down so the drops are never moving up
                float2 gv = frac(uv) - .5; // 2 take the fractional component of my uv, 4 -.5 to move the origin is in the middle of each box
                float2 id = floor(uv);
    
                float n = N21(id); // 0 1
                t += n * 6.2831; // multiply by at least two pie to get full amount of randomness
                float w = UV.y * 10; // 18 add variable 
                float x = (n - .5)* .8;  // -.4 4
                x += (.4 - abs(x)) * sin(3*w) * pow(sin(w), 6) * .45; //9 move drop by changing xy coordinates, 18 create sin calculation to move drop left to right sin(3x)sin(x)to the power of 6, and multiply by smaller number so it doesnt go outside the box
                float y = -sin(t+sin(t+sin(t)*.5)) * .45 ; //10 move it over time, 11 to keep dot inside box multiply by less than 1, add desmos sin calculation 
                //"-sin(x+sin(x+sin(x).5))"
                y -= (gv.x-x)*(gv.x-x); //17 make drop saggy 
                
                float2 dropPos = (gv - float2(x,y))/aspect; //9 create dropPos var, make it move by subtracting x,y from gv
                float drop = S(.05, .03, length(dropPos)); //8 draw a drop, gv coordinate is the length from the corner of the cox to the centre of the box, divide by aspect to undo the strech on drop
                float2 trailPos = (gv - float2(x,t * .25))/aspect; //15 copy dropPos call it trailPos
                trailPos.y = (frac(trailPos.y * 8) - .5 )/ 8; // 16 frac will slice space into diff boxes, divide by 8 to remove distorsion, minus .5 to move dot up
                float trail = S(.03, .01, length(trailPos)); //15 call this trail, make trail drops smaller
                float fogTrail = S(-.05, .05, dropPos.y);
                fogTrail *= S(.5, y, gv.y); // 16 add fade to trail drops
                trail *= fogTrail;
                fogTrail *= S(.05, .04, abs(dropPos.x));
    
                // col += fogTrail * .5;
                // col += trail; // visualise trail drops
                // col += drop; //8 see drop
    
                // col *= 0; col.rg += dropPos;
                float2 offs = drop* dropPos + trail * trailPos;
                // if(gv.x>.48 || gv.y>.49) col = float4(1,0,0,1); //6 make red box outline on all boxes
                
                return float3(offs, fogTrail);
            }
            fixed4 frag (v2f i) : SV_Target
            {
                float t = fmod(_Time.y + _T, 7200); // create time var, 14 expose _T time var, reset every two hours by adding fmod
                float4 col = 0;

                float3 drops = Layer(i.uv, t);
                drops += Layer(i.uv*1.23+7.54, t);
                drops += Layer(i.uv*1.35+1.54, t);
                drops += Layer(i.uv*1.57-7.54, t);
                
                float blur = _Blur * 7 * (1 - drops.z);
                col = tex2Dlod(_MainTex, float4(i.uv + drops.xy * _Distortion, 0, blur)); //todo: keep distorion negative on the exposed range variable so it flips the sky on the drop yay
                // tex2Dlod controls mipmaps
                return col;
            }
            ENDCG
        }
    }
}
