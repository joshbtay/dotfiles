# Response style

As terse as possible. All technical substance should stay. Get rid of fluff.
Don't say things like: "Sure! I'd be happy to help you with that.", "Of course! Here's how you can do that.", "Sorry for the confusion", etc. Just get to the point.
End responses by asking if you should do a suggested next step, or if you have any other questions.
If you are unsure about what to do, ask for clarification. Don't make unreasonable assumptions, but feel free to make reasonable ones if it helps you move forward. If you make an assumption, state it explicitly.
Do not ever send a slack message, or suggest that you do so. I will never ask you to send a slack message.

# Code style

Avoid comments. A comment is justified only when the code cannot express a non-obvious fact or hazard that a competent reader would otherwise miss and could break — and it must read as a standalone statement about the code, not as an account of your work. Forbidden: describing what the code does, restating a name, and any narration of your reasoning — why you chose this approach, what you rejected, why it's done this way and not another, or why the change was made. That reasoning belongs in the PR description, never the source.
A comment must not restate any fact that code elsewhere already establishes or enforces — even when that code is in another file, and even when the current location (a config key, an enum entry, a flag definition) has no logic of its own. "A reader here can't see the behavior" is not a justification: a competent reader can follow the usage to the source, and a comment mirroring it is strictly worse than none, because the reader must now read the comment AND verify it against the usage to check it hasn't rotted. If a location genuinely needs orientation, that is a naming problem, not a comment problem.
Litmus test before keeping a comment: if its content could be made false by an edit to code you can point at (here or elsewhere), delete it — it is a duplicated source of truth that will drift. If it only makes sense to someone who saw your diff or the alternatives you weighed, delete it. Keep a comment only for a fact that no code anywhere expresses: an external constraint, a non-obvious hazard, or a "why" that isn't recoverable from the code at all.
Avoid duplicating code. If the same code needs to exist in multiple places, a reasonable attempt should be made to refactor it into a shared function or module.
Avoid keeping code around for "backwards compatibility". If something needs to truly be backwards compatible, I will explicitly tell you. Otherwise, feel free to remove or refactor old code as needed.
Avoid 1-liner functions that just call another function. If a function doesn't do anything other than call another function, consider just calling the second function directly.
Similarly, avoid assigning function calls to variables if the variable is used only once. Just call the function directly where it's needed. However, if assigning to a variable significantly improves readability, it's fine to do so.
In all cases, prioritize concise, clean code.
In tests, never use a timeout directly. For instance, in a javascript test, you would never do something like `await new Promise((resolve) => setTimeout(resolve, 50));` to wait for something to happen. Instead, use a proper waiting mechanism that waits for a specific condition to be true, or for a specific event to happen. This makes tests more reliable and less flaky.
Rollouts - Most changes should be gated behind a feature gate, experiment, or dynamic config. In general, I default to an experiment unless I specify otherwise, since experiments give us concrete metrics that catch regressions.

# Execution style

If a follow-up modifies only one attribute of a multi-attribute request, treat it as replacing only that attribute. Keep the other requested attributes intact unless explicitly cancelled.
If a file changes between edits, there is a good chance that I manually modified the file. Do not remove those changes unless they are causing problems, and then check with me first.
If I ask you to create, open, raise, or submit a PR, use the /pr skill.
Confirm the deliverable format before writing anything long-form. Especially when the request is a message I've relayed from someone else rather than my own words — "put together a page" in a forwarded Slack thread does not mean I want a page from you. Ask first; a wrong guess wastes the whole draft.
Validate before documenting. When the output depends on data you can query (Databricks, Splunk, SignalFx, an API), authenticate and run the queries BEFORE writing prose about the results. If auth is missing, ask for it at the start rather than drafting around it — unvalidated field names, table shapes, and "this metric exists" claims are wrong often enough that the draft has to be redone.
Several dotfiles in ~ (AGENTS.md, CLAUDE.md, ...) are symlinks into ~/dotfiles/. Edit refuses to write through a symlink, so resolve the real path with `readlink -f` first.

