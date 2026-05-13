#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform vec4 u_colorTop;
uniform vec4 u_colorBottom;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 st = fragCoord / u_resolution.xy;
    
    // Background gradient
    vec4 bgColor = mix(u_colorTop, u_colorBottom, st.y);
    
    // Scale and aspect ratio correct
    st.x *= u_resolution.x / max(u_resolution.y, 1.0);

    vec2 p = st * 6.0; // scale of the ripples
    float time = u_time * 0.3; // speed of the ripples

    for(int i = 1; i < 5; i++) {
        vec2 newp = p;
        newp.x += 0.6 / float(i) * sin(float(i) * p.y + time + 0.3) + 1.0;
        newp.y += 0.6 / float(i) * cos(float(i) * p.x + time + 0.3) + 1.0;
        p = newp;
    }
    
    float v = cos(p.x + p.y + 1.0) * 0.5 + 0.5;
    
    // Add caustic highlights to the background color
    bgColor.rgb += vec3(v * 0.15); // Add light highlights
    
    fragColor = bgColor;
}
