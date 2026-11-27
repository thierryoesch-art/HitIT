"""Erzeugt fünf eigene Songs (OGG) mit passenden Beatmaps «leicht» und «schwer» für HitIT.

Alle Klänge werden hier synthetisch erzeugt (keine fremden Samples) – die Musik ist
damit eine eigene Komposition des Projekts und wird unter CC0 freigegeben.
Die Melodietöne liegen exakt auf den Notenzeiten der leichten Beatmap, die zusätzlichen
Noten der schweren Beatmap liegen auf den Hi-Hats (Achtel).
"""
import json, os, random, subprocess, sys
import numpy as np

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/v02/hitit/assets"
DEMO_LEICHT = os.path.join(OUT, "beatmaps", "demo_leicht.json")

SONGS = [
    # kennung, titel, bpm, start_ms, takte, grundton (Hz), Akkordfolge (Halbtöne über Grundton, Moll/Dur)
    ("demo", "Demo-Track", 128.0, 1600, None, 220.0, [(0, "m"), (-4, "M"), (3, "M"), (-2, "M")]),
    ("neon_puls", "Neon Puls", 120.0, 2000, 22, 196.0, [(0, "m"), (5, "m"), (-2, "M"), (3, "M")]),
    ("morgenrot", "Morgenrot", 100.0, 2400, 18, 261.63, [(0, "M"), (-3, "m"), (5, "M"), (7, "M")]),
    ("turbo_tiles", "Turbo Tiles", 140.0, 1714, 26, 233.08, [(0, "m"), (-4, "M"), (-2, "M"), (0, "m")]),
    ("kaskade", "Kaskade", 110.0, 2182, 20, 207.65, [(0, "m"), (3, "M"), (-2, "M"), (5, "m")]),
]


def ton(f, dauer, typ="pluck", vol=0.3):
    n = int(SR * dauer)
    t = np.arange(n) / SR
    if typ == "pluck":
        env = np.exp(-t * 7.0)
        w = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) + 0.15 * np.sin(2 * np.pi * 3 * f * t)
    elif typ == "pad":
        env = np.minimum(1.0, t / 0.03) * np.minimum(1.0, (dauer - t) / 0.08)
        w = np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.005 * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    else:  # bass
        env = np.exp(-t * 3.0) * np.minimum(1.0, t / 0.005)
        w = np.sign(np.sin(2 * np.pi * f * t)) * 0.4 + np.sin(2 * np.pi * f * t)
    return (w * env * vol).astype(np.float32)


def kick():
    t = np.arange(int(SR * 0.25)) / SR
    f = 50 + 90 * np.exp(-t * 30)
    return (np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 12) * 0.9).astype(np.float32)


def clap(rng):
    t = np.arange(int(SR * 0.18)) / SR
    return (rng.standard_normal(len(t)) * np.exp(-t * 25) * 0.35).astype(np.float32)


def hat(rng):
    t = np.arange(int(SR * 0.05)) / SR
    x = rng.standard_normal(len(t))
    x = np.diff(np.concatenate([[0], x]))  # Hochpass
    return (x * np.exp(-t * 80) * 0.12).astype(np.float32)


def add(buf, sig, ms):
    i = int(round(ms * SR / 1000.0))
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[: j - i]


def akkord(root, art):
    return [root, root * 2 ** ((3 if art == "m" else 4) / 12), root * 2 ** (7 / 12), root * 2]


def leicht_beatmap(rng, bpm, start, takte):
    beat = 60000.0 / bpm
    noten, belegt_bis = [], [-1.0] * 4
    letzte = -1
    b = 0
    gesamt = takte * 4
    while b < gesamt - 1:
        t = start + b * beat
        if b % 16 == 15:          # kurze Pause am Ende jeder Phrase
            b += 1
            continue
        frei = [s for s in range(4) if belegt_bis[s] < t - 1 and s != letzte]
        spur = rng.choice(frei)
        if b % 8 == 4 and b + 2 < gesamt:   # Hold-Note über zwei Schläge
            dauer = int(round(2 * beat * 0.9))
            noten.append({"t": int(round(t)), "spur": spur, "typ": "hold", "dauer": dauer})
            belegt_bis[spur] = t + dauer
            b += 2
        else:
            noten.append({"t": int(round(t)), "spur": spur, "typ": "tap"})
            belegt_bis[spur] = t
            b += 1
        letzte = spur
    return noten


