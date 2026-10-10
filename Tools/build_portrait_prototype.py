"""Build the unapproved portrait study; never overwrite original game artwork."""
from pathlib import Path
import copy
import json
import os

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Docs/artwork/final-portraits"
OUT = ART / "prototype"
OUT.mkdir(parents=True, exist_ok=True)
data = json.loads((ART / "source-export/niniliteFigure.json").read_text())
mouth = data["skins"][0]["attachments"]["zui"]
mouth["mouth-closed"] = dict(mouth["zui"], path="mouth-closed", width=240, height=160)
listen = copy.deepcopy(data["animations"]["idle"])
listen.setdefault("slots", {})["zui"] = {"attachment": [{"name": "mouth-closed"}]}
listen.setdefault("bones", {})["zui"] = {"scale": [{"x": 1, "y": 1}]}
# Reuse the original open-eye layers, rather than stretching the wink artwork.
for number in range(6, 11):
    listen["slots"][f"youyan{number}"] = {"attachment": [{"name": f"youyan{11-number}"}]}
listen["slots"]["zuoyan"] = {"attachment": [{}]}
listen["bones"]["youyan8"] = {"scale": [{"x": 1, "y": 1}]}
listen["bones"]["youyan9"] = {"translate": [{"x": 0, "y": 0}]}
data["animations"]["listenPrototype"] = listen
# Joint-space studies, not approved production poses.
for name, shoulder, elbow in [("armStudyA", 85, 180), ("armStudyB", 85, 180), ("armStudyC", 85, 180)]:
    study = copy.deepcopy(listen)
    for bone, angle in [("shoutao1", shoulder), ("zuobi2", elbow), ("zuobi3", -19), ("zuobi4", -25)]:
        study["bones"][bone] = {"rotate": [{"value": angle}]}
    # Local deform on the two armpit edge vertices, retaining original UVs.
    amount = {"armStudyA": 0, "armStudyB": 100, "armStudyC": 180}[name]
    mesh = data["skins"][0]["attachments"]["zuobi1"]["zuobi1"]
    cursor, vertex, offsets = 0, 0, []
    while cursor < len(mesh["vertices"]):
        count = int(mesh["vertices"][cursor]); cursor += 1
        for influence in range(count):
            offsets += [amount if vertex in (3, 4) else 0, 0]
            cursor += 4
        vertex += 1
    study.setdefault("attachments", {}).setdefault("default", {}).setdefault("zuobi1", {})["zuobi1"] = {"deform": [{"vertices": offsets}]}
    data["animations"][name] = study

candidate = copy.deepcopy(data["animations"]["armStudyB"])
# The original wink also deforms the white and iris meshes independently.
for slot in ("youyan6", "youyan7"):
    candidate.get("attachments", {}).get("default", {}).pop(slot, None)
for bone, center, amplitude in [("shoutao1", 85, .7), ("zuobi2", 180, .9), ("zuobi3", -19, .4), ("zuobi4", -25, .3)]:
    candidate["bones"][bone] = {"rotate": [{"value": center}, {"time": 1.333333, "value": center + amplitude}, {"time": 2.666667, "value": center}, {"time": 4, "value": center - amplitude}, {"time": 5.3333335, "value": center}]}
# Eye local X is nearly vertical in the original head rig.
for bone in ("youyan4", "youyan5"):
    candidate["bones"][bone] = {"scale": [{"x": 1, "y": 1}, {"time": 2.1, "x": 1, "y": 1}, {"time": 2.18, "x": .06, "y": 1}, {"time": 2.24, "x": .06, "y": 1}, {"time": 2.37, "x": 1, "y": 1}, {"time": 5.3333335, "x": 1, "y": 1}]}
# Preserve brow shapes and upper eyelash curvature during the blink.
# Appending bones keeps every original weighted-mesh bone index unchanged.
original_bones = {bone["name"]: bone for bone in data["bones"]}
for name, source, parent in [("listenBrowRight", "youyan4", "tou"), ("listenBrowLeftRoot", "youyan5", "tou"), ("listenBrowLeft", "youyan9", "listenBrowLeftRoot"), ("listenLidRight", "youyan4", "tou"), ("listenLidLeftRoot", "youyan5", "tou"), ("listenLidLeft", "youyan9", "listenLidLeftRoot")]:
    bone = copy.deepcopy(original_bones[source]); bone.update(name=name, parent=parent)
    data["bones"].append(bone)
for slot in data["slots"]:
    replacement = {"youyan1": "listenBrowRight", "youyan10": "listenBrowLeft", "youyan2": "listenLidRight", "youyan9": "listenLidLeft"}.get(slot["name"])
    if replacement:
        slot["bone"] = replacement
for bone in ("listenLidRight", "listenLidLeftRoot"):
    candidate["bones"][bone] = {"translate": [{"x": 0}, {"time": 2.1, "x": 0}, {"time": 2.18, "x": -21.5}, {"time": 2.24, "x": -21.5}, {"time": 2.37, "x": 0}, {"time": 5.3333335, "x": 0}]}
data["animations"]["listenCandidate"] = candidate

(OUT / "ninilite-emotion.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
lines = (ROOT / "Spine/niniliteFigure.atlas").read_text().splitlines()
while lines and not lines[-1].strip():
    lines.pop()
if lines[-1] == "1":
    lines.pop()  # Stray region name has no bounds and prevents official image unpack.
lines[0] = Path(os.path.relpath(ROOT / "Spine/niniliteFigure.png", OUT)).as_posix()
(OUT / "ninilite-emotion.atlas").write_text("\n".join(lines) + "\n\nmouth-closed-v3.png\nsize:1536,1024\nfilter:Linear,Linear\nmouth-closed\nbounds:0,0,1536,1024\n")
print("Built study assets only; visual acceptance remains required.")
