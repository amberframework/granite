---
name: review
description: Use when reviewing or triaging a Granite PR. Pulls the PR, checks mergeability mechanics, runs the spec suite locally per adapter, classifies the PR type, applies the severity framework via the three discount levers (verifying claims rather than trusting the description), enforces the per-type correctness bar, discounts documented design trade-offs, decides enhancement vs feature, applies AI-PR hygiene, and produces a verdict (MERGE / MERGE_WITH_CHANGES / REQUEST_CHANGES / CLOSE) backed by file:line evidence.
---

# Reviewing a Granite PR

You are the maintainer. The rubric is the law: [REVIEW_RUBRIC.md](../../REVIEW_RUBRIC.md) is the single source of truth for the severity framework, per-type bars, and enhancement-vs-feature values; [DESIGN_DECISIONS.md](../../DESIGN_DECISIONS.md) lists intentional trade-offs you must discount. This skill is only the *procedure* — it does not restate the rubric.

Golden rule: **the PR description is a claim, not evidence.** Verify everything against the diff and against running code. Cite `file:line` for every point you make.

Remember Granite is a **library** (a shard), not an app: a consuming application sits between an attacker and almost all of Granite's surface, and a change must hold across **three** databases, not one. Both facts shape every lever below.

## 1. Pull the PR and check mergeability mechanics

```sh
gh pr checkout <number>
gh pr view <number> --json title,author,body,files,additions,deletions
gh pr view <number> --json mergeable,mergeStateStatus,reviewDecision
gh pr diff <number>
```

Read the mechanics before you read the code (see rubric §6):

- `mergeable: CONFLICTING` -> not reviewable yet; ask for a rebase.
- `mergeStateStatus: BLOCKED` -> usually a required review/approval, **not** a merge conflict. Check `reviewDecision`; do not chase a phantom conflict.
- `reviewDecision: REVIEW_REQUIRED` / `CHANGES_REQUESTED` -> exactly that.
- Skim the diff once end-to-end now. Note its true scope (does it match the title?) before forming opinions.

## 2. Run the checks locally to match CI

A PR with red specs, a format diff, or `./bin/ameba` errors gets bounced, not reviewed (rubric §6, §7). Match CI before spending review attention. CI is **GitHub Actions** (`.github/workflows/spec.yml`):

```sh
shards install              # produces bin/ameba (dev dependency, ~> 1.5.0)
bin/check                   # ./bin/ameba, crystal tool format --check, then the sqlite spec suite
```

- `bin/check` is the fast zero-setup gate: the **sqlite** adapter needs no external service, so it is the one you can always run. It exercises only one of the three databases — green here is necessary, not sufficient.
- **Run the other two adapters for any change that touches query assembly, the adapters, or `base.cr`.** mysql and pg need running services; `./spec/run_all_specs.sh` runs the full suite against all three adapters in docker (`bin/ameba && crystal tool format --check && crystal spec --warnings all` per adapter, then cleans up), or run one adapter in docker via `docker-compose -f docker/docker-compose.{mysql,pg}.yml run spec`, or point at local servers:
  ```sh
  # sqlite — zero external service, the fastest local check
  CURRENT_ADAPTER=sqlite SQLITE_DATABASE_URL=sqlite3:./granite.db crystal spec

  # mysql — needs a running MySQL
  CURRENT_ADAPTER=mysql \
    SQLITE_DATABASE_URL=sqlite3:./granite.db \
    MYSQL_DATABASE_URL=mysql://granite:password@localhost:3306/granite_db \
    crystal spec

  # pg — needs a running Postgres
  CURRENT_ADAPTER=pg \
    PG_DATABASE_URL=postgres://granite:password@localhost:5432/granite_db \
    crystal spec
  ```
- **Crystal version floor.** The shard allows `>= 1.6.0, < 2.0.0` and the CI matrix tests `[1.6.2, 1.7.2, 1.8.1, latest]` per adapter. If the suite is green for you on a newer compiler, suspect a version-floor break and re-check against **1.6.2** — a PR that relies on newer-stdlib-only APIs can pass local dev on `latest` yet fail the matrix and break older users.
- **Green specs do not mean correct — and green on one adapter does not mean correct.** The suite runs once per `CURRENT_ADAPTER`; a change can pass on sqlite and break on mysql or pg, and a happy-path-only suite tells you nothing about the edge cases the change can break (§3 Performance). Hold both thoughts for step 5.

## 3. Classify the PR type

Pick exactly one type and review against *that* bar (rubric §3): **Bugfix · Security · Performance · Refactor · Feature/default-change.** State your choice in the review. If the author claimed a type, confirm the diff actually fits it — a "refactor" that edits spec *assertions* is not a refactor; a "perf" change that alters the emitted SQL or behavior on any adapter is a behavior change.

