#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;       // Ukuran layar
uniform sampler2D uImage; // Gambar 360
uniform float uScale;     // 0.1 = Planet Kecil, 2.0+ = Zoom Masuk
uniform float uRotation;  // Rotasi (spin)

out vec4 fragColor;

const float PI = 3.14159265359;

void main() {
    // 1. Setup Koordinat (Tengah layar jadi 0,0)
    vec2 st = FlutterFragCoord().xy / uSize;
    vec2 uv = st * 2.0 - 1.0;
    
    // Koreksi Aspect Ratio agar planet bulat sempurna di layar HP apapun
    if (uSize.x > uSize.y) {
        uv.x *= uSize.x / uSize.y;
    } else {
        uv.y *= uSize.y / uSize.x;
    }

    // 2. Stereographic Projection Math
    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Rumus inti Tiny Planet:
    // uScale mengontrol seberapa "jauh" kamera dari planet
    float phi = 2.0 * atan(r / uScale); // Latitude
    float theta = angle + uRotation;    // Longitude + Rotasi

    // 3. Mapping ke Equirectangular (Texture UV)
    // Map latitude (phi) dari 0..PI ke 0..1
    // Map longitude (theta) dari -PI..PI ke 0..1
    vec2 texCoord = vec2(
        fract((theta + PI) / (2.0 * PI)), // fract() agar texture ngeloop horizontal
        phi / PI 
    );

    // 4. Handle batas langit (agar tidak glitch di tengah planet atau di pojok langit)
    // Clamp agar tidak mengambil pixel di luar gambar vertikal
    texCoord.y = clamp(texCoord.y, 0.001, 0.999);

    fragColor = texture(uImage, texCoord);
}