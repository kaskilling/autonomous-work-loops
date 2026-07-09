#!/usr/bin/env bash
# Deterministic bootstrap for autonomous-work-loops target repositories.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--force] [--guided] [--arm] [--allow-incomplete] [target-repo]

Copies agent-loops-template into <target-repo>/.agent-loops, renders local
runner scripts, fills conservative discovered defaults, and writes
.agent-loops/BOOTSTRAP-REPORT.md.

Defaults:
  target-repo  current working directory

Options:
  --force             replace an existing .agent-loops directory
  --guided            run labels, doctor, create the smoke issue, and run one tick
  --arm               guided setup, then start the managed background supervisor
  --allow-incomplete  scaffold even when the target is not a GitHub git repo
  -h, --help          show this help
EOF
}

force=0
guided=0
arm=0
allow_incomplete=0
target="${PWD}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --guided)
      guided=1
      shift
      ;;
    --arm)
      guided=1
      arm=1
      shift
      ;;
    --allow-incomplete)
      allow_incomplete=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *)
      target="$1"
      shift
      if [ "$#" -gt 0 ]; then
        printf 'unexpected extra argument: %s\n' "$1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

if [ "$#" -gt 0 ]; then
  target="$1"
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 is required to render bootstrap files.\n' >&2
  exit 1
fi

if [ ! -d "$target" ]; then
  printf 'target repo path does not exist: %s\n' "$target" >&2
  exit 1
fi

target="$(cd "$target" && pwd -P)"

if [ "$allow_incomplete" -ne 1 ]; then
  if ! git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'target is not a git worktree: %s\n' "$target" >&2
    printf 'run from a GitHub repo, or pass --allow-incomplete for manual scaffolding.\n' >&2
    exit 1
  fi
  origin_url="$(git -C "$target" remote get-url origin 2>/dev/null || true)"
  case "$origin_url" in
    *github.com*) ;;
    *)
      printf 'target origin remote is not GitHub: %s\n' "${origin_url:-'(missing)'}" >&2
      printf 'V1 supports GitHub only, or pass --allow-incomplete for manual scaffolding.\n' >&2
      exit 1
      ;;
  esac
fi

assets_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
template_dir="${assets_dir}/agent-loops-template"
runner_template_dir="${assets_dir}/runners"
dest="${target}/.agent-loops"
reused_existing=0

if [ ! -d "$template_dir" ]; then
  printf 'missing template directory: %s\n' "$template_dir" >&2
  exit 1
fi

if [ ! -d "$runner_template_dir" ]; then
  printf 'missing runner template directory: %s\n' "$runner_template_dir" >&2
  exit 1
fi

if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
  if [ "$guided" -eq 1 ] && [ -d "$dest" ]; then
    reused_existing=1
  else
    printf 'refusing to overwrite existing %s\n' "$dest" >&2
    printf 'rerun with --force to replace it, or use --arm/--guided to resume existing setup.\n' >&2
    exit 1
  fi
fi

if [ "$reused_existing" -eq 0 ]; then
tmp="${target}/.agent-loops.tmp.$$"
rm -rf "$tmp"
trap 'rm -rf "$tmp"' EXIT

cp -R "$template_dir" "$tmp"
mkdir -p "$tmp/runners" "$tmp/evidence/inbox"

gh_user=""
repo_json=""
gh_status="not checked: gh not found"
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    gh_status="authenticated"
  else
    gh_status="gh auth status failed"
  fi
  gh_user="$(gh api user --jq .login 2>/dev/null || true)"
  repo_json="$(cd "$target" && gh repo view --json nameWithOwner,owner,visibility,viewerPermission,defaultBranchRef,hasIssuesEnabled 2>/dev/null || true)"
fi

