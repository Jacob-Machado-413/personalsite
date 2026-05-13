#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform sampler2D u_image;
uniform float u_radius; // Kept so Dart uniform indexes don't shift, though unused for loop bound

out vec4 fragColor;

// Kuwahara filter – constant loop bounds for Impeller compatibility.
// Radius is clamped in Dart before passing (max 5), but the shader also
// clamps internally.  Loop bounds are fixed at [-5,5] so the compiler can
// unroll; the `inRange` check skips samples outside the requested radius.
bool inRange(int i, int j, int R) {
    return i >= -R && i <= R && j >= -R && j <= R;
}

void main() {
    int R = int(u_radius);
    if (R > 5) R = 5;
    if (R < 1) R = 1;

    float n = float((R + 1) * (R + 1));
    vec2 fragCoord = FlutterFragCoord().xy;

    vec3 m[4];
    vec3 s[4];
    for (int k = 0; k < 4; ++k) {
        m[k] = vec3(0.0);
        s[k] = vec3(0.0);
    }

    // Constant loop bounds: -5..5 covers the maximum possible radius.
    // Samples outside the current R are skipped via inRange().
    for (int j = -5; j <= 5; ++j) {
        for (int i = -5; i <= 5; ++i) {
            vec3 c = texture(u_image, (fragCoord + vec2(float(i), float(j))) / u_resolution).rgb;

            // Region 0: [-R, 0] x [-R, 0]
            if (inRange(i, j, R) && i <= 0 && j <= 0) {
                m[0] += c;
                s[0] += c * c;
            }
            // Region 1: [0, R] x [-R, 0]
            if (inRange(i, j, R) && i >= 0 && j <= 0) {
                m[1] += c;
                s[1] += c * c;
            }
            // Region 2: [0, R] x [0, R]
            if (inRange(i, j, R) && i >= 0 && j >= 0) {
                m[2] += c;
                s[2] += c * c;
            }
            // Region 3: [-R, 0] x [0, R]
            if (inRange(i, j, R) && i <= 0 && j >= 0) {
                m[3] += c;
                s[3] += c * c;
            }
        }
    }

    float min_sigma2 = 1e10;
    vec3 outColor = vec3(0.0);

    for (int k = 0; k < 4; ++k) {
        m[k] /= n;
        s[k] = abs(s[k] / n - m[k] * m[k]);
        float sigma2 = s[k].r + s[k].g + s[k].b;
        if (sigma2 < min_sigma2) {
            min_sigma2 = sigma2;
            outColor = m[k];
        }
    }

    fragColor = vec4(outColor, 1.0);
}
