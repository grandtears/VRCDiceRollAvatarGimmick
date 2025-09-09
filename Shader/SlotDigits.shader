Shader "Unlit/VerticalDigitSpin_Colorable_Stable"
{
    Properties{
        _MainTex     ("Digits Sheet (vertical 0-9)", 2D) = "white" {}
        _DigitCount  ("Digit Count", Float) = 10
        _DigitIndex  ("Digit Index (0-9)", Range(0,9)) = 0
        _SpinSpeed   ("Spin Speed (digits/sec)", Float) = 0   // 0=停止, 正=下, 負=上
        _Color       ("Digit Color", Color) = (1,1,1,1)
        [Toggle]_SolidColor ("Use Solid Color (alpha only from texture)", Float) = 0
        _Alpha       ("Alpha", Range(0,1)) = 1
        _PadTexels   ("Edge Pad (texels)", Float) = 0.5
    }

    SubShader{
        Tags{ "Queue"="Transparent" "RenderType"="Transparent" }
        Cull Off Lighting Off ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex; float4 _MainTex_TexelSize;
            float _DigitCount, _DigitIndex, _SpinSpeed, _Alpha, _PadTexels, _SolidColor;
            float4 _Color;

            struct appdata{ float4 vertex:POSITION; float2 uv:TEXCOORD0; };
            struct v2f{ float4 pos:SV_POSITION; float2 uv:TEXCOORD0; };

            v2f vert(appdata v){
                v2f o; o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                // 1行の高さ（0..1）
                float count = max(1.0, _DigitCount);
                float slice = 1.0 / count;

                // にじみ防止（テクセル → UV）
                float padUV = _PadTexels * _MainTex_TexelSize.y;
                float usable = max(0.0, slice - 2.0 * padUV);

                // 停止時は整数インデックスにスナップ（補間/誤差対策）
                float stopIdx = clamp(round(_DigitIndex), 0.0, count - 1.0);

                // スピン時は 0→1→…→count をループ（digits/sec）
                float phaseIdx = frac(_Time.y * (_SpinSpeed / count)) * count;

                // 実際に使う行インデックス
                float idx = (_SpinSpeed != 0.0) ? phaseIdx : stopIdx;

                // 行の“中央”から切り出す（境界跨ぎを避ける）
                // 上から 0,1,2... と並んでいる前提
                float rowCenter = 1.0 - (idx + 0.5) * slice;      // 行中央のV
                // メッシュ内の縦UV(0..1)を usable 範囲に再マッピング（中央基準）
                float y = rowCenter + (i.uv.y - 0.5) * usable;

                // 0..1 に正規化（負方向も考慮）
                y = y - floor(y);

                float2 uv = float2(i.uv.x, y);
                fixed4 tex = tex2D(_MainTex, uv);

                fixed3 rgb = (_SolidColor > 0.5) ? _Color.rgb : tex.rgb * _Color.rgb;
                fixed a   = tex.a * _Alpha * _Color.a;
                return fixed4(rgb, a);
            }
            ENDCG
        }
    }
}