AWL_TARGET="$target" \
AWL_TMP="$tmp" \
AWL_ASSETS_DIR="$assets_dir" \
AWL_GUIDED="$guided" \
AWL_ARM="$arm" \
AWL_RUNNER_TEMPLATES="$runner_template_dir" \
AWL_GH_USER="$gh_user" \
AWL_GH_STATUS="$gh_status" \
AWL_REPO_JSON="$repo_json" \
python3 - <<'PY'
import json
import os
import re
from pathlib import Path

target = Path(os.environ["AWL_TARGET"])
tmp = Path(os.environ["AWL_TMP"])
assets_dir = Path(os.environ["AWL_ASSETS_DIR"])
guided = os.environ.get("AWL_GUIDED", "0") == "1"
arm = os.environ.get("AWL_ARM", "0") == "1"
runner_templates = Path(os.environ["AWL_RUNNER_TEMPLATES"])
gh_user = os.environ.get("AWL_GH_USER", "").strip()
gh_status = os.environ.get("AWL_GH_STATUS", "")
repo_json_raw = os.environ.get("AWL_REPO_JSON", "").strip()


def shell_double(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("$", "\\$")
        .replace("`", "\\`")
    )


def render_template(src: Path, dst: Path) -> None:
    text = src.read_text()
    replacements = {
        "{{repo_path}}": shell_double(str(target)),
        "{{interval_seconds}}": "600",
        "{{role}}": "implementer",
        "{{model}}": "",
        "{{timeout_minutes}}": "30",
    }
    for key, value in replacements.items():
        text = text.replace(key, value)
    dst.write_text(text)


for name in ("local-supervisor.sh", "guarded-role-runner-common.sh", "codex.sh", "claude.sh"):
    source = runner_templates / f"{name}.tmpl"
    if not source.exists():
        raise SystemExit(f"missing runner template: {source}")
    render_template(source, tmp / "runners" / name)


def package_manager(package_json: dict) -> str:
    declared = str(package_json.get("packageManager", "")).split("@", 1)[0]
    if declared in {"npm", "pnpm", "yarn", "bun"}:
        return declared
    if (target / "pnpm-lock.yaml").exists():
        return "pnpm"
    if (target / "yarn.lock").exists():
        return "yarn"
    if (target / "bun.lockb").exists() or (target / "bun.lock").exists():
        return "bun"
    return "npm"


def package_script_command(manager: str, script: str) -> str:
    if manager == "npm":
        return "npm test" if script == "test" else f"npm run {script}"
    if manager == "pnpm":
        return f"pnpm {script}"
    if manager == "yarn":
        return f"yarn {script}"
    if manager == "bun":
        return f"bun run {script}"
    return ""


proof = {"test": "", "build": "", "lint": ""}
proof_sources = {"test": "", "build": "", "lint": ""}
proof_notes = []
package_json_path = target / "package.json"
if package_json_path.exists():
    try:
        package_json = json.loads(package_json_path.read_text())
        scripts = package_json.get("scripts", {})
        if isinstance(scripts, dict):
            manager = package_manager(package_json)
            for key in ("test", "build", "lint"):
                if isinstance(scripts.get(key), str) and scripts[key].strip():
                    proof[key] = package_script_command(manager, key)
                    proof_sources[key] = f"package.json scripts.{key}"
            test_script = str(scripts.get("test", ""))
            unit_script = scripts.get("test:unit")
            if (
                isinstance(unit_script, str)
                and unit_script.strip()
                and proof["test"]
                and re.search(r"\b(e2e|playwright|browser|headed)\b", test_script, re.IGNORECASE)
            ):
                full_test = proof["test"]
                proof["test"] = package_script_command(manager, "test:unit")
                proof_sources["test"] = "package.json scripts.test:unit (first-smoke default)"
                proof_notes.append(
                    f"Full test candidate: {full_test} (package.json scripts.test includes browser/e2e work)."
                )
    except json.JSONDecodeError:
        pass

