# Granite Review Rubric

The canonical, single source of truth for how we judge a change to Granite. Everything else (the pre-review skill, the review skill, the PR template, `.github/CONTRIBUTING.md`) links here and adds only its own lens. If those documents and this one ever disagree, **this document wins** — fix the other.

## 1. Purpose & how to use

Multiple AI coding assistants now open PRs against shards like Granite. This standard originated from a wave of AI-assisted PRs on the Amber framework, where a small set of repeatable failure shapes surfaced (over-stated severities, incomplete fixes, "perf" changes that quietly altered behavior, dead/dangerous defaults). The same failure shapes apply to Granite — an ORM consumed by those apps — so this rubric exists, shared verbatim with Amber where the framework is generic, so both sides catch them before they cost review cycles.

- **Contributors — run this before opening a PR.** Load the pre-review skill (`.github/contributing/skills/pre-review/SKILL.md`), self-grade against this rubric, fix what you find, and fill the PR template honestly. The cheapest review note is the one you never trigger.
- **Maintainers — run this before merging.** Load the review skill (`.github/contributing/skills/review/SKILL.md`) and grade the diff against the matching PR-type bar (§3), apply the discount levers (§2) before you assign a severity, and verify mergeability (§6) plus local/CI checks (§7).

Use second person, cite the actual file and line, and prefer "here is the reachable sink" over "this looks scary."

## 2. Severity framework — "what is important"

Assign a tier to every issue you raise. Then **discount it** with the three levers below. A raw finding is a hypothesis; the severity is what survives the levers.

### Tiers

| Tier | Meaning | Granite/ORM example (illustrative) |
|---|---|---|
| **Critical** | Remote, unauthenticated, no preconditions: RCE, auth bypass, secret/data disclosure at scale. | (None reserved here — this tier triggers an immediate fix/release, not a normal review. For a library, a Critical is something every consuming app inherits with no opt-out.) |
| **High** | Real exploit with realistic preconditions, or in a default-on/widely-used path. | A raw or string-interpolated SQL fragment, or an interpolated identifier (table/column name) reachable from request-derived input that a consuming app forwards into a query builder. Bound *values* go through `add_parameter` and run via `db.exec sql, args: numbered_parameters` (`src/granite/query/assemblers/base.cr`), so values are parameterized and safe — but interpolated **identifiers** and hand-written raw SQL are not. **But see Environment gating below**, which can move where it lands. |
| **Medium** | Exploitable only with significant preconditions, or limited blast radius, or needs an unusual config. | A query path that mishandles a malformed value and raises an unexpected exception type, surfacing a confusing error to the consuming app, where the input has already passed the app's own validation/contained. |
| **Low** | Real but minor: needs local access, the operator is the attacker, or impact is cosmetic/hardening. | A migration/CLI concern run by the developer locally — e.g. a generator or maintenance script that shells out. Real, but the operator already controls the machine and the inputs. |
| **Informational** | Style, naming, doc nits, defense-in-depth suggestions with no live vector. | "Consider hardening this even though no untrusted input reaches it." Note it; do not block on it. |

### The three discount levers (apply before finalizing severity)

**(a) Reachability — is there a real attacker-reachable sink, and is it already mitigated?**
Trace the finding to a sink an attacker can actually drive, *then* check existing mitigations on the path before you assign severity.
- Worked example (the "looks scary but is contained" case): a code path that raises on malformed input *sounds* like a denial-of-service — but if the immediate caller already `rescue`s it and returns a clean error, the reachable sink has full existing mitigation -> **downgrade to Informational/Low**, not High. As a library, also remember the consuming app sits between the attacker and most of Granite's surface.
- Checklist: Can request-derived input actually reach it through a normal app's use of the API? Does the immediate caller `rescue`? Is the value parameterized (`add_parameter`) rather than interpolated? If a mitigation already contains it, say so explicitly and discount.

**(b) Threat model — local dev/CLI vs library API consumed by untrusted input.**
Who is the attacker relative to who already has control? A query-builder method an app feeds request data into trusts no one; a generator or migration script run by the developer already runs as the operator.
- A shell-out in a local maintenance/generator script is real code-smell but **Low**, because the person who can run the script and set its inputs is the same person the shell would run as. A code path that takes untrusted request-derived input and builds SQL jumps several tiers.

**(c) Environment gating — production-affecting vs development/test-only.**
Where the dangerous branch only executes outside normal runtime — e.g. only in a spec helper, a fixture loader, or a dev-only generator — severity is lower at runtime, and vice versa.
- A finding in a spec-support or fixture path that never runs in a deployed app is usually Low/Informational. A finding on the default code path that every consuming app exercises on every query is the opposite — it ships to everyone on upgrade. Gating can cut both ways.

