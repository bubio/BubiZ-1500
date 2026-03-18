//
//  Display.metal
//  BubiZ-1500
//
//  Created by 太田誠司 on 2026/02/14.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct DisplayParams {
    uint scanlineEnabled;
    uint sourceHeight;
    float backingScale;
    uint filterType;       // 0=None, 1=RGB(CPU), 2=CRT(Metal), 3=NTSC
    float textureWidth;
    float textureHeight;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                               constant float4 *vertices [[buffer(0)]]) {
    VertexOut out;
    float4 v = vertices[vertexID];
    out.position = float4(v.xy, 0.0, 1.0);
    out.texCoord = v.zw;
    return out;
}

// --- NTSC Composite Video helpers ---

// RGB to YIQ color space conversion
float3 rgb2yiq(float3 rgb) {
    return float3(
        dot(rgb, float3(0.299,  0.587,  0.114)),   // Y (luminance)
        dot(rgb, float3(0.596, -0.274, -0.322)),    // I (in-phase)
        dot(rgb, float3(0.211, -0.523,  0.312))     // Q (quadrature)
    );
}

// YIQ to RGB color space conversion
float3 yiq2rgb(float3 yiq) {
    return float3(
        dot(yiq, float3(1.0,  0.956,  0.621)),
        dot(yiq, float3(1.0, -0.272, -0.647)),
        dot(yiq, float3(1.0, -1.106,  1.703))
    );
}

// Encode a single texel as NTSC composite signal
float encodeComposite(float3 rgb, float phase) {
    float3 yiq = rgb2yiq(rgb);
    return yiq.x + yiq.y * cos(phase) + yiq.z * sin(phase);
}

// NTSC subcarrier period in texels
// ~3.6 texels/cycle gives authentic dot crawl patterns
constant float NTSC_CARRIER_PERIOD = 3.545;

// FIR lowpass filter taps (9-tap windowed sinc, cutoff ~0.15 normalized)
// Used to separate luma from modulated chroma
constant int FIR_HALF_TAPS = 4;
constant float FIR_LUMA_WEIGHTS[9] = {
    0.015, 0.065, 0.13, 0.19, 0.20, 0.19, 0.13, 0.065, 0.015
};
// Narrower bandpass for chroma (tighter bandwidth as in real NTSC)
constant float FIR_CHROMA_WEIGHTS[9] = {
    0.02, 0.06, 0.12, 0.18, 0.24, 0.18, 0.12, 0.06, 0.02
};

// --- CRT Filter helpers ---

// Barrel distortion for CRT curvature
float2 barrelDistortion(float2 uv, float strength) {
    float2 centered = uv - 0.5;
    float r2 = dot(centered, centered);
    float2 distorted = centered * (1.0 + strength * r2);
    return distorted + 0.5;
}