pyproject = target / "pyproject.toml"
pyproject_text = pyproject.read_text(errors="ignore") if pyproject.exists() else ""
if not proof["test"]:
    if (target / "pytest.ini").exists() or "[tool.pytest" in pyproject_text:
        proof["test"] = "python3 -m pytest"
        proof_sources["test"] = "pytest config"
if not proof["lint"]:
    if (target / "ruff.toml").exists() or "[tool.ruff" in pyproject_text:
        proof["lint"] = "python3 -m ruff check ."
        proof_sources["lint"] = "ruff config"


def update_config(path: Path) -> None:
    lines = path.read_text().splitlines()
    out = []
    in_proof = False
    for raw in lines:
        stripped = raw.strip()
        if raw.startswith("proof:"):
            in_proof = True
            out.append(raw)
            continue
        if in_proof and raw and not raw.startswith((" ", "\t")):
            in_proof = False
        if in_proof:
            match = re.match(r"^(\s*)(test|build|lint):", raw)
            if match:
                key = match.group(2)
                out.append(f"{match.group(1)}{key}: {json.dumps(proof[key])}")
                continue
        if stripped.startswith("trusted_actors:"):
            trusted = [gh_user] if gh_user else []
            out.append(f"trusted_actors: {json.dumps(trusted)}")
            continue
        out.append(raw)
    path.write_text("\n".join(out) + "\n")


update_config(tmp / "config.yaml")

repo = {}
if repo_json_raw:
    try:
        repo = json.loads(repo_json_raw)
    except json.JSONDecodeError:
        repo = {}

instructions = []
for rel in (
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "CONTRIBUTING.md",
    ".github/copilot-instructions.md",
):
    if (target / rel).exists():
        instructions.append(rel)

default_branch = ""
if isinstance(repo.get("defaultBranchRef"), dict):
    default_branch = repo["defaultBranchRef"].get("name") or ""

trusted_text = gh_user if gh_user else "(none discovered)"
repo_name = repo.get("nameWithOwner") or "(not discovered)"
visibility = repo.get("visibility") or "(not discovered)"
permission = repo.get("viewerPermission") or "(not discovered)"
issues_enabled = repo.get("hasIssuesEnabled")
issues_text = str(issues_enabled).lower() if isinstance(issues_enabled, bool) else "(not discovered)"

proof_lines = "\n".join(
    f"  - {key}: {proof[key] or '(blank)'}"
    + (f" ({proof_sources[key]})" if proof_sources[key] else "")
    for key in ("test", "build", "lint")
)
proof_note_lines = "\n".join(f"  - {item}" for item in proof_notes) or "  - (none)"
instruction_lines = "\n".join(f"  - {item}" for item in instructions) or "  - (none discovered)"

missing_proof = [key for key, value in proof.items() if not value]
human_gates = []
if not guided:
    human_gates.append("Create required labels by running .agent-loops/setup-labels.sh.")
if missing_proof:
    human_gates.append(
        "Fill missing proof commands before expecting autonomous convergence: "
        + ", ".join(missing_proof)
        + "."
    )
if not gh_user:
    human_gates.append("Authenticate GitHub CLI if trusted_actors should include the operator.")

human_gate_lines = "\n".join(f"  - {item}" for item in human_gates)
if not human_gate_lines:
    human_gate_lines = "  - (none for guided setup)"
required_label_text = (
    "guided setup will create/update labels before doctor"
    if guided
    else "not mutated; run `.agent-loops/setup-labels.sh`"
)
doctor_text = (
    "guided setup will run `.agent-loops/doctor.sh` after labels exist"
    if guided
    else "run `.agent-loops/doctor.sh` after labels exist and before arming the supervisor"
)
critical_label_text = (
    "GitHub labels are created/updated by guided setup."
    if guided
    else "GitHub labels are not created by bootstrap."
)
guided_action_lines = (
    "- Completed by setup:\n"
    "  - Labels: create/update via `.agent-loops/setup-labels.sh`\n"
    "  - Doctor: run `.agent-loops/doctor.sh`\n"
    "  - Smoke issue: create from `.agent-loops/FIRST-TRIAL-ISSUE.md`\n"
    "  - Supervisor: run `.agent-loops/runners/local-supervisor.sh --once \"$PWD\"`\n"
    "  - Smoke cleanup: on success, close smoke issue/PR artifacts and delete the smoke branch\n"
    + ("  - Managed watch: start `.agent-loops/runners/local-supervisor.sh --background \"$PWD\"`\n" if arm else "")
    if guided
    else "- Completed by setup: render `.agent-loops/` only; no GitHub mutation or supervisor tick requested"
)

