#!/usr/bin/env python3
"""
reorganize_project.py - moves the Godot project into the scripts/ + scenes/ layout.

Usage (run from the project root, with the Godot editor CLOSED):
    python reorganize_project.py            # dry run: prints what would happen
    python reorganize_project.py --apply    # actually move files and rewrite res:// paths

What it does
  1. Moves every .gd file (and its .uid sidecar) under scripts/, scenes under scenes/.
  2. Fixes naming: assset_lookup.gd -> asset_lookup.gd, content/enounters -> encounters.
  3. Rewrites res:// paths inside .gd/.tscn/.tres/project.godot/.cfg/.md files.
  4. Creates the planned (empty) folders with a .gitkeep so git tracks them.
It uses `git mv` when the folder is a git repo, otherwise a plain move.
"""
import argparse
import shutil
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------- mapping --
# Exact file moves / renames (checked before directory rules).
FILE_MAP = {
    "battle/battle_controller.gd": "scripts/battle/battle_controller.gd",
    "battle/battle_scene.tscn": "scenes/battle/battle_scene.tscn",
    "battle/ui/debug_panel.gd": "scripts/debug/debug_panel.gd",
    "shared/assset_lookup.gd": "scripts/shared/asset_lookup.gd",   # typo fix
}

# Directory moves (longest prefix wins). Files keep their relative sub-path.
DIR_MAP = {
    "battle/data": "scripts/battle/data",
    "battle/models": "scripts/battle/models",
    "battle/systems": "scripts/battle/systems",
    "battle/ui": "scripts/battle/ui",
    "content/spells/templates": "resources/spells/templates",
    "content/spells": "scripts/content/spells",
    "content/enounters": "scripts/content/encounters",             # typo fix
    "content/encounters": "scripts/content/encounters",
    "content/enemies": "resources/enemies",
    "content/fragments": "resources/fragments",
    "shared": "scripts/shared",
}

# Folders created for planned systems (see README sections 1-10).
PLANNED_DIRS = [
    "scripts/autoload", "scripts/shared",
    "scripts/battle/data", "scripts/battle/models", "scripts/battle/systems",
    "scripts/battle/ui", "scripts/battle/ai", "scripts/battle/terrain",
    "scripts/content/spells", "scripts/content/encounters",
    "scripts/content/enemies", "scripts/content/items",
    "scripts/player", "scripts/progression",
    "scripts/items", "scripts/inventory", "scripts/economy",
    "scripts/exploration", "scripts/save", "scripts/ui", "scripts/debug", "scripts/utils",
    "scenes/main", "scenes/battle/ui", "scenes/exploration",
    "scenes/ui", "scenes/components", "scenes/debug",
    "resources/spells/fire", "resources/spells/ice", "resources/spells/earth",
    "resources/spells/wind", "resources/spells/lightning", "resources/spells/dark",
    "resources/spells/templates", "resources/fragments", "resources/enemies",
    "resources/encounters", "resources/items", "resources/characters",
    "resources/boards", "resources/themes",
    "assets/characters", "assets/enemies", "assets/textures/tiles", "assets/textures/ui",
    "assets/textures/environments", "assets/icons/elements", "assets/icons/statuses",
    "assets/icons/spells", "assets/icons/items", "assets/vfx",
    "assets/audio/sfx", "assets/audio/music", "assets/fonts",
    "tests", "docs",
]

SKIP_TOP = {".git", ".godot", "addons", "assets", "scripts", "scenes",
            "resources", "tests", "docs", ".vscode"}
TEXT_EXT = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".md", ".json"}
OLD_ROOT_DIRS = ["battle", "content", "shared"]
REPORT_ONLY = ["project.godot.bak"]
# ---------------------------------------------------------------------------


def plan_moves(root: Path):
    file_map = dict(FILE_MAP)
    for old, new in list(FILE_MAP.items()):
        file_map[old + ".uid"] = new + ".uid"
    dir_rules = sorted(DIR_MAP.items(), key=lambda kv: -len(kv[0]))
    moves = {}
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        if rel.split("/")[0] in SKIP_TOP or "/" not in rel:
            continue
        if rel in file_map:
            moves[rel] = file_map[rel]
            continue
        for old_dir, new_dir in dir_rules:
            if rel.startswith(old_dir + "/"):
                moves[rel] = new_dir + rel[len(old_dir):]
                break
    return moves


def do_move(root: Path, old: str, new: str, use_git: bool):
    src, dst = root / old, root / new
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        print(f"  ! target exists, skipped: {new}")
        return False
    if use_git:
        r = subprocess.run(["git", "mv", old, new], cwd=root,
                           capture_output=True, text=True)
        if r.returncode == 0:
            return True
    shutil.move(str(src), str(dst))
    return True


def rewrite_paths(root: Path, moves: dict, apply: bool):
    pairs = sorted(((f"res://{o}", f"res://{n}") for o, n in moves.items()
                    if not o.endswith(".uid")), key=lambda p: -len(p[0]))
    changed = []
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix not in TEXT_EXT:
            continue
        top = path.relative_to(root).parts[0]
        if top in {".git", ".godot", "addons"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        new_text = text
        for old, new in pairs:
            new_text = new_text.replace(old, new)
        if new_text != text:
            changed.append(path.relative_to(root).as_posix())
            if apply:
                path.write_text(new_text, encoding="utf-8", newline="")
    return changed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="perform the changes")
    ap.add_argument("--root", default=".", help="project root (folder with project.godot)")
    ap.add_argument("--no-git", action="store_true", help="never use git mv")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    if not (root / "project.godot").exists():
        sys.exit(f"project.godot not found in {root}. Run from the project root.")
    use_git = (root / ".git").exists() and not args.no_git and shutil.which("git")

    moves = plan_moves(root)
    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"[{mode}] {len(moves)} file(s) to move. git mv: {bool(use_git)}\n")
    for old, new in moves.items():
        print(f"  {old}  ->  {new}")

    if args.apply:
        for old, new in moves.items():
            do_move(root, old, new, bool(use_git))

    changed = rewrite_paths(root, moves, args.apply)
    print(f"\nres:// path rewrites in {len(changed)} file(s):")
    for c in changed:
        print(f"  {c}")

    if args.apply:
        for d in PLANNED_DIRS:
            p = root / d
            p.mkdir(parents=True, exist_ok=True)
            keep = p / ".gitkeep"
            if not any(p.iterdir()):
                keep.touch()
        for top in OLD_ROOT_DIRS:
            base = root / top
            if base.exists():
                for sub in sorted(base.rglob("*"), reverse=True):
                    if sub.is_dir() and not any(sub.iterdir()):
                        sub.rmdir()
                if not any(base.iterdir()):
                    base.rmdir()

    left = [r for r in REPORT_ONLY if (root / r).exists()]
    stale = root / "scripts/shared/battle_types.gd"
    print("\nManual follow-ups:")
    for r in left:
        print(f"  - delete stray file: {r}")
    if args.apply and stale.exists() or (not args.apply and (root / "shared/battle_types.gd").exists()):
        print("  - shared/battle_types.gd is superseded by elements.gd and status_types.gd."
              " Search the project for 'BattleTypes'; if nothing is found, delete the file.")
    print("  - open the project in Godot; if you see odd errors, close Godot, delete the"
          " local .godot/ folder and reopen (it regenerates).")
    if not args.apply:
        print("\nThis was a dry run. Re-run with --apply to make the changes.")


if __name__ == "__main__":
    main()