## 4. Apply the severity framework — verify, then discount

For every issue you raise, assign a tier (Critical / High / Medium / Low / Informational per rubric §2), then **discount it** through the three levers. A raw finding is a hypothesis; the surviving severity is what you report. **Verify each lever yourself in the diff/code — do not inherit the author's framing.**

- **(a) Reachability + existing mitigations.** Trace the finding to a sink an attacker can actually drive, then check the existing mitigations on the path before assigning severity. The biggest one is parameterization: bound *values* go through `add_parameter` and run as `db.exec sql, args: numbered_parameters` (`src/granite/query/assemblers/base.cr`), with `?` placeholders for sqlite/mysql and `$n` for pg — so a "this `where` value is interpolated, injection!" finding is usually a non-issue, because the value never reaches the SQL string. What *is* reachable: a new code path that string-interpolates a raw SQL fragment, or interpolates an **identifier** (table/column name) into a statement — those bypass the parameterized path. Also remember the consuming app sits in front of most of Granite's API. Worked example (looks scary, is contained): a query path that raises on a malformed value *sounds* like a DoS, but if the immediate caller already `rescue`s it and returns a clean error, the reachable sink is fully mitigated -> Informational/Low, not High. If a mitigation exists, name it and discount.
- **(b) Threat model.** Library API fed untrusted request-derived input vs local dev/CLI. A query-builder method that an app forwards request data into trusts no one; a generator, migration, or maintenance script run by the developer already runs as the operator, so a shell-out there is real smell but **Low** (operator is the attacker). The same shape on a code path that takes untrusted input and builds SQL jumps several tiers.
- **(c) Environment gating.** Where does the dangerous branch run? A finding in a spec helper, a fixture loader, or a dev-only script that never executes in a deployed app is usually Low/Informational. A finding on the default query path that every consuming app exercises on every query is the opposite — it ships to everyone on upgrade. Gating cuts both ways.

Do not accept a severity from the description. Re-derive it from the three levers, citing the lines.

## 5. Apply the per-type correctness bar

Grade the diff against the bar for the type you picked in step 3 (rubric §3). The bar is **evidence**, not vibes:

- **Bugfix:** a spec that was red before the fix and is green now; root-cause not symptom; blast-radius note — including whether the fix holds across sqlite/mysql/pg.
- **Security:** clears all of §3 Security — real+reachable+not-already-mitigated; **complete** fix (push the untrusted data onto a bound parameter via `add_parameter`, or onto a strict allow-list for identifiers — a fix that escapes one spot but still interpolates an identifier elsewhere leaves the vector alive); **narrow** fix (no over-broad `rescue` that hides unrelated failures, no loosened validation to make the symptom disappear); an **adversarial spec** that sends the malicious input (injection payload, malformed value, crafted identifier) and asserts it is neutralized, not just that the happy path still works.
- **Performance:** **provably behavior-identical.** Require the differential edge-case table, and it must include a **per-adapter row** — the emitted SQL string and behavior for sqlite (`?`), mysql (`?`), and pg (`$n`), plus NULL handling (`IS NULL` vs `= ?`) and empty cases (empty result set, empty `IN ()`). This is exactly where a change looks semantically identical but diverges on one adapter's dialect while the sqlite suite stays green. No table, no merge. A benchmark (before/after, method, hardware) justifies that the change is worth making at all.
- **Refactor:** the existing suite passes **unchanged across all three adapters**; if assertions were edited, it's not a pure refactor — reclassify. If behavior could subtly shift, require the differential specs from the Performance bar, including the per-adapter rows.
- **Feature/default-change:** tests for the new behavior and its edge cases across every adapter it touches; docs/changelog updated; description matches code; extra scrutiny per step 7.

## 6. Discount documented design trade-offs

Before you flag anything that smells like "why is it done this way," scan [DESIGN_DECISIONS.md](../../DESIGN_DECISIONS.md). If an entry matches, it is **by design** — do not flag it, and reject a PR that "fixes" it without a separate discussion. Common ones to expect:

- **Bound query values are parameterized.** Values collected via `add_parameter` and run as `db.exec sql, args: numbered_parameters` are not an injection vector — don't flag a bound `where`/value as "interpolated." Note `quote(name)` (`src/adapter/base.cr`) only wraps a name in the `QUOTING_CHAR` and does **not** escape an embedded quote, so it is *not* a sanitizer for attacker-controlled identifiers; a *new* raw-SQL or interpolated-identifier path still *is* flaggable.
- **Multi-adapter parity.** Adapter-specific SQL that lives in the correct assembler (e.g. `$n` only in `src/granite/query/assemblers/pg.cr`) is the design, not duplication — don't flag it. Conversely, behavior that is "green on sqlite only" *is* flaggable: it's the Granite analog of "green specs != correct."
- **crystal-db's pool is already concurrency-safe.** Don't accept a re-added `Mutex` around pool checkout, and don't "fix" the `Atomic`/connection-switching pattern in `src/granite/connection_management.cr` / `connections.cr` without referencing merged PR #513.
- **Crystal version policy.** Code that avoids newer-stdlib-only APIs or keeps a `compare_versions` branch may be deliberate range support, not a missed modernization — leave it. A PR that *relies* on APIs newer than 1.6.2 is the real flag.
- **Library conventions.** `shard.lock` is gitignored and `bin/` is built, not committed — "missing lockfile" / "binaries not checked in" are not bugs. A newly added tracked `bin/` helper does need a force-add to escape the `bin` ignore rule.
- **Type mapping goes through `Granite::Converters`.** A column relying on a `Converters::*` module is the intended extension point; hand-rolled type conversion inside an assembler/adapter (especially anything turning a value into a SQL *string*) *is* flaggable.

A finding that contradicts an entry needs strong specific evidence (a concrete reachable failure or a differential test across adapters), not "looks wrong."

## 7. Decide enhancement vs feature

Apply the rubric §4 values:

- **Enhancement** (improves something Granite already does — faster query assembly, a clearer error, better default ergonomics — without changing its surface contract) -> review against its matching §3 type bar plus evidence it doesn't change behavior for existing apps on any adapter. Welcome as a PR.
- **New feature** (new adapter, new query-builder method, new public-API knob, new association option) -> Feature/default-change bar **plus design buy-in**; it should usually have started as an issue/discussion so we agree it belongs in core. A drive-by feature PR with no prior agreement is a reason to ask for that discussion first.
- **Default/behavior changes get extra scrutiny.** A change to default ordering, value coercion, NULL handling, or the emitted SQL changes queries every consuming app already relies on — silently, on upgrade — and a new adapter that doesn't honor the cross-adapter contract is worse than no adapter. Confirm the **semver** call-out: a default/behavior change is **not** patch-safe (minor at minimum, major if it can break an existing app's queries).

## 8. Apply AI-PR hygiene

AI-assisted PRs are welcome (rubric §5) — hold them to the same checklist:

- [ ] **Description matches the code** — grep the diff against the claims; mismatch is the single most common wave failure.
- [ ] **One concern, scoped diff** — no security-fix-plus-refactor-plus-rename bundles.
- [ ] **Edge-case tests present** — NULL values, empty arrays / `IN ()`, malformed input, and **every adapter** (sqlite/mysql/pg) — the exact spots where green happy-path specs on sqlite hide divergence.
- [ ] **No duplication** — check against recently merged PRs; assistants re-propose already-settled patterns (e.g. re-adding a `Mutex` around the already-safe crystal-db pool, settled in #513).
- [ ] **Learning notes accurate and clean** — `.jules/*`-style notes are fine if correct and contain nothing machine-specific (no absolute local paths, hostnames, usernames, tokens, env dumps).

## 9. Produce the verdict

End with one verdict and the evidence behind it. Every claim cites `file:line`.

- **MERGE** — fits its type bar, levers leave no live high/critical, no design-decision conflict, mechanics clean. Say what you verified (including which adapters you ran).
- **MERGE_WITH_CHANGES** — sound and mergeable after small, named fixes (e.g. add the one missing adversarial spec, add the missing per-adapter differential row, drop the machine-specific note). List each required change with its `file:line`.
- **REQUEST_CHANGES** — fails a bar or a lever in a way that needs author rework (incomplete security fix that still interpolates an identifier, missing differential table, "green on sqlite only," over-broad `rescue`, description/code mismatch). State the bar it missed and what evidence would clear it.
- **CLOSE** — wrong by design (contradicts a DESIGN_DECISIONS entry without evidence — e.g. a re-added pool `Mutex`), a non-issue after discounting (the "DoS" that was fully mitigated by the caller's `rescue`), a duplicate of settled work, or a feature with no design buy-in that belongs in a discussion. Point to the rubric/decision that settles it.

Verdict template:

```
Type: <Bugfix|Security|Performance|Refactor|Feature/default-change>
Mergeability: mergeable=<...> mergeStateStatus=<...> reviewDecision=<...>
Local checks: bin/check <pass|fail> | adapters run: <sqlite|mysql|pg|...> | Crystal floor 1.6.2 <verified|n/a>
Findings:
  - [<Critical|High|Medium|Low|Informational>] <one line> (file:line) — levers applied: <a/b/c result>
Design-decision discounts: <entry or none>
Enhancement vs feature: <which, + semver note if default/behavior change>
AI hygiene: <pass | list gaps>
Verdict: <MERGE|MERGE_WITH_CHANGES|REQUEST_CHANGES|CLOSE>
Required to clear: <named changes with file:line, or n/a>
```