report = f"""# Autonomous Work Loops Bootstrap Report

- Host: GitHub
- Target repo path: {target}
- GitHub repo: {repo_name}
- Default branch: {default_branch or '(not discovered)'}
- Visibility: {visibility}
- Viewer permission: {permission}
- Issues enabled: {issues_text}
- Authenticated GitHub user: {gh_user or '(not discovered)'}
- GitHub auth status: {gh_status}
- Trust posture: strict
- Trusted actors: {trusted_text}
- Required labels: {required_label_text}
- Proof commands:
{proof_lines}
- Proof notes:
{proof_note_lines}
- Context:
  - repo instructions:
{instruction_lines}
  - generated paths:
    - `.agent-loops/config.yaml`
    - `.agent-loops/context.md`
    - `.agent-loops/runners/`
    - `.agent-loops/playbooks/`
    - `.agent-loops/evidence/inbox/`
  - repo-specific rules: read discovered instruction files before every tick
- Doctor: {doctor_text}
- First trial issue: `.agent-loops/FIRST-TRIAL-ISSUE.md`
- Normal setup command:
  - one-command arm path: `{assets_dir}/bootstrap.sh --arm "{target}"`
  - rerun behavior: if `.agent-loops/` already exists, `--arm` resumes setup without creating another smoke issue
  - cleanup: successful first-run smoke artifacts are closed and the smoke branch is deleted after proof; failed smoke artifacts stay open for diagnosis
- Recovery/debug commands:
  - one-command guided path: `{assets_dir}/bootstrap.sh --guided "{target}"`
  - `gh issue create --title "Add one tiny tested change to prove autonomous-work-loops is wired correctly" --body-file .agent-loops/FIRST-TRIAL-ISSUE.md --label ready`
  - `.agent-loops/runners/local-supervisor.sh --once "$PWD"`
  - watch mode after the smoke test: `.agent-loops/runners/local-supervisor.sh --watch --interval 600 "$PWD"`
  - managed background watch after the smoke test: `.agent-loops/runners/local-supervisor.sh --background "$PWD"`
{guided_action_lines}
- Runner: managed local supervisor at `.agent-loops/runners/local-supervisor.sh`
  - shared guarded runner body: `.agent-loops/runners/guarded-role-runner-common.sh`
- Credentials: runner uses local shell credentials; bootstrap did not install cron, launchd, Actions schedules, Codex Automations, or Claude `/loop`
- Budgets: default V1 budgets retained in `.agent-loops/config.yaml`
- Reviewer model: blank, meaning same-model adversarial review unless changed in config
- Critical decisions:
  - Existing `.agent-loops` is preserved unless bootstrap runs with `--force`; guided and armed setup resume it.
  - Strict trust is retained as the conservative default.
  - Missing proof commands are left blank rather than guessed.
  - {critical_label_text}
- Human gates:
{human_gate_lines}
"""

(tmp / "BOOTSTRAP-REPORT.md").write_text(report)
PY

chmod +x "$tmp/setup-labels.sh" "$tmp/doctor.sh" "$tmp/runners/"*.sh

if [ -e "$dest" ]; then
  rm -rf "$dest"
