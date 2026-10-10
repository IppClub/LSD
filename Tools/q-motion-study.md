# Authored Q motion study

From the Dora-SSR checkout, compile this local reader against the already bundled Spine source:

```sh
clang++ -std=c++17 -O0 -I Source/3rdParty /Users/Jin/Workspace/Dora/LSD/Tools/analyze_q_motion.cpp Source/3rdParty/spine/*.cpp -o /private/tmp/lsd-spine-motion
/private/tmp/lsd-spine-motion /Users/Jin/Workspace/Dora/LSD/Spine/ninilite /Users/Jin/Workspace/Dora/LSD/Spine/wuyun /Users/Jin/Workspace/Dora/LSD/Spine/charF > /private/tmp/lsd-q-motion.tsv
```

No textures are loaded or edited. `ANIM` records exact authored durations; `BONE` records 25 sampled phases of world pose and rotation. Each phase starts from setup pose and Physics_Reset, so this omits continuous physics history and is not a deformation or rendered silhouette analysis. World angles must be unwrapped before estimating their ranges. Save the TSV then run `summarize_q_motion.py` to generate its JSON summary.

Native evidence comes separately from `Test/QCharacterMotionStudy.lua`: original three-character playback, nine full finite AnimationEnd records, idle and two movement screenshots. New independent fox motion candidate uses `build_fox_motion.py`, and `Test/FoxCompanionMotion.lua` verifies native joint interpolation and planted idle feet. These are supplementary to visual acceptance. Do not adopt a candidate just because its numeric tests pass.
