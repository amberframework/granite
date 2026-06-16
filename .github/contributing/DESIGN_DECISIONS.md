# Design Decisions & Known Trade-offs

A living registry of **intentional** design decisions in Granite that look like bugs but are not. Reviewers should **discount** these — do not flag them as defects, and do not "fix" them in a PR without a separate, explicit discussion.

This file complements the [REVIEW_RUBRIC.md](REVIEW_RUBRIC.md), which owns the severity framework and per-type bars. This file owns the *context*: the deliberate choices the rubric assumes you already know.

## How to use it

- **Before flagging** something as a bug, missing default, or anti-pattern, scan this list for a matching entry. If it matches, it is by design — don't flag it.
- A finding that *contradicts* an entry here needs strong, specific evidence (a concrete reachable failure, a differential test across adapters). "Looks wrong" is not enough.
- If an entry is genuinely wrong or stale, that is a real change: open it as its own PR/discussion, update this file in the same PR, and link the reasoning. Don't silently regress a documented decision.

## How to add an entry

Add a new `###` section using the template at the bottom. Each entry has three parts:

1. **Decision** — what the code does, with the relevant repo-relative path.
2. **Rationale** — why it's that way.
3. **Don't flag** — the specific shapes of false-positive review comment this entry preempts.

Keep entries short and link to source. When you add an entry, you are saving every future reviewer the trip you just took.

---

## Entries

### Bound query values are parameterized — they are not an injection vector

- **Decision:** The query assemblers collect a `@numbered_parameters` array (`src/granite/query/assemblers/base.cr`) via `add_parameter`, and execute with `db.exec sql, args: numbered_parameters`. Each adapter emits the placeholder its driver expects: `?` for mysql and sqlite (`src/granite/query/assemblers/mysql.cr`, `src/granite/query/assemblers/sqlite.cr`), `$n` for pg (`src/granite/query/assemblers/pg.cr`, `"$#{@numbered_parameters.size}"`). User-supplied *values* never reach the SQL string.
- **Rationale:** Binding values as positional parameters lets the driver handle escaping/typing, which removes SQL injection from the value path entirely.
- **Don't flag:** "This where/value is interpolated into SQL — injection risk." Bound values go through `add_parameter`; they are safe. Conversely, *do* flag any *new* code that string-interpolates raw SQL fragments, or that interpolates **identifiers** (table/column names) into a statement — those bypass parameterization. Note `quote(name)` (`src/adapter/base.cr`) only wraps a name in the adapter's `QUOTING_CHAR` and does **not** escape an embedded quote, so it is safe for schema-derived names but **not** a sanitizer for attacker-controlled identifiers.

### Multi-adapter parity — a change must hold on sqlite, mysql, and pg

- **Decision:** Granite supports three databases through parallel adapters (`src/adapter/{base,mysql,pg,sqlite}.cr`) and per-adapter SQL assemblers (`src/granite/query/assemblers/{base,mysql,pg}.cr`; the sqlite assembler reuses the mysql `?`-placeholder path). The spec suite runs **once per** `CURRENT_ADAPTER`, so the same specs execute separately against each database in CI.
- **Rationale:** Adapter-specific dialect (placeholder style, `RETURNING`/`lastval`, quoting char) belongs in the matching adapter/assembler. Shared logic lives in the `base` files. Splitting it this way keeps each backend correct without forking the whole query layer.
- **Don't flag:** Adapter-specific SQL that lives in the correct assembler/adapter (e.g. `$n` only in `pg.cr`) — that is the design, not duplication. Conversely, *do* flag behavior that only works on one adapter: a change "green on sqlite only" is the Granite analog of "green specs != correct." If a PR touches `base.cr` query logic or adds a feature, it must hold across sqlite/mysql/pg, not just the local adapter the author ran.

### crystal-db connection pool is already concurrency-safe