## 3. Correctness bars by PR type

Pick the type that matches the change. State which one you are reviewing/submitting against. The bar is **evidence**, not vibes.

### Bugfix
- A failing spec that **reproduces the bug** (red before the fix), now green.
- The fix targets the root cause, not the symptom; no unrelated drive-by edits.
- A note on blast radius: what else calls this path, and does the fix hold across sqlite/mysql/pg (§3 Performance)?

### Security
A security PR must clear **all** of:
- **Real + reachable + not-already-mitigated.** Apply §2(a)–(c). If a caller `rescue` or the parameterized-value path already contains it, say why your fix still matters.
- **Complete fix — no leftover vector.** The norm in Granite is **bound parameters**: collect the value through `add_parameter` so it runs as `db.exec sql, args: numbered_parameters`, never interpolate a value into the SQL string. A "complete fix" pushes the untrusted data onto a bound parameter or onto a strict allow-list for identifiers; a partial fix that escapes one spot but still interpolates an identifier elsewhere leaves the vector alive.
- **Narrow fix — no over-broad rescue or loosened validation.** Do not wrap a wide block in `rescue` (it hides unrelated failures) and **do not loosen validation** to make the symptom disappear — the narrow fix keeps the check strict and routes the value through a parameter.
- **Adversarial spec.** A spec that sends the malicious input (the injection payload, the malformed value, the crafted identifier) and asserts it is neutralized — not just that the happy path still works.

### Performance
Perf changes are the highest-risk "looks fine" category. A perf PR must be **provably behavior-identical**.
- **Differential edge-case table required.** Enumerate inputs where the old and new implementation could diverge and show they agree — including the **emitted SQL string** and behavior **per adapter**. Template:

  | Case | Old behavior | New behavior | Same? |
  |---|---|---|---|
  | emitted SQL for a normal `where` | SQL string + bound params | SQL string + bound params | yes |
  | per adapter (sqlite / mysql / pg) | `?` vs `$n` placeholders, dialect | ... | **must verify on all three** |
  | NULL handling (`IS NULL` vs `= ?`) | ... | ... | **must verify** |
  | empty result set / empty `IN ()` | ... | ... | **must verify** |

  Watch for changes that look semantically identical but diverge on one adapter's dialect or on edge values (NULL, empty arrays). Green specs on the happy path tell you nothing about these.
- **"Green specs != correct" — and "green on one adapter != correct."** The suite runs once per `CURRENT_ADAPTER`; a change can pass on sqlite and break on mysql or pg. Verify across **all three** adapters, and add the differential specs that exercise the divergent inputs.
- A benchmark (before/after numbers, method, hardware) justifying the change is worth making at all.

### Refactor
- **Behavior-preserving by definition.** The existing suite must pass unchanged across all three adapters; if you had to edit a spec's *assertions*, it is not a pure refactor — re-file it.
- No public API or default changes ride along (those are Feature/default-change).
- If behavior could subtly shift, add the differential specs from the Performance bar (including the per-adapter rows).

### Feature / default-change
- Tests for the new behavior **and** its edge cases, exercised across the adapters it touches.
- Docs/changelog updated; the PR description matches what the code does (§5).
- **Default/behavior changes get extra scrutiny — see §4.** A new adapter, a changed default query behavior, or a public-API change alters every app on upgrade.

## 4. Enhancement vs new feature (our values)

- **Enhancement** = improves something Granite already does (faster query assembly, clearer error, better default ergonomics) without changing the library's surface contract. **Bar:** the matching §3 type bar (usually Bugfix/Refactor/Performance) plus evidence it does not change behavior for existing apps on any adapter. Welcome as a PR.
- **New feature** = adds surface area (a new adapter, a new query-builder method, a new public-API knob, a new association option). **Bar:** the Feature/default-change bar, *plus* design buy-in. A new feature should usually **start as an issue or discussion**, not a drive-by PR — so we agree it belongs in core before you build it.

**Why default/behavior changes get extra scrutiny (and a semver note):**
- They affect every app on upgrade, silently. A change to default ordering, default value coercion, NULL handling, or the emitted SQL changes the behavior of queries that consuming apps already rely on — and a new adapter that does not honor the cross-adapter contract is worse than no adapter. New behavior belongs behind an explicit opt-in or a clearly documented default, and "changes the default" needs an explicit safety argument.
- **Semver:** a new default/behavior change is **not patch-safe**. Changing a default or the emitted SQL is a **minor** at minimum (new behavior) and a **major** if it can break an existing app's queries. Call out the bump in the PR.

