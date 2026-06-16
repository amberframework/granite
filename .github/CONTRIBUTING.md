# Contributing to Granite

First, thank you for taking the time to contribute!

Granite is an open source ORM for [Crystal](https://crystal-lang.org/), with adapters for SQLite, MySQL, and PostgreSQL. We love contributions from the community — bug reports, fixes, docs, and features. The following guidelines help your change land smoothly. They are guidelines, not hard rules: use your best judgment, and feel free to propose changes to this document in a pull request.

## How to report a bug

Bugs are tracked as [GitHub issues](https://github.com/amberframework/granite/issues). A good report lets a maintainer reproduce the problem quickly:

* Use a clear, descriptive title.
* State which adapter(s) you hit it on (sqlite, mysql, pg) — Granite runs the same suite per adapter, and behavior can differ between them.
* Give your Crystal version (`crystal --version`) and Granite version. CI tests Crystal `1.6.2` through latest, so version-specific issues matter.
* Provide a minimal, runnable reproduction: a small model plus the query or call that misbehaves, the SQL or error you observed, and what you expected instead.
* Include the exact error output in a Markdown code block.

## How to suggest a feature or enhancement

Enhancement suggestions are also tracked as [GitHub issues](https://github.com/amberframework/granite/issues). Before opening one:

* Search existing issues — if it's already proposed, add to that thread instead.
* Consider whether it belongs in Granite core or could live as a separate shard.

When you open the issue, describe the use case, give a concrete API example as you'd expect to call it, and note how it should behave across the sqlite/mysql/pg adapters.

## Setting up for development

```sh
# 1. Fork and clone, then from the repo root:
shards install            # installs dependencies and builds bin/ameba

# 2. Activate the git hooks and link the review skills (idempotent):
bin/setup-dev

# 3. Run the full multi-adapter suite (sqlite + mysql + pg, in docker):
./spec/run_all_specs.sh         # builds + runs each adapter in docker, then cleans up
```

The **sqlite adapter needs no external service** and is the fastest way to iterate. The **mysql and pg adapters need running database services**: `./spec/run_all_specs.sh` runs the whole suite against all three adapters in docker (building each, then cleaning up), or run a single adapter in docker with `docker-compose -f docker/docker-compose.{mysql,pg,sqlite}.yml run spec`.

## Running the specs

Granite runs its spec suite once per adapter, selected with the `CURRENT_ADAPTER` environment variable. Run the zero-setup sqlite suite directly:

```sh
CURRENT_ADAPTER=sqlite \
  SQLITE_DATABASE_URL=sqlite3:./granite.db \
  SQLITE_REPLICA_URL=sqlite3:./granite_replica.db \
  crystal spec
```

For mysql and pg, either run everything in docker with `./spec/run_all_specs.sh`, run one adapter in docker with `docker-compose -f docker/docker-compose.mysql.yml run spec` (or `…pg.yml`), or point at your own running server by setting the matching adapter variables (`CURRENT_ADAPTER=mysql` with `MYSQL_DATABASE_URL`, or `CURRENT_ADAPTER=pg` with `PG_DATABASE_URL`) and running `crystal spec`. A change must hold across **all three** adapters — green on sqlite alone is not enough.

### Style and specs

* Format your code with `crystal tool format` — CI enforces it.
* Lint with `./bin/ameba` — lint is gated in CI.
* Follow the Crystal [coding style](https://crystal-lang.org/reference/conventions/coding_style.html) and document public API per the [documenting code](https://crystal-lang.org/reference/syntax_and_semantics/documenting_code.html) conventions.
* Add Crystal specs under `spec/`. Treat `describe` as a noun or situation and `it` as a statement about behavior.
* End files with a newline.

## Code review & quality bar

A wave of AI-authored PRs taught us that the same failure shapes recur: "vulnerabilities" with no reachable sink, incomplete fixes, inert dead code, and performance changes that quietly alter behavior while happy-path specs stay green on one adapter. To catch these up front we maintain a shared rubric, a list of intentional design trade-offs, and two skills that walk you through self-review and maintainer review.

* **[contributing/REVIEW_RUBRIC.md](./contributing/REVIEW_RUBRIC.md)** — the source of truth: the severity framework, per-change-type quality bars, and how we value enhancements vs. new features. Read this before opening or reviewing a PR.
* **[contributing/DESIGN_DECISIONS.md](./contributing/DESIGN_DECISIONS.md)** — deliberate trade-offs reviewers should DISCOUNT (so you don't re-litigate settled decisions or flag them as bugs).
* **[contributing/skills/pre-review/SKILL.md](./contributing/skills/pre-review/SKILL.md)** — contributor skill: self-review your own change against the rubric before you push.
* **[contributing/skills/review/SKILL.md](./contributing/skills/review/SKILL.md)** — maintainer skill: review an incoming PR against the rubric.

See **[contributing/README.md](./contributing/README.md)** for how to load the skills and run the checks.

## Before you push

* Run `bin/setup-dev` once. It activates the local git hooks and links the skills into your gitignored `.claude/` so your assistant can load them.
* Run `bin/check` to match CI. It runs `crystal tool format --check`, `./bin/ameba`, and the sqlite spec suite — the zero-setup adapter, no DB service required.
* For the full cross-adapter run (mysql + pg), use `./spec/run_all_specs.sh`. Remember a fix must hold across sqlite, mysql, and pg, and across Crystal `1.6.2`..latest — not just on your local adapter and Crystal version.