# Local code references

convo-ai/conversational-ai: ~/convo-ai/
afm/atlassian-frontend-monorepo: ~/atlassian/afm/master/
confluence backend/monolith: ~/confluence/

Other code may be found with bitbucket.

# Tools

## twg

A command line interface to the Atlassian Teamwork Graph and Cloud services. TWG is Atlassian's enterprise knowledge & context graph that continuously maps people, content, activities, and relationships across many work tools (Jira, Confluence, Bitbucket, etc.). It is useful for making authenticated calls to any Atlassian service.
For ANY request involving an Atlassian service (Jira, Confluence, Bitbucket, Compass, Trello, JSM, Atlassian Graph, etc.) — including reads like fetching a PR, issue, or page — use the `twg` CLI.
Code across the company's repositories can be searched with `twg search-code`.

Do NOT use any MCP server (e.g. bitbucket_cloud, Atlassian_Rovo) for these. This applies even when a matching MCP tool is available — prefer twg over it. Also, do NOT use a direct curl, since it WILL fail. use twg.

Run `twg help` if necessary to discover exact subcommands before calling.

### twg examples

To read a Bitbucket file from a URL like https://bitbucket.org/<workspace>/<repo>/src/<ref>/<path>, run `twg bitbucket repo file <path> --workspace <workspace> --repo <repo>
  --ref <ref>` (don't fetch the URL directly).

## agent-browser

Useful for frontend work, especially reproducing bugs and validating fixes. 

agent-browser - fast browser automation CLI for AI agents

Usage: agent-browser <command> [args] [options]
Can be run in --headed mode. 
To discover available commands and usage patterns, run:
`agent-browser skills get core --full`
Skills ship with the CLI (always version-matched) and include workflow patterns, ref/selector usage, and copy-paste examples. Prefer this over guessing commands from flag docs alone. 
skills [list]                List available skills
skills get core              Core usage guide (overview + common patterns)
skills get core --full       Include full command reference and templates
skills get <name>            Load a specialized skill (electron, slack, ...)
skills path [name]           Print skill directory path

## ops-sherpa

ops-sherpa is an extremely useful tool especially for gaining insights on company-specific information here at Atlassian. It can query many services, including:
Splunk
JSM (for alerts)
Pollinator
Bitbucket
SignalFx
Ops Jira (for HOT incidents)
Post Office
Commit Tracker
Micros Log Insights (to search load balancer logs)
Support Ticket PII Redaction
Clipboard utilities
Tome
Mailtracker
Impacts API (tenant impact analysis)

When querying a service, especially splunk, slauth authentication will sometimes be required. If you are required to authenticate via atlas slauth, please do so immediately, even if it means triggering an MFA prompt. Do not proceed without authenticating, estimating or attempting to retrieve data another way. Do not stop to warn me that I will need to approve the slauth request. Just do it, and I will approve the MFA prompt in my browser right away. If authentication fails, let me know immediately and we can troubleshoot together.

### The `sherpa` CLI

The ops-sherpa MCP server is not loaded in sessions. Reach it through the `sherpa` CLI instead — do NOT try to call ops-sherpa MCP tools, and do not run the server yourself.

`sherpa` wraps the MCP server as a background daemon and exposes all 91 tools as subcommands. Commands and flags are generated from the live server, so the CLI stays in sync with the package.

```
sherpa                      list all commands, grouped by service
sherpa help <cmd>           full tool description + every argument
sherpa <cmd> [args] [--flags]
```

Argument rules: positionals fill required args in order; flags are the kebab-cased schema keys (`--max-results 10`); arrays take comma-separated values or a repeated flag; a value of `-` reads stdin. Command names also accept snake_case, camelCase, or any unique prefix.

Useful aliases: `splunk`, `logs`, `lb-logs`, `alert`, `alerts`, `oncall`, `jql`, `issue`, `hot`, `commits`, `diff`, `pr-diff`, `file`, `owners`, `metrics`, `impact`, `slauth`, `clip`.

```
sherpa splunk 'search index=main error' --earliest-time -1h
sherpa jql 'project = JRACLOUD AND status = Open' --max-results 5
sherpa commits confluence-frontend --limit 10
sherpa hot HOT-12345
```

Global flags: `--json` (raw MCP result), `--sherpa-timeout <sec>`, `--verbose`. Other commands: `sherpa tools`, `sherpa raw <tool> '<json>'`, `sherpa daemon status|stop|restart|log`, `sherpa update`.

The daemon is kept alive by a launchd agent, so it needs no manual start — just run commands. It survives login and restarts on its own if it exits. `sherpa daemon install` re-installs the agent if it is ever removed.

## databricks

For analytics/event data (Socrates), use the `databricks` CLI against the Socrates workbench host `https://socrates-workbench-01.cloud.databricks.com`. If `databricks auth profiles` shows no valid profile, ask me to run `! databricks auth login --host https://socrates-workbench-01.cloud.databricks.com` — it's interactive, don't try to drive it yourself.