- **Decision:** Each adapter's `database` is a `DB::Database` from `DB.open(@url)` (`src/adapter/base.cr`), and access goes through the crystal-db connection pool (`database.retry` / `database.using_connection` in `Adapter::Base#open`). The pool is concurrency-safe on its own. The reader/writer connection-switching logic in `src/granite/connection_management.cr` and `src/granite/connections.cr` was hardened for M:N fibers in merged PR #513 (it uses `Atomic` for the last-write timestamp, intentionally).
- **Rationale:** The pool already manages checkout/checkin and fiber safety. Adding our own `Mutex` around it serializes what the pool deliberately parallelizes, and the M:N-safety work in #513 is the considered solution for the parts the pool does not cover.
- **Don't flag:** "Database access isn't locked / needs a mutex / has a race." Do not re-add manual locking around pool checkout, and do not "fix" the `Atomic`/unsynchronized-class-global pattern in `connection_management.cr` without referencing #513. If you think there's a real race, prove it sits *outside* the pool's guarantees and outside what #513 already settled.

### Crystal version policy: shard allows `>=1.6.0,<2`; CI matrix runs 1.6.2..latest

- **Decision:** `shard.yml` declares `crystal: ">= 1.6.0, < 2.0.0"`. The spec jobs in `.github/workflows/spec.yml` run a Crystal matrix of `[1.6.2, 1.7.2, 1.8.1, latest]` per adapter; the `formatting` job (format check + `./bin/ameba`) uses Crystal latest.
- **Rationale:** Granite supports a broad Crystal range; the matrix proves the code compiles and passes on the oldest supported version, not just the newest.
- **Don't flag:** Code that avoids newer-stdlib-only APIs or works around an older signature — that may be deliberate range support, not a missed modernization. Some code is already version-gated (`{% if compare_versions(Crystal::VERSION, "1.20.0") >= 0 %}` in `connection_management.cr`); leave those branches in place. Conversely, *do* flag a PR that relies on behavior or APIs only present in Crystal newer than 1.6.2 (it can pass local dev on `latest` yet break the matrix and older users) — verify against the declared range, don't assume the newest stdlib.

### Granite is a library: `shard.lock` is gitignored and `bin/` is built, not committed

- **Decision:** `.gitignore` ignores `shard.lock` and `bin` (and `/doc/`). `bin/ameba` and other executables are produced by `shards install`; the lockfile is deliberately not tracked.
- **Rationale:** Libraries (shards) intentionally do not pin their dependencies — locking is the *consuming application's* job, so a library that committed `shard.lock` would force its resolution onto downstream users. The `bin/` directory is regenerated, so committing it would just create churn.
- **Don't flag:** "Missing `shard.lock` / dependencies aren't pinned" or "`bin/ameba` (or other binaries) isn't checked in." Both are by design for a library. *Do* note when a newly added `bin/` script that is meant to be tracked (e.g. a dev helper under `bin/`) needs an explicit force-add to escape the `bin` ignore rule — otherwise it silently won't ship.

### Type mapping goes through `Granite::Converters`, not ad-hoc casting

- **Decision:** Custom column type round-tripping is handled by the converter modules in `src/granite/converters.cr` (`Uuid`, `Enum`, `Json`, `PgNumeric`), each exposing `to_db(value)` / `from_rs(result)`. The `to_db` side returns a `Granite::Columns::Type` so the value flows into the parameterized path; the `from_rs` side reads from a `DB::ResultSet`.
- **Rationale:** Centralizing serialization in converters keeps the value path uniform (and parameterized) across adapters, and makes a new column type a single, testable module rather than scattered casts in the query layer.
- **Don't flag:** A column relying on a `Converters::*` module instead of inline `.to_s`/`.as(...)` casting — that's the intended extension point. Conversely, *do* flag a PR that hand-rolls type conversion inside an assembler or adapter (especially anything that turns a value into a SQL *string*) instead of adding/using a converter, since that risks both adapter drift and breaking parameterization.

---

## Template for new entries

Copy this block, fill it in, and place it in the **Entries** section.

```markdown
### <Short imperative title of the decision>

- **Decision:** <What the code does + repo-relative path(s), e.g. `src/granite/...`.>
- **Rationale:** <Why it's intentionally this way.>
- **Don't flag:** <The specific false-positive review comment(s) this preempts. Optionally: and DO flag <the real failure shape this is sometimes confused with>.>
```
