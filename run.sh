#!/usr/bin/env bash
# Minimal pi harness for small local models.
# Runs pi against an isolated agent dir so no package, skill, prompt, theme or
# session from your other profiles leaks in.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Isolated config dir: settings.json, SYSTEM.md, models.json, sessions/.
# Always overridden: inheriting an outer PI_CODING_AGENT_DIR (e.g. when this is
# launched from another agent session) would silently reuse that profile.
# Set PI_LOCAL_AGENT_DIR to point somewhere else deliberately.
export PI_CODING_AGENT_DIR="${PI_LOCAL_AGENT_DIR:-$HERE/agent}"

# Drop session/provider variables inherited from an enclosing pi/agent process.
unset PI_SESSION_FILE PI_SESSION_ID PI_PROVIDER PI_MODEL PI_REASONING_LEVEL \
      PI_CODING_AGENT PI_SUBAGENTS_PI_CODING_AGENT_PACKAGE_ROOT \
      PI_SUBAGENTS_TEMP_ROOT PENDANT_SDK_WORKER_GENERATION 2>/dev/null || true

# First run: seed models.json from the example so the profile is usable as-is.
# Edit $PI_CODING_AGENT_DIR/models.json afterwards to point at your own server.
if [[ ! -f "$PI_CODING_AGENT_DIR/models.json" && -f "$PI_CODING_AGENT_DIR/models.example.json" ]]; then
  cp "$PI_CODING_AGENT_DIR/models.example.json" "$PI_CODING_AGENT_DIR/models.json"
  echo "pi-for-local: created models.json from models.example.json" >&2
  echo "pi-for-local: edit $PI_CODING_AGENT_DIR/models.json (baseUrl, models[].id)" >&2
fi

# pi from PATH. Override with PI_BIN=/path/to/pi to A/B a different version.
PI_BIN="${PI_BIN:-pi}"

args=()

# Skills are discovered from `~/.agents/skills/` and the working-directory tree.
# That location is not inside the agent dir, so an "isolated" profile inherits
# them anyway; the index costs ~600 tokens, so it is off unless asked for.
[[ "${PI_LOCAL_SKILLS:-0}" == "1" ]] || args+=(--no-skills)
# Context files (AGENTS.md/CLAUDE.md) are ON by default: they are the project's
# own instructions and the main reason to run this profile inside a repo. Set
# PI_LOCAL_CONTEXT=0 for a baseline run without them (~430 tokens in a
# repo that ships one).
[[ "${PI_LOCAL_CONTEXT:-1}" == "1" ]] || args+=(--no-context-files)
args+=(--no-prompt-templates)

# Project `.pi/` settings load only for trusted projects. Trusted project
# settings can add tools to this profile's list, so trust is opt-in to keep the
# baseline deterministic.
[[ "${PI_LOCAL_PROJECT:-0}" == "1" ]] || args+=(--no-approve)

# PI_LOCAL_BARE=1 drops every extension and skill, including agent-dir ones.
# Useful as the floor of the "how little harness can a model survive" ladder.
if [[ "${PI_LOCAL_BARE:-0}" == "1" ]]; then
  args+=(--no-extensions --no-skills --no-context-files)
fi

exec "$PI_BIN" "${args[@]}" "$@"