fi
mv "$tmp" "$dest"
trap - EXIT
else
  for required in "$dest/setup-labels.sh" "$dest/doctor.sh" "$dest/runners/local-supervisor.sh"; do
    if [ ! -f "$required" ]; then
      printf 'existing %s is missing required file: %s\n' "$dest" "$required" >&2
      printf 'rerun with --force to replace the incomplete setup.\n' >&2
      exit 1
    fi
  done
  chmod +x "$dest/setup-labels.sh" "$dest/doctor.sh" "$dest/runners/"*.sh 2>/dev/null || true
fi

if git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_dir="$(git -C "$target" rev-parse --absolute-git-dir)"
  exclude_file="${git_dir}/info/exclude"
  if mkdir -p "$(dirname "$exclude_file")" 2>/dev/null && touch "$exclude_file" 2>/dev/null; then
    if [ ! -w "$exclude_file" ]; then
      printf 'warn: could not update %s; .agent-loops/ will remain untracked locally, but generated runners still refuse to stage it.\n' "$exclude_file" >&2
    else
      exclude_ok=1
      if ! grep -Fxq ".agent-loops/" "$exclude_file"; then
        {
          printf '\n%s\n' "# autonomous-work-loops local runtime files"
          printf '%s\n' ".agent-loops/"
        } >> "$exclude_file" || exclude_ok=0
      fi
      if ! grep -Fxq ".agent-loops.tmp.*/" "$exclude_file"; then
        printf '%s\n' ".agent-loops.tmp.*/" >> "$exclude_file" || exclude_ok=0
      fi
      if [ "$exclude_ok" -ne 1 ]; then
        printf 'warn: could not update %s; .agent-loops/ will remain untracked locally, but generated runners still refuse to stage it.\n' "$exclude_file" >&2
      fi
    fi
  else
    printf 'warn: could not update %s; .agent-loops/ will remain untracked locally, but generated runners still refuse to stage it.\n' "$exclude_file" >&2
  fi
fi

if [ "$reused_existing" -eq 1 ]; then
  printf 'using existing %s\n' "$dest"
else
  printf 'bootstrapped %s\n' "$dest"
fi
printf 'guided: %s --guided "%s"\n' "${assets_dir}/bootstrap.sh" "$target"
printf 'guided and armed: %s --arm "%s"\n' "${assets_dir}/bootstrap.sh" "$target"
printf 'manual labels: %s\n' "${dest}/setup-labels.sh"
printf 'manual doctor: %s\n' "${dest}/doctor.sh"
printf 'manual smoke issue (fresh setup only): gh issue create --title "%s" --body-file .agent-loops/FIRST-TRIAL-ISSUE.md --label ready\n' "Add one tiny tested change to prove autonomous-work-loops is wired correctly"
printf 'manual one-shot: %s --once "$PWD"\n' "${dest}/runners/local-supervisor.sh"
printf 'background supervisor: %s --background "$PWD"\n' "${dest}/runners/local-supervisor.sh"
printf 'watch later: %s --watch --interval 600 "$PWD"\n' "${dest}/runners/local-supervisor.sh"

