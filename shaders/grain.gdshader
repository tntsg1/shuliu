shader_type canvas_item;
render_mode blend_mul;
// 全屏纸纹 / 漆面颗粒 + 暗角：乘法叠加在整个画面上（哑光质感的关键）

uniform float strength = 0.10;
uniform float fiber = 1.0;      // 亮色纸纤维，暗色为 0
uniform float vignette = 0.18;
uniform vec4 tint : source_color = vec4(1.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 fc = FRAGCOORD.xy;
	float g = hash(floor(fc)) - 0.5;
	float blot = noise(fc / 90.0) * 0.6 + noise(fc / 23.0) * 0.4;
	// 纸纤维：拉长的噪声
	float fib = noise(vec2(fc.x / 3.0, fc.y / 40.0)) * noise(vec2(fc.x / 41.0 + 3.0, fc.y / 2.5));
	float v = 1.0 - strength * (g * 0.55 + (blot - 0.5) * 0.9) - fiber * strength * smoothstep(0.35, 0.6, fib) * 0.6;
	vec2 uv = SCREEN_UV - 0.5;
	v *= 1.0 - vignette * smoothstep(0.35, 0.85, length(uv * vec2(1.0, 0.9)));
	COLOR = vec4(tint.rgb * v, 1.0);
}