## 5. AI-assisted contributions

AI-assisted PRs are **welcome and encouraged** — this whole rubric assumes them. The expectations:

- [ ] **Description matches the code.** The PR text describes what the diff *actually does*, not what the assistant intended. Mismatch is the single most common wave failure — reviewers should grep the diff against the claims.
- [ ] **One concern per PR, scoped diff.** No bundling a security fix with a refactor with a rename. Small diffs review faster and revert cleaner.
- [ ] **Tests including the edge cases assistants tend to skip.** NULL values, empty arrays/`IN ()`, malformed input, and **every adapter** (sqlite/mysql/pg) — the exact spots where "green happy-path specs on sqlite" hide divergence (§3 Performance).
- [ ] **No duplication.** Check the change against recently merged PRs before opening; assistants frequently re-propose something already landed or already settled. For example, the connection pool in crystal-db is already concurrency-safe and the M:N safety work landed in `src/granite/connection_management.cr` / `connections.cr` — do not re-add manual locking around the pool.
- [ ] **Learning notes welcome if accurate.** `.jules/*`-style notes are fine to include when they are correct and contain **nothing machine-specific** (no absolute local paths, hostnames, usernames, tokens, or env dumps).

## 6. Mergeability mechanics

Before review, confirm the PR can actually merge:

```sh
gh pr view <number> --json mergeable,mergeStateStatus,reviewDecision
```

- `mergeable: CONFLICTING` -> rebase/resolve; not reviewable yet.
- `mergeStateStatus: BLOCKED` -> **usually a required review/approval, not a merge conflict.** Do not chase a phantom conflict; check `reviewDecision`.
- `reviewDecision: REVIEW_REQUIRED` / `CHANGES_REQUESTED` -> exactly what it says.
- **Local checks must pass before a human spends review time.** A PR with failing `./bin/ameba`, a format diff, or red specs gets bounced back, not reviewed (§7).

## 7. Running the checks locally to match CI

CI is **GitHub Actions** (`.github/workflows/spec.yml`). Match it locally before you push:

1. **formatting** (Crystal `latest`): runs `shards install`, then `crystal tool format --check`, then `./bin/ameba`. **Lint is gated** — a lint failure fails the build.
   ```sh
   shards install              # produces bin/ameba (dev dependency, ~> 1.5.0)
   crystal tool format --check
   ./bin/ameba
   ```
2. **sqlite-spec / mysql-spec / psql-spec** (Crystal matrix `[1.6.2, 1.7.2, 1.8.1, latest]`): each installs deps with `shards update --ignore-crystal-version --skip-postinstall --skip-executables` and runs `crystal spec` once per `CURRENT_ADAPTER`. The same spec suite must pass under **all three** adapters — green on one is not green.

   - **sqlite — zero external service, the fastest local check:**
     ```sh
     CURRENT_ADAPTER=sqlite SQLITE_DATABASE_URL=sqlite3:./granite.db crystal spec
     ```
   - **mysql** (needs a running MySQL — `./spec/run_all_specs.sh` or a local server):
     ```sh
     CURRENT_ADAPTER=mysql \
       SQLITE_DATABASE_URL=sqlite3:./granite.db \
       MYSQL_DATABASE_URL=mysql://granite:password@localhost:3306/granite_db \
       crystal spec
     ```
   - **pg** (needs a running Postgres — `./spec/run_all_specs.sh` or a local server):
     ```sh
     CURRENT_ADAPTER=pg \
       PG_DATABASE_URL=postgres://granite:password@localhost:5432/granite_db \
       crystal spec
     ```

   **Crystal version floor:** the shard allows `>= 1.6.0, < 2.0.0` and CI tests **1.6.2** through `latest`. Do not rely on newer-stdlib-only APIs; if it passes for you on a newer compiler but fails in CI, suspect the version floor — verify against **1.6.2**.

**Shortcuts (use these, don't reinvent them):**
- `bin/check` runs the full local check in order: `./bin/ameba`, `crystal tool format --check`, and the sqlite spec suite. Run it before every push. (`./spec/run_all_specs.sh` runs the equivalent across all DBs: `bin/ameba && crystal tool format --check && crystal spec --warnings all`.)
- The git hooks in `.githooks/` (installed via `bin/setup-dev`) run the fast checks automatically on commit/push so you catch failures before CI does.

## 8. See also

- **`.github/contributing/DESIGN_DECISIONS.md`** — deliberate trade-offs in Granite that reviewers should **discount** (do not flag a settled decision as a bug). Read it before raising a finding that smells like "why is it done this way."
