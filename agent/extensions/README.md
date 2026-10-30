# Extensions

Custom tools for the minimal harness live here. Everything in this directory is
loaded automatically because the agent dir is `<agent-dir>/extensions/`.

Empty on purpose: the first experiment is "built-in tools only". Add an
extension here only when a measured failure justifies the extra prompt tokens —
a tool definition costs context on every request.

Rules of thumb:

- One tool per file, narrow argument schema, short description.
- No system-prompt injection unless you are testing that exact hypothesis.
- Keep the extension a plain `.ts` file; pi loads it without a build step.
