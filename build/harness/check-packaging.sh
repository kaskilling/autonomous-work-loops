#!/usr/bin/env sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$repo_root"

fail() {
  printf 'packaging check failed: %s\n' "$1" >&2
  exit 1
}

[ -f ".codex-plugin/plugin.json" ] || fail "missing .codex-plugin/plugin.json"
[ -f ".claude-plugin/plugin.json" ] || fail "missing .claude-plugin/plugin.json"
[ -d "skills" ] || fail "missing skills directory"
[ ! -L "skills" ] || fail "skills must be a real directory, not a symlink"
[ -f "skills/autonomous-work-loops/SKILL.md" ] || fail "missing skills/autonomous-work-loops/SKILL.md"
[ ! -e "skill" ] || fail "legacy skill directory still exists"

python3 - <<'PY'
import json
from pathlib import Path

root = Path(".")

def fail(message: str) -> None:
    raise SystemExit(f"packaging check failed: {message}")

codex = json.loads((root / ".codex-plugin/plugin.json").read_text())
skills_path = codex.get("skills")
if skills_path != "./skills/":
    fail(f"Codex skills path should be ./skills/, got {skills_path!r}")

for field in ("websiteURL", "privacyPolicyURL", "termsOfServiceURL"):
    value = codex.get("interface", {}).get(field)
    if not isinstance(value, str) or not value.startswith("https://"):
        fail(f"Codex interface.{field} must be an https URL")

codex_skill_root = root / skills_path.removeprefix("./")
if not (codex_skill_root / "autonomous-work-loops/SKILL.md").is_file():
    fail("Codex skills path does not expose autonomous-work-loops/SKILL.md")

claude = json.loads((root / ".claude-plugin/plugin.json").read_text())
claude_skills = claude.get("skills")
if claude_skills != ["./skills/autonomous-work-loops"]:
    fail(f"Claude skills path should be ['./skills/autonomous-work-loops'], got {claude_skills!r}")

for entry in claude_skills:
    target = root / entry.removeprefix("./")
    if not (target / "SKILL.md").is_file():
        fail(f"Claude skill path does not contain SKILL.md: {entry}")
PY

printf '%s\n' "packaging check passed"