def schwer_beatmap(rng, leicht, bpm):
    beat = 60000.0 / bpm
    noten = [dict(n) for n in leicht]
    extra = []
    for i in range(len(leicht) - 1):
        a, b = leicht[i], leicht[i + 1]
        if a["typ"] != "tap":
            continue
        if b["t"] - a["t"] < beat * 0.9:
            continue
        mitte = a["t"] + beat / 2
        aktiv = {n["spur"] for n in leicht if n["typ"] == "hold" and n["t"] <= mitte <= n["t"] + n["dauer"] + 60}
        frei = [s for s in range(4) if s not in (a["spur"], b["spur"]) and s not in aktiv]
        if frei:
            extra.append({"t": int(round(mitte)), "spur": rng.choice(frei), "typ": "tap"})
    # zusätzlich Viertel in den Pausen am Phrasenende
    noten += extra
    noten.sort(key=lambda n: n["t"])
    return noten


def musik(rng, bpm, start, ende_ms, progression, grund, leicht):
    beat = 60000.0 / bpm
    laenge_ms = ende_ms + 2500
    buf = np.zeros(int(SR * laenge_ms / 1000.0) + SR, dtype=np.float32)
    k, c = kick(), clap(rng)
    n_beats = int((ende_ms - start) / beat) + 2
    # Einzähler: zwei Hi-Hats vor dem ersten Schlag
    for i in range(1, 3):
        if start - i * beat >= 0:
            add(buf, hat(rng) * 2, start - i * beat)
    for i in range(n_beats):
        t = start + i * beat
        add(buf, k, t)
        if i % 2 == 1:
            add(buf, c, t)
        add(buf, hat(rng), t + beat / 2)
        takt = i // 4
        root, art = progression[takt % len(progression)]
        f = grund * 2 ** (root / 12) / 2
        add(buf, ton(f, beat / 1000.0 * 0.95, "bass", 0.18), t)
        if i % 4 == 0:
            for fa in akkord(grund * 2 ** (root / 12), art)[:3]:
                add(buf, ton(fa, 4 * beat / 1000.0, "pad", 0.035), t)
    for n in leicht:
        takt = int((n["t"] - start) / beat) // 4
        root, art = progression[takt % len(progression)]
        f = akkord(grund * 2 ** (root / 12), art)[n["spur"]] * 2
        if n["typ"] == "hold":
            add(buf, ton(f, n["dauer"] / 1000.0, "pad", 0.12), n["t"])
        else:
            add(buf, ton(f, 0.35, "pluck", 0.22), n["t"])
    buf = buf[: int(SR * laenge_ms / 1000.0)]
    buf /= max(1e-6, np.max(np.abs(buf))) / 0.85
    return buf


def schreiben_ogg(buf, pfad):
    raw = (np.clip(buf, -1, 1) * 32767).astype(np.int16).tobytes()
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "4", pfad], input=raw, check=True)


def kopf(kennung, titel, bpm, start, schwierigkeit, vorschau):
    return {"titel": titel, "interpret": "HitIT-Team", "audiodatei": f"assets/songs/{kennung}.ogg",
            "lizenz": "CC0 1.0 (eigene Komposition)", "quelle": "Im Projekt HitIT synthetisch erzeugt (tools/songs.py)",
            "bpm": bpm, "startOffset": start, "spuren": 4, "schwierigkeit": schwierigkeit, "vorschau": vorschau}


os.makedirs(os.path.join(OUT, "songs"), exist_ok=True)
os.makedirs(os.path.join(OUT, "beatmaps"), exist_ok=True)
for kennung, titel, bpm, start, takte, grund, prog in SONGS:
    rng = random.Random(kennung)
    nrng = np.random.default_rng(__import__("zlib").crc32(kennung.encode()))
    if kennung == "demo":
        leicht = json.load(open(DEMO_LEICHT, encoding="utf-8"))["noten"]
    else:
        leicht = leicht_beatmap(rng, bpm, start, takte)
    schwer = schwer_beatmap(rng, leicht, bpm)
    ende = max(n["t"] + n.get("dauer", 0) for n in leicht)
    vorschau = int(start + 8 * 4 * 60000.0 / bpm)
    for grad, noten in (("leicht", leicht), ("schwer", schwer)):
        daten = kopf(kennung, titel, bpm, start, grad, vorschau)
        daten["noten"] = noten
        with open(os.path.join(OUT, "beatmaps", f"{kennung}_{grad}.json"), "w", encoding="utf-8") as f:
            json.dump(daten, f, ensure_ascii=False, indent=1)
    buf = musik(nrng, bpm, start, ende, prog, grund, leicht)
    schreiben_ogg(buf, os.path.join(OUT, "songs", f"{kennung}.ogg"))
    print(f"{kennung:12s} {bpm:5.0f} BPM  {len(buf)/SR:5.1f} s  leicht {len(leicht):3d}  schwer {len(schwer):3d}  "
          f"Faktor {len(schwer)/len(leicht):.2f}")
