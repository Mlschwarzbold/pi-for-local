# pi-for-local

A deliberately small [pi](https://pi.dev) profile for testing how small local
models cope with a minimal harness: short system prompt, three tool definitions,
no packages, no skills.

Use it as a template — clone it, point it at whatever OpenAI-compatible server
you run, and change one knob at a time.

## Quickstart

```bash
git clone <this-repo> pi-for-local && cd pi-for-local
./run.sh                 # TUI; first run seeds agent/models.json from the example
```

Requires `pi` on your `PATH` (tested with 1.4.0). Override with
`PI_BIN=/path/to/pi ./run.sh`.

Before the first useful run, point the profile at a server — either edit
`agent/models.json` (created on first launch) or run your own server on the
default `http://127.0.0.1:8080/v1`:

```bash
# llama.cpp, one model, with tool-call templates
llama-server -m ~/models/Qwen3-8B-Q4_K_M.gguf --jinja \
             --host 127.0.0.1 --port 8080 -ngl 999 -c 32768

# or ollama
ollama serve   # OpenAI-compatible endpoint on 127.0.0.1:11434/v1

# or a llama.cpp router over a model dir
llama-server --models-dir ~/models --no-models-autoload --jinja \
             --host 127.0.0.1 --port 8199 -ngl 999 -c 32768
```

Any OpenAI-compatible server works: change `baseUrl`, `apiKey`, `authHeader`
and `models[].id` in `agent/models.json`. Keep the provider key (`local`) in
sync with `defaultProvider` in `agent/settings.json`, or rename both.

Handy alias:

```bash
alias pi-local="$PWD/run.sh"
```

## Why a separate agent dir

pi combines resource lists across the agent dir and project settings
([docs/settings.md](https://pi.dev/docs/settings)), and extensions cannot unload
each other. A normal profile with subagents, web access, context viewers, … keeps
injecting its prompt text and tool definitions no matter what a project or
extension disables. Isolation therefore has to happen one level up, at the agent
dir — which is what `run.sh` sets via `PI_CODING_AGENT_DIR`.

## Layout

```
pi-for-local/
├── run.sh                    launcher: PI_CODING_AGENT_DIR + pinned-ish pi binary
└── agent/                    <- PI_CODING_AGENT_DIR
    ├── settings.json         packages: [], 3 builtin extensions off, 3 tools
    ├── SYSTEM.md             replaces pi's default system prompt
    ├── models.example.json   template for your OpenAI-compatible endpoint
    ├── extensions/           custom harness extensions (empty by default)
    └── .gitignore            runtime state (auth, sessions, npm, per-machine config)
```

Not in the repo, created locally by you or by pi: `agent/models.json`,
`agent/auth.json`, `agent/sessions/`, `agent/npm/`, `agent/trust.json`.

## Experiment knobs

| Knob | Where | Question it answers |
|---|---|---|
| `SYSTEM.md` | `agent/` | Does the model need the rules at all, and which ones? |
| `defaultTools` | `agent/settings.json` | How many tool schemas can it keep straight? |
| `--tools`/`--exclude-tools` | CLI | Per-run tool ablation without editing settings |
| `PI_LOCAL_BARE=1` | env | Floor: no extensions, no skills at all |
| `PI_LOCAL_SKILLS=1` | env | Re-enable skill discovery (`agent/skills/` + `~/.agents/skills/`, +~600 tok) |
| `PI_LOCAL_CONTEXT=0` | env | Drop AGENTS.md/CLAUDE.md context files (on by default, -~430 tok) |
| `PI_LOCAL_PROJECT=1` | env | Trust project `.pi/` settings |
| `extensions/` | `agent/` | Does a custom tool beat describing the same thing in prose? |
| `PI_BIN` | env | A/B a different pi version against the same harness |

Measure before changing: `/context` and the footer token count show what the
harness itself costs. `/context` comes from the `pi-context-view` package, which
is deliberately not installed here; add it back for a measurement session:

```bash
# agent/settings.json
"packages": ["npm:pi-context-view"]
```

Ground truth for this profile, measured by pointing `models.json` at a capture
server and reading the request body:

| Configuration | System prompt | Tools |
|---|---|---|
| default | ~175 tok + context files (AGENTS.md) | `read`, `bash`, `edit` |
| `PI_LOCAL_CONTEXT=0` | ~175 tok | same |
| `PI_LOCAL_SKILLS=1` | ~778 tok (without context files) | same |
| skills + context | ~1211 tok | same |

Context files (`AGENTS.md`) are on by default because they are the project's own
instructions; skills stay off because `~/.agents/skills/` is a global directory
that has nothing to do with the current project. `PI_LOCAL_BARE=1` drops both.

## Notes

- Thinking defaults to `high`, which small models sometimes burn their whole
  budget on. Try `defaultThinkingLevel: "medium"` or `--reasoning-level low`.
- `SYSTEM.md` lists exactly the three tools in `defaultTools`. If you add a tool
  (`+codemode`, an MCP server, an extension), update the prose too — otherwise
  the model is told a tool exists that does not, or vice versa. That mismatch is
  usually what makes a small model flail.
- Nothing here is pinned by version except the settings schema; `run.sh` uses
  whatever `pi` it finds first, so record the version when you publish numbers.