// Shadow mask pattern - simulates RGB phosphor triads
float3 shadowMask(float2 fragPos, float scale) {
    // 3-pixel wide RGB phosphor pattern
    int px = int(fragPos.x / scale);
    int phase = px % 3;

    float3 mask;
    if (phase == 0) {
        mask = float3(1.0, 0.25, 0.25);   // Red phosphor
    } else if (phase == 1) {
        mask = float3(0.25, 1.0, 0.25);   // Green phosphor
    } else {
        mask = float3(0.25, 0.25, 1.0);   // Blue phosphor
    }
    return mask;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                texture2d<float> tex [[texture(0)]],
                                sampler s [[sampler(0)]],
                                constant DisplayParams &params [[buffer(0)]]) {

    // --- CRT Filter (filterType == 2) ---
    if (params.filterType == 2) {
        float2 uv = in.texCoord;

        // Barrel distortion (CRT curvature)
        float2 distUV = barrelDistortion(uv, 0.06);

        // Out-of-bounds check: black outside the curved screen
        if (distUV.x < 0.0 || distUV.x > 1.0 || distUV.y < 0.0 || distUV.y > 1.0) {
            return float4(0.0, 0.0, 0.0, 1.0);
        }

        float2 texSize = float2(params.textureWidth, params.textureHeight);

        // --- Phosphor diffusion: soft base image (CRT never has sharp pixels) ---
        float2 texelSize = 1.0 / texSize;

        // Gaussian-like 3x3 weighted blur for phosphor softness
        float3 c  = tex.sample(s, distUV).rgb;
        float3 l  = tex.sample(s, distUV + float2(-texelSize.x, 0.0)).rgb;
        float3 r  = tex.sample(s, distUV + float2( texelSize.x, 0.0)).rgb;
        float3 u  = tex.sample(s, distUV + float2(0.0, -texelSize.y)).rgb;
        float3 d  = tex.sample(s, distUV + float2(0.0,  texelSize.y)).rgb;
        float3 ul = tex.sample(s, distUV + float2(-texelSize.x, -texelSize.y)).rgb;
        float3 ur = tex.sample(s, distUV + float2( texelSize.x, -texelSize.y)).rgb;
        float3 dl = tex.sample(s, distUV + float2(-texelSize.x,  texelSize.y)).rgb;
        float3 dr = tex.sample(s, distUV + float2( texelSize.x,  texelSize.y)).rgb;

        // Soft base: weighted average (phosphor diffusion)
        float3 rgb = c  * 0.40
                   + (l + r + u + d) * 0.10
                   + (ul + ur + dl + dr) * 0.05;

        // --- Bloom / glow: bright areas bleed further out ---
        float3 far_l  = tex.sample(s, distUV + float2(-texelSize.x * 2.0, 0.0)).rgb;
        float3 far_r  = tex.sample(s, distUV + float2( texelSize.x * 2.0, 0.0)).rgb;
        float3 far_u  = tex.sample(s, distUV + float2(0.0, -texelSize.y * 2.0)).rgb;
        float3 far_d  = tex.sample(s, distUV + float2(0.0,  texelSize.y * 2.0)).rgb;

        // Bloom intensity scales with pixel brightness (bright areas glow more)
        float brightness = dot(c, float3(0.299, 0.587, 0.114));
        float bloomStr = smoothstep(0.1, 0.8, brightness) * 0.35;
        float3 bloom = (l + r + u + d) * 0.15 + (far_l + far_r + far_u + far_d) * 0.06;
        bloom *= bloomStr;
        rgb += bloom;

        // --- Shadow mask (RGB phosphor triads) ---
        float scale = params.backingScale;
        float3 mask = shadowMask(in.position.xy, scale);
        rgb *= mix(float3(1.0), mask, 0.45);

        // --- Scanlines: screen-space based ---
        float rowInBand = fract(in.position.y / scale * 0.5);
        float scanline = 1.0 - 0.25 * smoothstep(0.3, 0.5, rowInBand) * smoothstep(0.7, 0.5, rowInBand);
        rgb *= scanline;

        // --- Vignette: darken edges ---
        float2 vig = (uv - 0.5) * 2.0;
        float vigAmount = 1.0 - dot(vig, vig) * 0.18;
        vigAmount = clamp(vigAmount, 0.0, 1.0);
        rgb *= vigAmount;

        // --- Phosphor warmth: slight warm color shift like real CRT ---
        rgb *= float3(1.08, 1.02, 0.95);

        // Brightness compensation
        rgb *= 1.3;

        return float4(clamp(rgb, 0.0, 1.0), 1.0);
    }

    // --- NTSC Composite Video Filter (filterType == 3) ---
    if (params.filterType == 3) {
        float2 uv = in.texCoord;
        float2 texSize = float2(params.textureWidth, params.textureHeight);
        float texelW = 1.0 / texSize.x;

        // Current texel position in source pixels
        float pixelX = uv.x * texSize.x;
        float scanline = uv.y * texSize.y;

        // --- Encode & decode NTSC composite signal ---
        // Phase alternates per scanline (half-cycle offset) to produce dot crawl
        float phaseBase = 2.0 * M_PI_F / NTSC_CARRIER_PERIOD;
        float scanlinePhase = M_PI_F * scanline;

        // Accumulate luma (lowpassed composite) and chroma (demodulated I/Q)
        float lumaSum = 0.0;
        float iSum = 0.0;
        float qSum = 0.0;
        float3 centerRGB = float3(0.0);

        for (int i = -FIR_HALF_TAPS; i <= FIR_HALF_TAPS; i++) {
            float2 sampleUV = float2(uv.x + float(i) * texelW, uv.y);
            float3 sampleRGB = tex.sample(s, sampleUV).rgb;

            // Retain center pixel for ringing approximation
            if (i == 0) centerRGB = sampleRGB;

            float samplePixelX = pixelX + float(i);
            float phase = phaseBase * samplePixelX + scanlinePhase;

            // Encode to composite: Y + I*cos(phase) + Q*sin(phase)
            float composite = encodeComposite(sampleRGB, phase);

            int idx = i + FIR_HALF_TAPS;

            // Luma: lowpass the composite signal directly
            lumaSum += composite * FIR_LUMA_WEIGHTS[idx];

            // Chroma: demodulate by multiplying with carrier, then lowpass
            iSum += composite * cos(phase) * 2.0 * FIR_CHROMA_WEIGHTS[idx];
            qSum += composite * sin(phase) * 2.0 * FIR_CHROMA_WEIGHTS[idx];
        }

        // --- Reconstruct YIQ and convert back to RGB ---
        float3 yiq = float3(lumaSum, iSum, qSum);

        // --- Subtle color fringing at sharp edges (ringing approximation) ---
        // Blend decoded luma with original for slight sharpness
        float3 centerYIQ = rgb2yiq(centerRGB);
        yiq.x = mix(yiq.x, centerYIQ.x, 0.15);
        float3 rgb = yiq2rgb(yiq);

        // --- Scanlines ---
        if (params.scanlineEnabled != 0) {
            float scale = params.backingScale;
            float rowInBand = fract(in.position.y / scale * 0.5);
            float sl = 1.0 - 0.3 * smoothstep(0.3, 0.5, rowInBand) * smoothstep(0.7, 0.5, rowInBand);
            rgb *= sl;
        }

        return float4(clamp(rgb, 0.0, 1.0), 1.0);
    }

    // --- Default / RGB filter path ---
    float4 color = tex.sample(s, in.texCoord);
    float3 rgb = color.rgb;

    // RGBフィルター(filterType==1)はCPU側で独自のスキャンライン処理を持つため
    // GPU側のスキャンラインはフィルター無し(filterType==0)の時のみ適用
    if (params.scanlineEnabled != 0 && params.filterType == 0) {
        int row = int(in.position.y / params.backingScale);
        if (row % 2 == 1) {
            rgb = float3(0.0);
        }
    }

    return float4(rgb, 1.0);
}
