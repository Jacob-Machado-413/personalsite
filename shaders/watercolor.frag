#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_wobble;
uniform float u_granulation;
uniform float u_blackLift;
uniform sampler2D u_image;

out vec4 fragColor;

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / u_resolution;
    vec2 texel = 1.0 / u_resolution;

    // Wash edges wander off the geometry. Same layered-sine idiom as water.frag.
    vec2 p = uv * 4.0;
    float t = u_time * 0.08;
    vec2 drift = vec2(
        sin(p.y * 3.0 + t) + 0.5 * sin(p.y * 7.0 - t * 1.3),
        cos(p.x * 3.0 - t) + 0.5 * cos(p.x * 6.0 + t * 1.1)
    );
    vec2 wobbled = uv + drift * texel * u_wobble;

    vec3 base = texture(u_image, wobbled).rgb;

    // Pigment settles into bands, softened back toward the original so the
    // washes have gradients inside them rather than hard steps.
    vec3 banded = floor(base * 6.0 + 0.5) / 6.0;
    vec3 wash = mix(base, banded, 0.55);

    // Lift the black point: the lowest band lands on an exact multiple of 1/6,
    // which crushes the deep end of the water darker than the gradient ever was.
    wash = mix(vec3(u_blackLift), vec3(1.0), wash);

    vec3 pigment = wash;

    // Paper tooth, stronger where the pigment is thick.
    float grain = valueNoise(fragCoord * 0.9) * 0.6
                + valueNoise(fragCoord * 2.7) * 0.4;
    float density = 1.0 - luma(pigment);
    pigment *= 1.0 - (grain - 0.5) * u_granulation * (0.35 + density);

    fragColor = vec4(clamp(pigment, 0.0, 1.0), 1.0);
}
