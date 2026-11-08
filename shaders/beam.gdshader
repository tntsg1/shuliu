shader_type canvas_item;
// 胶囊观测舱内的束流投影：哑光墨线 + 网点，价值/危险两条通道分开驱动（DECISIONS 视觉硬规则）

uniform vec2 size = vec2(560.0, 300.0);
uniform float value = 0.2;      // 价值通道 0..1：层数、束团、尺寸
uniform float danger = 0.05;    // 危险通道 0..1：偏心、抖动、束晕、红
uniform float lockf = 0.0;      // 锁相 0..1
uniform float pulse = 0.0;      // 每次加速的冲击 1→0
uniform float dissolve = 0.0;   // 丢失消散 0..1
uniform float appear = 1.0;
uniform float flash = 0.0;
uniform float charge = 0.0;      // 蓄力 0..1：轨道收紧、束团加速、核心膨胀       // 冲击闪白 1→0
uniform vec4 flash_col : source_color = vec4(1.0);     // 注入出现 0..1
uniform float seed = 1.0;
uniform vec4 ink : source_color;
uniform vec4 inner0 : source_color;
uniform vec4 inner1 : source_color;
uniform vec4 grid_col : source_color;
uniform vec4 beam_col : source_color;
uniform vec4 beam_hi : source_color;
uniform vec4 danger_col : source_color;
uniform vec4 lock_col : source_color;
uniform float paper_mode = 1.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(vec2(c, s), vec2(-s, c)); }
float sd_stadium(vec2 p, vec2 h) {
	float r = h.y;
	vec2 q = abs(p) - vec2(h.x - r, 0.0);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
float line_a(float d, float w) { float aa = fwidth(d) * 0.9 + 0.35; return 1.0 - smoothstep(w - aa, w + aa, abs(d)); }

void fragment() {
	vec2 px = (UV - 0.5) * size;
	float sd = sd_stadium(px, size * 0.5);
	float mask = 1.0 - smoothstep(-0.8, 0.8, sd);
	float t = TIME;

	// —— 舱内底：坐标纸 ——
	float rr = length(px / (size * 0.5));
	vec3 bg = mix(inner0.rgb, inner1.rgb, smoothstep(0.1, 1.3, rr));
	bg = mix(bg, danger_col.rgb, danger * danger * 0.10 * (1.0 - rr));
	vec2 g1 = abs(fract(px / 12.0 + 0.5) - 0.5) * 12.0;
	vec2 g2 = abs(fract(px / 60.0 + 0.5) - 0.5) * 60.0;
	bg = mix(bg, grid_col.rgb, (1.0 - smoothstep(0.0, 0.8, min(g1.x, g1.y))) * 0.35);
	bg = mix(bg, grid_col.rgb, (1.0 - smoothstep(0.2, 1.3, min(g2.x, g2.y))) * 0.6);

	// —— 锁相六边形磁场网格 ——
	if (lockf > 0.001) {
		vec2 hp = px / 22.0;
		vec2 r = vec2(1.0, 1.7320508);
		vec2 a = mod(hp, r) - r * 0.5;
		vec2 b = mod(hp - r * 0.5, r) - r * 0.5;
		vec2 gv = dot(a, a) < dot(b, b) ? a : b;
		vec2 q = abs(gv);
		float hexd = 0.5 - max(dot(q, normalize(vec2(1.0, 1.7320508))), q.x);
		float edge = 1.0 - smoothstep(0.0, 0.05, hexd);
		float wave = 0.55 + 0.45 * sin(length(px) * 0.05 - t * 9.0);
		bg = mix(bg, lock_col.rgb, edge * lockf * 0.2 * wave);
	}

	vec3 col = bg;
	float jit = danger * danger;
	vec2 c = (vec2(noise(vec2(t * 2.7, seed)), noise(vec2(seed * 3.1, t * 2.9))) - 0.5) * jit * 26.0;
	vec2 p = px - c;
	float A = appear;
	vec3 bc = mix(beam_col.rgb, lock_col.rgb, lockf);

	// —— 危险：束晕杂散纤维 ——
	if (danger > 0.25) {
		float an = atan(p.y, p.x);
		float rad = length(p);
		float s = noise(vec2(an * 9.0 + seed, rad * 0.018 - t * 1.7));
		float s2 = noise(vec2(an * 23.0 - seed, rad * 0.03 + t * 1.1));
		float fib = smoothstep(0.80, 0.86, s) + smoothstep(0.86, 0.9, s2) * 0.7;
		fib *= smoothstep(size.y * 0.75, 30.0, rad) * smoothstep(0.25, 0.9, danger);
		col = mix(col, danger_col.rgb, clamp(fib, 0.0, 1.0) * 0.75 * A);
	}

	// —— 环与束团 ——
	int n = int(1.0 + floor(value * 5.0 + 0.5));
	if (lockf > 0.5) { n = 6; }
	float wl = (0.7 + value * 0.9) * (1.0 + pulse * 0.6);
	for (int i = 0; i < 6; i++) {
		if (i >= n) { break; }
		float fi = float(i);
		float rx = size.x * 0.5 * (0.26 + 0.12 * fi) * (1.0 + pulse * 0.05) * A * (1.0 - 0.17 * charge);
		float asp = mix(0.30 + 0.12 * sin(fi * 2.1 + seed), 0.34, lockf);
		float ry = min(rx * asp, size.y * 0.44);
		float ang = mix(fi * 0.62 + seed + t * 0.05 * (1.0 + fi * 0.3), fi * 3.14159 / 6.0, lockf);
		vec2 q = rot(-ang) * p;
		vec2 qn = q / vec2(rx, ry);
		float L = length(qn);
		vec2 grad = qn / (max(L, 1e-4) * vec2(rx, ry));
		float d = (L - 1.0) / max(length(grad), 1e-4);
		float th = atan(qn.y, qn.x);
		d += jit * (noise(vec2(th * 3.0 + fi * 7.0, t * 2.3)) - 0.5) * 14.0;
		vec3 rc = mix(bc, danger_col.rgb, clamp((danger - 0.45) * 1.6, 0.0, 1.0) * (fi + 1.0) / 6.0);
		col = mix(col, rc, line_a(d, wl * 0.5) * 0.32 * A);

		int kN = lockf > 0.5 ? 6 : 2 + int(value * 4.0);
		float dir = mod(fi, 2.0) < 1.0 ? 1.0 : -1.0;
		float speed = (0.55 + value * 1.4 + lockf * 2.4) * dir * (1.0 + charge * 3.0);
		float trail = 0.35 + value * 0.55 + lockf * 0.5;
		float on_ring = 1.0 - smoothstep(wl * 0.5, wl * 0.5 + 2.6 + value * 2.0, abs(d));
		for (int k = 0; k < 6; k++) {
			if (k >= kN) { break; }
			float ph = fi * 1.31 + float(k) * 6.28318 / float(kN) + t * speed + seed * float(k + 1);
			float dth = mod(th - ph + 3.14159, 6.28318) - 3.14159;
			float behind = -dth * dir;
			float tr = step(0.0, behind) * (1.0 - smoothstep(0.0, trail, behind));
			col = mix(col, rc, tr * on_ring * 0.45 * A);
			vec2 bp = rot(ang) * (vec2(cos(ph), sin(ph)) * vec2(rx, ry));
			float bd = length(p - bp);
			float br = (2.6 + value * 3.6) * (1.0 + pulse * 0.5);
			float aa = fwidth(bd) + 0.4;
			col = mix(col, mix(rc, beam_hi.rgb, 0.35), (1.0 - smoothstep(br - aa, br + aa, bd)) * A);
			col = mix(col, ink.rgb, (1.0 - smoothstep(0.55, 0.55 + aa, abs(bd - br))) * 0.85 * A);
		}
	}

	// —— 核心：网点晕 + 实心芯 + 墨线 ——
	float cd = length(p);
	float cr = (9.0 + value * 22.0) * (1.0 + pulse * 0.35 + charge * 0.45) * A;
	float halo = cr * (2.4 + value * 0.8);
	vec2 cell = mod(px, 6.0) - 3.0;
	float dotr = clamp(1.0 - cd / halo, 0.0, 1.0) * 2.9;
	float dots = 1.0 - smoothstep(dotr - 0.5, dotr + 0.5, length(cell));
	col = mix(col, bc, dots * 0.55 * A);
	float aa2 = fwidth(cd) + 0.4;
	col = mix(col, mix(bc, beam_hi.rgb, 0.6), (1.0 - smoothstep(cr - aa2, cr + aa2, cd)) * A);
	// 芯内排线
	float hatch = step(0.5, fract((px.x + px.y) / 4.0));
	col = mix(col, bc, hatch * (1.0 - smoothstep(cr * 0.45, cr * 0.5, cd)) * 0.35 * A * paper_mode);
	col = mix(col, ink.rgb, (1.0 - smoothstep(0.7, 0.7 + aa2, abs(cd - cr))) * A);
	col = mix(col, ink.rgb, (1.0 - smoothstep(0.5, 0.5 + aa2, abs(cd - cr * 0.5))) * 0.5 * A);
	// 锁相：放射刻线
	if (lockf > 0.01) {
		float an = atan(p.y, p.x);
		float ray = 1.0 - smoothstep(0.0, 0.05, abs(fract(an / 6.28318 * 12.0 + t * 0.4) - 0.5) - 0.44);
		col = mix(col, lock_col.rgb, ray * step(cr * 1.15, cd) * (1.0 - smoothstep(cr * 1.8, cr * 2.6, cd)) * lockf);
	}

	// —— 丢失：纸屑式消散 ——
	if (dissolve > 0.0) {
		float nz = noise(px * 0.06 + seed) * 0.7 + noise(px * 0.25) * 0.3;
		float keep = smoothstep(dissolve - 0.08, dissolve, nz + (1.0 - rr) * 0.15);
		col = mix(mix(bg, danger_col.rgb, (1.0 - keep) * (1.0 - dissolve) * 0.6), col, keep);
	}

	// —— 玻璃：边缘内阴影 + 上沿反光 ——
	col *= 1.0 - smoothstep(-16.0, 0.0, sd) * 0.10;
	float hl = (1.0 - smoothstep(0.0, 6.0, abs(px.y + size.y * 0.36))) * smoothstep(-size.x * 0.42, -size.x * 0.2, px.x) * (1.0 - smoothstep(size.x * 0.1, size.x * 0.3, px.x));
	col = mix(col, vec3(1.0), hl * 0.18);
	col = mix(col, flash_col.rgb, flash * (0.55 + 0.45 * (1.0 - rr)));
	COLOR = vec4(col, mask);
}
