#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform sampler2D u_image;
uniform float u_time;
uniform float u_blurRadius; // 0.0 = crisp, 1.5 = soft underwater

out vec4 fragColor;

// Cheap 3x3 sampling — only 9 texture lookups total (vs 121 for Kuwahara).
// Combines a subtle blur with vignette and chromatic aberration for an
// underwater feel without melting the GPU.
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / u_resolution;
    vec2 texel = 1.0 / u_resolution;
    float r = u_blurRadius;

    // --- 3x3 blur ---
    vec4 blur = vec4(0.0);
    float weightSum = 0.0;

    // Center pixel gets double weight to preserve sharpness
    blur += texture(u_image, uv) * 2.0;
    weightSum += 2.0;

    // 4 cardinal neighbors
    blur += texture(u_image, uv + vec2( r,  0) * texel);
    blur += texture(u_image, uv + vec2(-r,  0) * texel);
    blur += texture(u_image, uv + vec2( 0,  r) * texel);
    blur += texture(u_image, uv + vec2( 0, -r) * texel);
    weightSum += 4.0;

    // 4 diagonal neighbors (half weight — softer contribution)
    float d = r * 0.7;
    blur += texture(u_image, uv + vec2( d,  d) * texel) * 0.5;
    blur += texture(u_image, uv + vec2(-d,  d) * texel) * 0.5;
    blur += texture(u_image, uv + vec2( d, -d) * texel) * 0.5;
    blur += texture(u_image, uv + vec2(-d, -d) * texel) * 0.5;
    weightSum += 2.0;

    blur /= weightSum;

    // --- Mix blurred with original (edge-aware-ish: blur more in flat areas) ---
    vec4 original = texture(u_image, uv);
    float mixFactor = 0.35; // 35% blur, 65% original
    vec4 result = mix(original, blur, mixFactor);

    // --- Vignette: darken edges for depth ---
    float vignette = 1.0 - smoothstep(0.3, 1.3, length(uv - 0.5) * 1.4);
    vignette = mix(0.82, 1.0, vignette);
    result.rgb *= vignette;

    // --- Subtle chromatic aberration (time-driven for living water feel) ---
    float caShift = sin(uv.y * 15.0 + u_time * 0.3) * 0.004;
    vec4 shiftedR = texture(u_image, uv + vec2(caShift, 0.0));
    vec4 shiftedB = texture(u_image, uv - vec2(caShift, 0.0));
    result.r = mix(result.r, shiftedR.r, 0.15);
    result.b = mix(result.b, shiftedB.b, 0.15);

    fragColor = result;
}
