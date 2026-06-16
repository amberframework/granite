---
name: pre-review
description: Self-review checklist to run BEFORE opening or updating a PR against Granite. Use it whenever you (or an AI assistant) are about to push a branch and open or refresh a pull request — it grades your own change against the Granite Review Rubric so CI is green and a maintainer's first pass finds nothing avoidable. Use when about to open a PR, update an existing PR, or check whether a change is ready to submit.
---

# Pre-review: grade your own PR before a maintainer does

You are about to open or update a PR against Granite. Run this procedure first. The
cheapest review note is the one you never trigger. The rubric below is the source
of truth — this skill is just the contributor lens on it.

- Severity framework, per-type bars, enhancement-vs-feature values: **[REVIEW_RUBRIC.md](../../REVIEW_RUBRIC.md)** (canonical — do not duplicate it here).
- Intentional trade-offs you should NOT "fix": **[DESIGN_DECISIONS.md](../../DESIGN_DECISIONS.md)**. Scan it before touching anything that looks like a bug — you may be undoing a settled decision (parameterized values, multi-adapter parity, the concurrency-safe pool, the Crystal version floor).

Work the steps in order. Don't skip a checkbox because it "looks obvious" — that
is exactly where the AI-PR wave failed.

## 1. Classify your PR type

Pick exactly one and write it in the PR description. The type sets your bar (rubric §3).

- [ ] **Bugfix** — fixes incorrect behavior.
- [ ] **Security** — closes a real, reachable vulnerability.
- [ ] **Performance** — same behavior, faster.
- [ ] **Refactor** — same behavior, cleaner code.
- [ ] **Feature / default-change** — new surface area or a changed default / emitted SQL / cross-adapter behavior.

If it's an **enhancement vs a new feature**, decide which (rubric §4). A *new feature*
(a new adapter, a new query-builder method, a new public-API knob, a new association
option) should usually **start as an issue/discussion** for design buy-in before you
build it — not a drive-by PR.

## 2. Make the description match the code

This is the single most common wave failure: the PR text describes intent, not the diff.

- [ ] Read your own `git diff` and write the description from what the code **actually does**.
- [ ] Grep your claims against the diff — every "fixes X", "adds Y", "no behavior change"
      must be visible in the changed lines.
- [ ] Remove aspirational language ("should", "intended to") for things the code doesn't do.

## 3. One concern, minimal diff

- [ ] Exactly one concern. No bundling a security fix with a refactor with a rename.
- [ ] No unrelated drive-by edits, reformatting of untouched code, or dependency bumps.
- [ ] Smaller is better — small diffs review faster and revert cleaner.

## 4. Meet your per-type bar (rubric §3)

State which bar you're submitting against, then clear it with **evidence, not vibes**.

**Bugfix** — a spec that's **red before the fix, green after**; fix the root cause, not the
symptom; note what else calls this path and confirm the fix holds across sqlite/mysql/pg.

**Refactor** — the existing suite passes **unchanged across all three adapters**. If you had
to edit a spec's *assertions*, it is not a pure refactor — reclassify it. No public-API /
default / emitted-SQL changes ride along.

**Performance** — perf is the highest-risk "looks fine" category. You must prove it's
**behavior-identical**. Fill in a differential edge-case table in the PR description and
verify each row with a real spec — green happy-path specs tell you nothing about edges, and
**green on one adapter tells you nothing about the other two**:

| Case | Old behavior | New behavior | Same? |
|---|---|---|---|
| emitted SQL for a normal `where` | SQL string + bound params | SQL string + bound params | yes |
| per adapter (sqlite / mysql / pg) | `?` vs `$n` placeholders, dialect | … | **must verify on all three** |
| NULL handling (`IS NULL` vs `= ?`) | … | … | **must verify** |
| empty result set / empty `IN ()` | … | … | **must verify** |
| malformed / out-of-range value | … | … | **must verify** |

(The classic perf trap: a change that looks semantically identical but diverges on one
adapter's dialect — sqlite's `?` vs pg's `$n`, a `RETURNING` clause, the quoting char — or on
an edge value like NULL or an empty array, while the suite stays green on the sqlite happy
path.) Include a before/after benchmark (method + hardware) justifying the change.

