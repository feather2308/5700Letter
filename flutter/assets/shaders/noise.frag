#version 460 core

precision highp float;

// Flutter automatically injects `u_resolution` (vec2) when using FragmentProgram
layout(location = 0) uniform vec2 u_resolution;
layout(location = 1) uniform float u_time;     // 시간 흐름
layout(location = 2) uniform float u_intensity; // 노이즈 강도

// 해시 함수 – 매우 빠르고 가벼움
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // 픽셀 단위 무작위 노이즈값
    float noise = hash(uv * u_time * 500.0);

    // 강도 적용
    float finalNoise = noise * u_intensity;

    // 흰색 노이즈 출력
    gl_FragColor = vec4(vec3(finalNoise), finalNoise);
}