if [ "$guided" -eq 1 ]; then
  if [ "$allow_incomplete" -eq 1 ]; then
    printf '%s\n' '--guided/--arm cannot run with --allow-incomplete because it mutates GitHub and starts a tick.' >&2
    exit 2
  fi
  printf 'guided setup: creating/updating labels\n'
  (cd "$target" && "$dest/setup-labels.sh")
  printf 'guided setup: running doctor\n'
  (cd "$target" && "$dest/doctor.sh")
  printf 'guided setup: preflighting role runner\n'
  (cd "$target" && "$dest/runners/local-supervisor.sh" --preflight-runner "$target")
  if [ "$reused_existing" -eq 1 ]; then
    printf 'guided setup: existing .agent-loops detected; not creating a duplicate smoke issue\n'
    if [ "$arm" -eq 1 ]; then
      printf 'guided setup: starting managed background supervisor\n'
      (cd "$target" && "$dest/runners/local-supervisor.sh" --background "$target")
      printf 'guided setup: autonomous-work-loops is armed for this repo\n'
      printf 'guided setup: create trusted GitHub issues and add label ready\n'
      printf 'guided setup: supervisor status: %s --status "%s"\n' "$dest/runners/local-supervisor.sh" "$target"
      printf 'guided setup: supervisor stop: %s --stop "%s"\n' "$dest/runners/local-supervisor.sh" "$target"
    else
      printf 'guided setup: running one supervisor tick on existing setup\n'
      (cd "$target" && "$dest/runners/local-supervisor.sh" --once "$target")
    fi
    exit 0
  fi
  printf 'guided setup: creating smoke issue\n'
  smoke_issue_url="$(cd "$target" && gh issue create --title "Add one tiny tested change to prove autonomous-work-loops is wired correctly" --body-file .agent-loops/FIRST-TRIAL-ISSUE.md --label ready)"
  printf 'guided setup: created %s\n' "$smoke_issue_url"
  smoke_issue="${smoke_issue_url##*/}"
  repo_slug="$(cd "$target" && gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
  printf 'guided setup: waiting for smoke issue #%s to be visible with label ready\n' "$smoke_issue"
  deadline=$(( $(date +%s) + 60 ))
  while true; do
    if (cd "$target" && gh issue view "$smoke_issue" --json labels --jq '.labels[].name' | grep -Fxq ready); then
      break
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      if [ -n "$repo_slug" ]; then
        failure_body="autonomous-work-loops guided setup created this smoke issue, but GitHub did not report it with the ready label before the setup timeout. Inspect the issue labels and rerun bootstrap with --arm after GitHub state settles."
        (cd "$target" && gh issue comment "$smoke_issue" --repo "$repo_slug" --body "$failure_body" >/dev/null 2>&1 || true)
        (cd "$target" && gh issue edit "$smoke_issue" --repo "$repo_slug" --remove-label ready >/dev/null 2>&1 || true)
        (cd "$target" && gh issue edit "$smoke_issue" --repo "$repo_slug" --add-label stalled >/dev/null 2>&1 || true)
        printf 'guided setup: marked smoke issue #%s as stalled after visibility timeout\n' "$smoke_issue" >&2
      fi
      printf 'guided setup: smoke issue #%s was not visible with label ready before timeout\n' "$smoke_issue" >&2
      exit 1
    fi
    sleep 2
  done
  printf 'guided setup: running one supervisor tick\n'
  supervisor_rc=0
  (cd "$target" && "$dest/runners/local-supervisor.sh" --once "$target") || supervisor_rc=$?
  branch="loop/impl/issue-${smoke_issue}"
  pr_url=""
  pr_number=""
  issue_labels=""
  issue_label_names=""
  if [ -n "$repo_slug" ]; then
    pr_url="$(cd "$target" && gh pr list --repo "$repo_slug" --state all --head "$branch" --json url --jq '.[0].url // empty' 2>/dev/null || true)"
    pr_number="$(cd "$target" && gh pr list --repo "$repo_slug" --state all --head "$branch" --json number --jq '.[0].number // empty' 2>/dev/null || true)"
    issue_labels="$(cd "$target" && gh issue view "$smoke_issue" --repo "$repo_slug" --json labels --jq '[.labels[].name] | join(", ")' 2>/dev/null || true)"
    issue_label_names="$(cd "$target" && gh issue view "$smoke_issue" --repo "$repo_slug" --json labels --jq '.labels[].name' 2>/dev/null || true)"
  fi
  printf 'guided setup: issue #%s labels: %s\n' "$smoke_issue" "${issue_labels:-'(unknown)'}"
  if [ -n "$pr_url" ]; then
    printf 'guided setup: PR: %s\n' "$pr_url"
  else
    printf 'guided setup: no PR was opened; inspect issue #%s and .agent-loops/evidence/prove-the-gate/logs/\n' "$smoke_issue"
  fi
  if [ "$supervisor_rc" -ne 0 ]; then
    if [ -n "$repo_slug" ]; then
      failure_body="autonomous-work-loops guided setup created this smoke issue, but the one-shot supervisor exited with ${supervisor_rc} before the repo could be armed. Inspect .agent-loops/evidence/prove-the-gate/logs/ locally, then rerun .agent-loops/runners/local-supervisor.sh --status \"$target\" or bootstrap with --arm again after fixing setup."
      (cd "$target" && gh issue comment "$smoke_issue" --repo "$repo_slug" --body "$failure_body" >/dev/null 2>&1 || true)
      (cd "$target" && gh issue edit "$smoke_issue" --repo "$repo_slug" --remove-label ready >/dev/null 2>&1 || true)
      (cd "$target" && gh issue edit "$smoke_issue" --repo "$repo_slug" --remove-label in-progress >/dev/null 2>&1 || true)
      (cd "$target" && gh issue edit "$smoke_issue" --repo "$repo_slug" --add-label stalled >/dev/null 2>&1 || true)
      printf 'guided setup: marked smoke issue #%s as stalled after setup failure\n' "$smoke_issue" >&2
    fi
    printf 'guided setup: supervisor exited with %s; setup needs attention before watch mode.\n' "$supervisor_rc" >&2
    exit "$supervisor_rc"
  fi
  if [ -n "$repo_slug" ] && printf '%s\n' "$issue_label_names" | grep -Eq '^(ready-for-human|ready-for-human-baseline-red)$'; then
    cleanup_comment="autonomous-work-loops setup smoke succeeded and is being cleaned up. Future work starts from normal trusted issues labeled ready."
    printf 'guided setup: cleaning successful smoke artifacts for issue #%s\n' "$smoke_issue"
    default_branch="$(cd "$target" && git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p' || true)"
    if [ -n "$default_branch" ]; then
      (cd "$target" && git switch "$default_branch" >/dev/null 2>&1 || git switch -C "$default_branch" "origin/${default_branch}" >/dev/null 2>&1 || true)
    fi
    if [ -n "$pr_number" ]; then
      (cd "$target" && gh pr close "$pr_number" --repo "$repo_slug" --comment "$cleanup_comment" --delete-branch >/dev/null 2>&1 || true)
      printf 'guided setup: closed smoke PR #%s and requested branch deletion\n' "$pr_number"
    else
      (cd "$target" && git push origin --delete "$branch" >/dev/null 2>&1 || true)
      printf 'guided setup: deleted smoke branch %s when present\n' "$branch"
    fi
    (cd "$target" && gh issue close "$smoke_issue" --repo "$repo_slug" --comment "$cleanup_comment" >/dev/null 2>&1 || true)
    printf 'guided setup: closed smoke issue #%s\n' "$smoke_issue"
    {
      printf '\n## Smoke Cleanup\n\n'
      printf '- Smoke issue: #%s closed after successful setup proof.\n' "$smoke_issue"
      if [ -n "$pr_number" ]; then
        printf '- Smoke PR: #%s closed after successful setup proof.\n' "$pr_number"
      fi
      printf '- Smoke branch: `%s` delete requested.\n' "$branch"
    } >> "$dest/BOOTSTRAP-REPORT.md"
  else
    printf 'guided setup: leaving smoke artifacts open because setup did not reach a successful handoff label\n'
  fi
  if [ "$arm" -eq 1 ]; then
    printf 'guided setup: starting managed background supervisor\n'
    (cd "$target" && "$dest/runners/local-supervisor.sh" --background "$target")
    printf 'guided setup: autonomous-work-loops is armed for this repo\n'
    printf 'guided setup: create trusted GitHub issues and add label ready\n'
    printf 'guided setup: supervisor status: %s --status "%s"\n' "$dest/runners/local-supervisor.sh" "$target"
    printf 'guided setup: supervisor stop: %s --stop "%s"\n' "$dest/runners/local-supervisor.sh" "$target"
  fi
fi