**Security** — clear **all** of these and write an **honest severity self-assessment**
using the three levers (rubric §2): **(a) reachability** — name the real
attacker-reachable sink AND state whether the immediate caller already `rescue`s it, or
whether the value already runs through `add_parameter` (so it's bound, not interpolated);
remember the consuming **app** sits between the attacker and most of Granite's surface;
**(b) threat model** — local dev/CLI or a generator/migration script the operator runs
(operator is the attacker → Low) vs a query-builder method an app feeds request-derived
input into; **(c) environment gating** — production query path vs spec-support / fixture /
dev-only-generator code that never runs in a deployed app. Don't over-state: a path that
raises on malformed input but is already `rescue`d at its reachable caller is
Informational/Low, not High.

- [ ] Real + reachable + not-already-mitigated (apply levers a–c above).
- [ ] **Complete fix** — no leftover vector. The norm in Granite is **bound parameters**:
      route the untrusted value through `add_parameter` so it runs as
      `db.exec sql, args: numbered_parameters`, never interpolated into the SQL string. For an
      **identifier** (table/column name) use a strict allow-list — `quote(name)`
      (`src/adapter/base.cr`) only wraps the name in the adapter's quoting char and does **not**
      escape an embedded quote, so it is not a sanitizer for attacker-controlled identifiers.
- [ ] **Narrow fix** — no over-broad `rescue` hiding unrelated failures, no loosened validation
      to make the symptom disappear.
- [ ] **Adversarial spec** — send the actual malicious input (the injection payload in a value,
      a crafted table/column identifier, a malformed value) and assert it's neutralized, not
      just that the happy path still works.

**Feature / default-change** — tests for the new behavior **and** its edges, exercised across
the adapters it touches; docs/changelog updated. Default/behavior changes get extra scrutiny
(rubric §4): they hit every consuming app on upgrade, silently. A change to default ordering,
default value coercion, NULL handling, or the emitted SQL alters queries apps already rely on;
a new adapter that doesn't honor the cross-adapter contract is worse than no adapter. New
behavior belongs behind an explicit opt-in or a clearly documented default with a safety
argument.
- [ ] Note the **semver** impact: a default / emitted-SQL change is **minor** at minimum
      (new behavior) and **major** if it can break an existing app's queries.

## 5. Add tests, including the edge cases assistants skip

- [ ] New/changed behavior is covered by a spec.
- [ ] Edge cases the wave hid in: **NULL** values, **empty** result sets / empty `IN ()`
      arrays, **malformed** input, and — the big one for an ORM — **every adapter**
      (sqlite/mysql/pg), not just the local one you ran. "Green happy-path specs on sqlite"
      hide divergence on mysql or pg.
- [ ] For perf/refactor, the **differential** specs that exercise the divergent inputs from
      your §4 table, asserting the same outcome (including the emitted SQL) on all three adapters.

## 6. Don't duplicate a recently-merged PR

- [ ] Check open/recently-merged PRs first — assistants frequently re-propose something
      already landed or already settled:
      ```sh
      gh pr list --state merged --limit 30
      gh pr list --state open --search "<keyword from your change>"
      ```
- [ ] Confirm you're not re-introducing a pattern the repo already settled (e.g. the crystal-db
      connection pool is already concurrency-safe and the M:N safety work landed in
      `src/granite/connection_management.cr` / `connections.cr` via PR #513 — do not re-add
      manual locking around the pool) or contradicting a
      [DESIGN_DECISIONS.md](../../DESIGN_DECISIONS.md) entry.
- [ ] If you include `.jules/`-style learning notes, make sure they're accurate and contain
      **nothing machine-specific** (no absolute local paths, hostnames, usernames, tokens, env dumps).

## 7. Run the local checks so CI is green the first time

CI is **GitHub Actions** (`.github/workflows/spec.yml`): a `formatting` job (format check +
`./bin/ameba`, lint **is** gated) plus `sqlite-spec` / `mysql-spec` / `psql-spec`, each running
the **same** spec suite once per `CURRENT_ADAPTER` across a Crystal matrix
`[1.6.2, 1.7.2, 1.8.1, latest]` (rubric §7). Match it locally **before** you push.

- [ ] One-time setup (idempotent — installs git hooks + makes the skills loadable):
      ```sh
      shards install   # produces bin/ameba (dev dependency, ~> 1.5.0)
      bin/setup-dev
      ```
- [ ] Run the full local check — lint, format, and the sqlite spec suite, in CI order:
      ```sh
      bin/check
      ```
- [ ] sqlite is the **zero-setup** check (no external service) and the fastest way to iterate:
      ```sh
      CURRENT_ADAPTER=sqlite SQLITE_DATABASE_URL=sqlite3:./granite.db crystal spec
      ```
- [ ] Then verify the **other two adapters** — green on sqlite alone is not green. mysql and pg
      need running services (`./spec/run_all_specs.sh`, or local servers):
      ```sh
      CURRENT_ADAPTER=mysql \
        SQLITE_DATABASE_URL=sqlite3:./granite.db \
        MYSQL_DATABASE_URL=mysql://granite:password@localhost:3306/granite_db \
        crystal spec

      CURRENT_ADAPTER=pg \
        PG_DATABASE_URL=postgres://granite:password@localhost:5432/granite_db \
        crystal spec
      ```
      (`./spec/run_all_specs.sh` runs the equivalent across all DBs:
      `bin/ameba && crystal tool format --check && crystal spec --warnings all`.)
- [ ] Let the hooks installed by `bin/setup-dev` do their job — **pre-commit** runs the fast
      `crystal tool format --check`, **pre-push** runs format + `./bin/ameba` + the sqlite specs.
      If a hook fails, fix the cause; don't reach for `SKIP_HOOKS=1`.
- [ ] **Crystal version floor:** the shard allows `>= 1.6.0, < 2.0.0` and CI tests **1.6.2**
      through `latest`. If it passes on a newer compiler for you but you suspect the floor, verify
      against **1.6.2** — don't rely on newer-stdlib-only APIs that pass local dev on `latest` yet
      break the matrix and older users.

## Final gate

- [ ] PR type stated, description matches the diff, one concern, per-type bar met with evidence,
      tests + edge cases across all three adapters, no duplication, `bin/check` green (and mysql/pg
      verified). Now fill in the PR template honestly and open it.
