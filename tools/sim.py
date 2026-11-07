"""束流 数值模拟器：反推价值曲线、锁相、累计考核线。
用法: python tools/sim.py            # 扫描增长倍率 g，并对选定参数做整局模拟
"""
import random, math, sys
sys.stdout.reconfigure(encoding="utf-8")

# 概率锚点（完美, 成功, 稳定, 失谐, 丢失），线性插值，E13 以后沿用 E13 并继续加丢失
# 2026-11-07 定稿 B 表：前期丢失压低、后期加陡（原 GDD 表最优策略丢失率 70%，太虐）
ANCHORS = {1: (10, 69, 15, 5, 1), 5: (9, 62, 14, 10, 5), 9: (7, 50, 13, 14, 16), 13: (5, 33, 10, 12, 40)}
EMAX = 20

def probs(E):
    ks = sorted(ANCHORS)
    if E >= ks[-1]:
        p = list(ANCHORS[ks[-1]]); extra = min(30, (E - 13) * 6)
        p[4] += extra; p[1] -= extra * 0.7; p[0] -= extra * 0.1; p[2] -= extra * 0.2
        return [max(0, x) / 100 for x in p]
    for a, b in zip(ks, ks[1:]):
        if a <= E <= b:
            t = (E - a) / (b - a)
            return [(ANCHORS[a][i] * (1 - t) + ANCHORS[b][i] * t) / 100 for i in range(5)]

class Cfg:
    def __init__(self, g, base=40, lock_need=6, lock_n=4):
        self.g, self.base, self.lock_need, self.lock_n = g, base, lock_need, lock_n
    def value(self, E):
        return self.base * self.g ** (E - 1)

def myopic_cross(cfg):
    """不考虑锁相：再按一次的期望价值 / 当前价值 首次 <1 的能级"""
    for E in range(1, EMAX):
        p = probs(E); V = cfg.value
        nxt = p[0] * V(min(EMAX, E + 2)) + p[1] * V(E + 1) + p[2] * V(E) + p[3] * V(max(1, E - 1))
        if nxt < V(E):
            return E
    return EMAX

def optimal_values(cfg):
    """动态规划：状态 (E, charge, lock_left, lock_used)，求期望最大停手策略的价值函数"""
    from functools import lru_cache
    V = cfg.value
    @lru_cache(None)
    def W(E, ch, lk, used, depth=0):
        stop = V(E)
        if depth > 60 or E >= EMAX:
            return stop
        p = probs(E)
        if lk > 0:  # 锁相：丢失为 0，按比例分给成功
            p = p[:4]; s = sum(p); p = [x / s for x in p] + [0]
        ev = 0
        for i, pi in enumerate(p):
            if pi == 0: continue
            if i == 4: continue  # 丢失=0
            dE = (2, 1, 0, -1)[i]
            nE = max(1, min(EMAX, E + dE))
            nch, nlk, nused = ch, max(0, lk - 1), used
            if lk == 0 and not used:
                nch = 0 if i == 3 else ch + (2, 1, 0)[i]
                if nch >= cfg.lock_need:
                    nch, nlk, nused = 0, cfg.lock_n, True
            ev += pi * W(nE, nch, nlk, nused, depth + 1)
        return max(stop, ev)
    return W

def run_experiment(cfg, rng, policy):
    E, ch, lk, used, presses = 1, 0, 0, False, 0
    while True:
        if policy(E, ch, lk, used):
            return cfg.value(E), presses, E
        presses += 1
        p = probs(E)
        if lk > 0:
            p = p[:4]; s = sum(p); p = [x / s for x in p] + [0]
        r = rng.random(); i = 0; acc = p[0]
        while r > acc and i < 4:
            i += 1; acc += p[i]
        if i == 4:
            return 0, presses, E
        E = max(1, min(EMAX, E + (2, 1, 0, -1)[i]))
        if lk > 0:
            lk -= 1
        elif not used:
            ch = 0 if i == 3 else ch + (2, 1, 0)[i]
            if ch >= cfg.lock_need:
                ch, lk, used = 0, cfg.lock_n, True

def threshold(k):
    return lambda E, ch, lk, used: E >= k and lk == 0

def optimal_policy(cfg):
    W = optimal_values(cfg)
    return lambda E, ch, lk, used: W(E, ch, lk, used) <= cfg.value(E) + 1e-9

def stats(cfg, policy, n=20000, seed=1):
    rng = random.Random(seed); vals = []; pr = []
    for _ in range(n):
        v, p, _ = run_experiment(cfg, rng, policy); vals.append(v); pr.append(p)
    vals.sort()
    return sum(vals) / n, sum(1 for v in vals if v == 0) / n, sum(pr) / n, vals[n // 2]

def campaign(cfg, policy, lines, n=20000, seed=7, per_stage=3):
    """累计总分制：每阶段 3 次实验，阶段末累计总分须 >= 该阶段考核线"""
    rng = random.Random(seed); passed = [0] * len(lines)
    for _ in range(n):
        tot = 0
        for s, L in enumerate(lines):
            for _ in range(per_stage):
                if tot >= L: break           # 已达标可提前结算（M1 简化）
                v, _, _ = run_experiment(cfg, rng, policy); tot += v
            if tot < L: break
            passed[s] += 1
    return [x / n for x in passed]

if __name__ == "__main__":
    print("== 扫描增长倍率 g：短视期望转负的能级 / 最优停手期望 ==")
    for g in (1.25, 1.3, 1.35, 1.4, 1.45, 1.5, 1.6, 1.7):
        cfg = Cfg(g)
        print(f"g={g:<5} 转负能级 E{myopic_cross(cfg):<3} 最优策略: 期望 {stats(cfg, optimal_policy(cfg), 6000)[0]:9.0f}")
    g = float(sys.argv[1]) if len(sys.argv) > 1 else 1.32
    cfg = Cfg(g)
    print(f"\n== g={g}：各种停手策略（单次实验） ==")
    print("策略        期望价值   丢失率   平均按键  中位数")
    pols = [("最优", optimal_policy(cfg))] + [(f"停在E{k}", threshold(k)) for k in (4, 6, 8, 10, 12)]
    for name, pol in pols:
        m, lose, pr, med = stats(cfg, pol)
        print(f"{name:<8} {m:10.0f} {lose:8.1%} {pr:8.1f} {med:9.0f}")
    print("\n能级价值:", " ".join(f"E{E}={cfg.value(E):.0f}" for E in range(1, 15)))
    print("每级概率(完/成/稳/失/丢):")
    for E in (1, 3, 5, 7, 9, 11, 13):
        print(f"  E{E}: " + " / ".join(f"{x*100:.1f}" for x in probs(E)))
    m = stats(cfg, optimal_policy(cfg))[0]
    lines = [round(m * 1.6, -1), round(m * 4.2, -1), round(m * 7.6, -1)]
    print(f"\n== 累计考核线（以最优单次期望 {m:.0f} 为基准）: {lines}")
    for name, pol in pols:
        print(f"{name:<8} 通过阶段1/2/3: " + " / ".join(f"{x:.0%}" for x in campaign(cfg, pol, lines)))
