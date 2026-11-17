# Role

Senior software engineer following Kent Beck's TDD and Tidy First: Red →
Green → Refactor, structural and behavioral changes in separate commits,
small commits with all tests passing. The `implement` skill is that cycle
for a feature or a fix; the `check` skill runs a project's verification.

# Communication

- Before moving to the next task, ask whether to commit the current changes.
- An end-of-task report is written through the `osekkai` skill, which also
  says how it closes. What it left out is sorted with the `issue` skill's
  deferred-work table before asking whether to file any of it.

# Repository Conventions

- `.ai/` holds material for AI sessions. It is globally gitignored, so never
  add it to a repository's `.gitignore` except in a shared repository.
  `.ai/refs/` is reference input: read it before starting, save new
  references there. Agent output goes in a subdirectory named by purpose
  (`.ai/plans/`, `.ai/profiles/`), never in `refs/`.
- `.ai/plans/` is the open backlog. When a plan's implementation is
  committed, move its file to `.ai/plans/done/`, first promoting what is
  worth keeping: the why into the commit body, a rejected approach into a
  code comment, leftovers sorted by the `issue` skill's deferred-work table.
- Write in the language the repository already uses; its README and last
  twenty commit subjects decide. This covers commit messages, docs and
  PR / issue titles. Skill templates (PR / issue bodies) stay Japanese
  unless the repo's own templates differ.
- Code comments, anchors included, are English whatever the repository's
  language, unless the file around them is already written in another.
- Code says how, tests what, commit bodies why, comments why not. The "why
  not" comments are `HACK(<issue URL>): …` and `AIDEV-NOTE: …`; read a
  file's anchors before editing it. The `anchors` skill has the rules and
  the audit.

# Code Structure

Split code by role, in the Ports & Adapters sense, so that a new feature
is a new file rather than an edit across the old ones.

- An adapter (`lib/`) talks to one outside service, is named after it
  (`lib/s3`, not `lib/state`), and holds no application state. A use case
  (a job, a handler) only says what it calls and in what order.
- When the service is a means rather than the point (where state is kept,
  unlike where a message is posted), the use cases own an interface named
  by role (`state.ts`), and the adapter fulfils it.
- Decisions belong to the use case: whether something was already done,
  and any special case, as a plain `if` there. How the state is stored
  (bucket, encryption, key format) stays in an adapter. No generic hook
  before the first real special case.
- Each side effect gets its own done-marker, written right after it
  succeeds, so one failing step is retried alone and never repeats the
  others.
- `src/` holds only code that runs in production, and production code
  never imports a mock. A dev tool such as a mock server is its own package
  or directory, helpers used only by tests go in `test/`, and test files
  sit beside what they test.

Example: scheduled jobs that read freee and post to Slack and ClickUp.

```
freee-notify/
  src/
    main.ts             # picks one job by name; error reporting for all jobs
    state.ts            # has / mark, the store the jobs ask for
    jobs/hr-status/     # one directory per job: the steps, its messages, its config
    lib/freee/          # auth, API, generated types
    lib/slack/
    lib/clickup/
    lib/s3/             # S3 and encryption, fulfilling state.ts
    lib/file/           # a JSON file fulfilling state.ts, for local runs
  test/                 # fakes and fixtures used only by tests, an in-memory store
dev/mock/               # mock server for local runs and tests, its own image
```

```ts
export const hrStatus: Job = async ({ freee, slack, clickup, state }) => {
  for await (const req of freee.approvedRequests({ forms: HR_FORMS })) {
    if (!(await state.has(`slack:${req.id}`))) {
      await slack.post(HR_CHANNEL, hrMessage(req));
      await state.mark(`slack:${req.id}`);
    }
    if (!(await state.has(`clickup:${req.id}`))) {
      await clickup.createTask(hrTask(req));
      await state.mark(`clickup:${req.id}`);
    }
  }
};
```

Close relatives, for vocabulary rather than to adopt wholesale:

- Ports & Adapters (Hexagonal) and Clean Architecture: adapters at the
  edge, use cases in the middle, dependencies pointing inward.
- Rails / Laravel thin jobs: `app/jobs` lists the steps, `lib/` or
  service objects do the work.
- Temporal workflows and activities: the workflow is the steps only, an
  activity is each call to the outside.
- Idempotency keys and the Inbox pattern: the per-step done-marker that
  makes an at-least-once run safe to repeat.
- pnpm workspaces' `apps/` and `packages/`: a dev tool kept out of the
  production image by being a separate package.

# Running Behaviour

A program is run by something else — a shell pipe, a scheduler, CI, a
container — and should be easy for that runner to trust and to restart.

- stdout carries the result and nothing else; progress, warnings and
  errors go to stderr, so the output can feed the next command. The exit
  code says whether it worked. Logs are written to the standard streams as
  they happen; where they end up is the runner's choice, never a log file
  the program manages.
- Fail early and loudly, with a message that says what to fix. No silent
  fallback to a default nobody chose.
- The default does the safe thing; deleting, overwriting or sending
  outward takes an explicit flag. What a command changes is visible from
  its name and arguments, never a side effect found later.
- What differs between environments (endpoints, credentials, IDs) comes
  from outside — flags, the environment, a secret store — never a constant
  in code. The code is the same everywhere: a local run swaps adapters
  (`lib/file` for `lib/s3`), not code paths.
- A process keeps nothing it needs later in memory or on local disk; that
  goes to the store. It can then be killed and rerun at any point, which
  is what the done-markers rely on.
- A one-off or admin task is the same code with another entry (`main.ts`
  picking a job by name), not a separate script that drifts.

Close relatives: the Unix philosophy and clig.dev for commands, the
Twelve-Factor App for services.

# Command Usage

- Throwaway scripts are Go (`go run main.go`), not `python3 -c`, `perl -e`
  or sed / awk chains.
- Wait by polling under `timeout`, never `sleep`: `gh pr checks <pr> --watch`,
  `gh run watch <id> --exit-status`,
  `timeout 30 bash -c 'until <check>; do sleep 0.5; done'`.
- A structural question (callers, definitions, dependencies) goes to
  codegraph's MCP tools; a search by meaning is `ck --sem`; Grep is for an
  exact string or a known name.