Run `databricks` inside the sandbox — it works. If it ever fails with `tls: failed to verify certificate: x509: OSStatus -26276`, the sandbox is blocking the Mach lookup of `com.apple.trustd.agent`, which Go-based CLIs need to verify TLS certificates; the fix is `sandbox.network.allowMachLookup: ["com.apple.trustd.agent"]` in `~/.claude/settings.json`, not disabling the sandbox. Settings hot-reload, so no restart is needed.

Pick a warehouse with `databricks warehouses list`, then run SQL through the Statements API:

```
databricks api post /api/2.0/sql/statements --json '{"warehouse_id":"<id>","statement":"<sql>","wait_timeout":"50s","format":"JSON_ARRAY","disposition":"INLINE"}'
```

`wait_timeout` maxes out at 50s. Anything slower comes back `PENDING` with a `statement_id` — poll `GET /api/2.0/sql/statements/<id>` until the state is `SUCCEEDED`. Write a small python runner that submits, polls, and prints rows rather than hand-assembling JSON per query, and pass the SQL via a file — shell quoting of SQL is a constant source of breakage.

Canonical Socrates event tables: `production.analyticsplat.event_{track,ui,screen,operational}` (`staging.*` for non-prod, 30-day retention). GASv3 track events land in `event_track`, operational events in `event_operational` — check the code for which stream an event is sent on, since it's easy for an event to have moved between them.

Query rules:
- **Always filter on `day`** (the partition column) or the query runs effectively forever.
- Use **equality predicates** on `action_subject` / `action` / `source` / `product`. `LIKE '%foo%'` on those columns does not prune and will time out on these tables even with a `day` filter.
- `attributes` is `map<string,string>` — cast numerics, compare booleans to `'true'`/`'false'`.
- Spark rejects `PARTITION BY attributes['k']` in a window when `attributes['k']` is also the `GROUP BY` expression (`MISSING_AGGREGATION`). Alias the lookup in a CTE first.
- Run `DESCRIBE <table>` once before adapting a query — don't guess column names or casing.

Never present query results without first running a sanity count over the date range and confirming the events exist. Missing events are common (unregistered in the Data Portal Event Registry, renamed attributes, a stream cutover mid-window), and a query returning 0 rows looks identical to a metric genuinely being 0.

# Other context

My name (the user) is Josh Taylor. When you see people refer to "Josh" in messages, you know they will be talking about me. You should refer to me as "you" in your responses, and refer to yourself as "I".

# Reflect

After a session, reflect on how it went. Think about how we could have reached resolution state faster, with less back-and-forth. Suggest things that I could do differently, and suggest improvements to the above guidelines. These guidelines can be found in ~/AGENTS.md.

Almost always, I will tee out server logs to the repository's root directory, to ./tmp.log. Check there first if you need to see logs.
