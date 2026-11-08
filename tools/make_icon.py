"""束流 图标：工程图纸风（米色坐标纸 + 墨线 + 彩色墨水），4 倍超采样后缩到 1024，并生成 Windows .ico
用法: python tools/make_icon.py
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

S = 4096                      # 超采样画布
K = S / 1024.0
def k(v): return v * K

PAPER = (239, 232, 216)
PAPER2 = (247, 242, 230)
GRID = (214, 203, 180)
INK = (43, 42, 40)
EQUIP = (216, 204, 178)
EQUIP_D = (196, 183, 154)
PIPE = (207, 195, 168)
RAMP = [(58, 79, 160), (47, 127, 168), (47, 154, 138), (106, 159, 69), (201, 151, 26)]
RED = (194, 65, 45)
LOCK = (106, 79, 176)

ROOT = Path(__file__).resolve().parent.parent

def stadium(d, cx, cy, hw, hh, **kw):
    d.rounded_rectangle([cx - hw, cy - hh, cx + hw, cy + hh], radius=hh, **kw)

def ellipse_pts(cx, cy, rx, ry, rot, n=400):
    c, s = math.cos(rot), math.sin(rot)
    out = []
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        x, y = rx * math.cos(a), ry * math.sin(a)
        out.append((cx + x * c - y * s, cy + x * s + y * c))
    return out

def main():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # —— 底板：圆角方形纸片 + 投影 ——
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([k(70), k(96), k(970), k(986)], radius=k(190), fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(k(22)))
    img.alpha_composite(shadow)
    d = ImageDraw.Draw(img)
    tile = [k(56), k(56), k(968), k(968)]
    d.rounded_rectangle(tile, radius=k(190), fill=PAPER)
    # 坐标纸网格（裁到圆角内）
    grid = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    step = k(32)
    x = tile[0]
    i = 0
    while x < tile[2]:
        w = int(k(3)) if i % 5 == 0 else int(k(1.4))
        gd.line([(x, tile[1]), (x, tile[3])], fill=GRID + (255,), width=w)
        gd.line([(tile[0], x), (tile[2], x)], fill=GRID + (255,), width=w)
        x += step
        i += 1
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(tile, radius=k(190), fill=255)
    img.paste(grid, (0, 0), Image.composite(grid, Image.new("RGBA", (S, S)), mask).split()[3])
    d = ImageDraw.Draw(img)
    cx, cy = k(512), k(540)
    # —— 束流管：从两侧伸出纸边 ——
    d.rectangle([tile[0] + k(10), cy - k(34), tile[2] - k(10), cy + k(34)], fill=PIPE, outline=INK, width=int(k(10)))
    d.rectangle([tile[0] + k(10), cy - k(22), tile[2] - k(10), cy - k(12)], fill=(240, 235, 222))
    for fx in (150, 874):
        d.rectangle([k(fx - 16), cy - k(56), k(fx + 16), cy + k(56)], fill=EQUIP_D, outline=INK, width=int(k(9)))
    # —— 胶囊观测舱：金属外环 + 玻璃 ——
    hw, hh = k(330), k(205)
    stadium(d, cx, cy, hw + k(34), hh + k(34), fill=EQUIP, outline=INK, width=int(k(12)))
    stadium(d, cx, cy, hw, hh, fill=PAPER2, outline=INK, width=int(k(10)))
    # 舱内坐标纸
    inner = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    idr = ImageDraw.Draw(inner)
    st = k(24)
    yy = cy - hh
    while yy < cy + hh:
        idr.line([(cx - hw, yy), (cx + hw, yy)], fill=GRID + (200,), width=int(k(2)))
        yy += st
    xx = cx - hw
    while xx < cx + hw:
        idr.line([(xx, cy - hh), (xx, cy + hh)], fill=GRID + (200,), width=int(k(2)))
        xx += st
    # 轨道（三层，颜色沿能级色阶）
    orbits = [(250, 0.36, -0.42, RAMP[0]), (285, 0.34, 0.38, RAMP[2]), (215, 0.40, 1.25, RAMP[3])]
    for rx, asp, rot, col in orbits:
        pts = ellipse_pts(cx, cy, k(rx), k(rx * asp), rot)
        idr.line(pts, fill=col + (255,), width=int(k(16)), joint="curve")
    # 束团（带拖尾）
    for (rx, asp, rot, col), a0 in zip(orbits, (0.6, 3.4, 5.2)):
        for t in range(14):
            a = a0 - t * 0.06
            c, s = math.cos(rot), math.sin(rot)
            x, y = k(rx) * math.cos(a), k(rx * asp) * math.sin(a)
            px, py = cx + x * c - y * s, cy + x * s + y * c
            r = k(26) * (1 - t / 16)
            if t == 0:
                idr.ellipse([px - r, py - r, px + r, py + r], fill=col + (255,), outline=INK + (255,), width=int(k(8)))
            else:
                idr.ellipse([px - r * 0.6, py - r * 0.6, px + r * 0.6, py + r * 0.6], fill=col + (int(200 * (1 - t / 14)),))
    # 核心：网点晕 + 实心芯 + 墨线圈
    for gx in range(-12, 13):
        for gy in range(-12, 13):
            px, py = cx + gx * k(14), cy + gy * k(14)
            dist = math.hypot(px - cx, py - cy) / k(170)
            if dist < 1:
                r = (1 - dist) * k(5.5)
                idr.ellipse([px - r, py - r, px + r, py + r], fill=RAMP[1] + (200,))
    R = k(74)
    idr.ellipse([cx - R, cy - R, cx + R, cy + R], fill=(236, 247, 244, 255), outline=INK + (255,), width=int(k(12)))
    R2 = k(40)
    idr.ellipse([cx - R2, cy - R2, cx + R2, cy + R2], fill=RAMP[4] + (255,), outline=INK + (255,), width=int(k(8)))
    imask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(imask).rounded_rectangle([cx - hw + k(6), cy - hh + k(6), cx + hw - k(6), cy + hh - k(6)], radius=hh - k(6), fill=255)
    a = inner.split()[3]
    img.paste(inner, (0, 0), Image.fromarray(__import__("numpy").minimum(__import__("numpy").array(a), __import__("numpy").array(imask))) if False else _min(a, imask))
    d = ImageDraw.Draw(img)
    # 玻璃上沿反光
    d.rounded_rectangle([cx - k(200), cy - hh + k(26), cx + k(60), cy - hh + k(44)], radius=k(9), fill=(255, 255, 255, 150))
    # 外环螺栓：沿金属环中线等距排布
    rr = hh + k(17)
    straight = 2 * (hw - hh)
    per = 2 * straight + 2 * math.pi * rr
    for i in range(20):
        u = per * i / 20
        if u < straight:
            bx, by = cx - (hw - hh) + u, cy - rr
        elif u < straight + math.pi * rr:
            ang = -math.pi / 2 + (u - straight) / rr
            bx, by = cx + (hw - hh) + math.cos(ang) * rr, cy + math.sin(ang) * rr
        elif u < 2 * straight + math.pi * rr:
            bx, by = cx + (hw - hh) - (u - straight - math.pi * rr), cy + rr
        else:
            ang = math.pi / 2 + (u - 2 * straight - math.pi * rr) / rr
            bx, by = cx - (hw - hh) + math.cos(ang) * rr, cy + math.sin(ang) * rr
        r = k(9)
        d.ellipse([bx - r, by - r, bx + r, by + r], fill=EQUIP_D, outline=INK, width=int(k(4)))
    # 磁体灯（上下各 5 个，前 4 个点亮）
    for i in range(5):
        lx = cx - k(220) + i * k(110)
        for ly in (cy - hh - k(78), cy + hh + k(40)):
            d.rectangle([lx - k(26), ly, lx + k(26), ly + k(38)], fill=EQUIP_D, outline=INK, width=int(k(8)))
            col = RAMP[min(4, i + 1)] if i < 4 else EQUIP
            d.rectangle([lx - k(15), ly + k(9), lx + k(15), ly + k(29)], fill=col)
    out = img.resize((1024, 1024), Image.LANCZOS)
    out.save(ROOT / "icon.png")
    out.save(ROOT / "icon.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    # 小尺寸预览
    prev = Image.new("RGBA", (16 + 32 + 64 + 128 + 256 + 60, 256), (255, 255, 255, 0))
    x = 0
    for sz in (16, 32, 64, 128, 256):
        prev.alpha_composite(out.resize((sz, sz), Image.LANCZOS), (x, 256 - sz))
        x += sz + 12
    prev.save(ROOT / "shots" / "icon_sizes.png")
    print("ok")

def _min(a, b):
    from PIL import ImageChops
    return ImageChops.darker(a, b)

if __name__ == "__main__":
    main()
