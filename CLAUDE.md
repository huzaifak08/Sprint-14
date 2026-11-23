## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. When the answer is under a Markdown heading, `graphify section "<heading>"` prints that section's text, so the .md need not be opened. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.

## Codebase Navigation & Token Discipline

`graphify-out/` is gitignored and built locally. If it's missing (fresh clone), run `pip install -U graphifyy && graphify hook install && graphify update .` first.

a) **Graph first.** Before any broad `Glob`, `Grep`, or multi-file `Read`, query the graph: `graphify query "<question>"`, `graphify explain "<symbol>"`, `graphify path "<A>" "<B>"`. For architecture overviews, skim `graphify-out/GRAPH_REPORT.md` (Community Hubs / god nodes). `graphify-out/graph.json` is ~2 MB: never `Read` it whole; go through the `graphify` CLI, or `jq`/grep for specific node ids.
b) **Targeted reads only.** Never read whole directories or large files blindly. Use the `src=` path and `loc=L<n>` that graph results return, and `Read` with `offset`/`limit` around that line. Skip generated/platform folders (`build/`, `.dart_tool/`, `ios/Pods/`, `**/GeneratedPluginRegistrant.*`) unless the task is about them.
c) **Keep the graph fresh.** Git hooks (post-commit/checkout/merge/rewrite) rebuild it automatically. After adding, renaming, moving or deleting files, classes, providers or modules, and before you commit, run `graphify update .` (AST-only, ~3 s, zero LLM calls) so later queries in the same session see the change.
