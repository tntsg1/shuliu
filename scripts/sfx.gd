extends Node
## 音效（自动加载 Sfx）：真实录音，一次性音效走对象池，嗡鸣环境声单独一路

const NAMES := ["btn", "btn2", "hit", "hit_low", "perfect", "ring", "arc", "crackle", "glass", "discharge",
	"boom", "lever", "tick", "paper", "whoosh", "metal", "step"]

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var hum: AudioStreamPlayer
var hum_vol := -80.0
var hum_target := -80.0
var hum_pitch := 1.0
var hum_pitch_target := 1.0
var last := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in NAMES:
		var s = load("res://audio/%s.ogg" % n)
		if s:
			streams[n] = s
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	hum = AudioStreamPlayer.new()
	var hs: AudioStreamOggVorbis = load("res://audio/hum.ogg")
	if hs:
		hs.loop = true
		hum.stream = hs
		hum.volume_db = -80.0
		add_child(hum)
		hum.play()

## 播放：vol 分贝，pitch 音高，rand 随机音高幅度，gap 同名最小间隔（秒）
func play(n: String, vol := 0.0, pitch := 1.0, rand := 0.05, gap := 0.0) -> void:
	if not streams.has(n):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if gap > 0.0 and now - float(last.get(n, -10.0)) < gap:
		return
	last[n] = now
	var p: AudioStreamPlayer = null
	for q in pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = pool[0]
		pool.push_back(pool.pop_front())
	p.stream = streams[n]
	p.volume_db = vol
	p.pitch_scale = maxf(0.05, pitch * (1.0 + randf_range(-rand, rand)))
	p.play()

## 嗡鸣：舱内有束流时响，能级越高越尖，危险越高越响
func set_hum(on: bool, energy := 1, danger := 0.0, locked := false) -> void:
	hum_target = (-17.0 + danger * 7.0 + (3.0 if locked else 0.0)) if on else -60.0
	hum_pitch_target = 0.82 + energy * 0.035 + (0.25 if locked else 0.0)

func _process(dt: float) -> void:
	var rdt := dt / maxf(Engine.time_scale, 0.01)
	hum_vol = lerpf(hum_vol, hum_target, 1.0 - exp(-4.0 * rdt))
	hum_pitch = lerpf(hum_pitch, hum_pitch_target, 1.0 - exp(-6.0 * rdt))
	if hum:
		hum.volume_db = hum_vol
		hum.pitch_scale = hum_pitch
