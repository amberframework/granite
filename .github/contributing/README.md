# Contributor review infrastructure

This folder holds the shared review docs and skills for Granite. They exist because multiple AI coding assistants now open PRs, and a recurring set of failure shapes ("vulnerabilities" with no reachable sink, incomplete fixes, inert dead code, performance changes that silently alter behavior, and changes that pass on one adapter but break another) need to be caught before merge — by contributors self-reviewing and by maintainers reviewing.

## What's in here

| File | What it is |
| --- | --- |
| [REVIEW_RUBRIC.md](./REVIEW_RUBRIC.md) | The source of truth: severity framework, per-change-type quality bars, and how we value enhancements vs. new features. Everything else links here instead of duplicating it. |
| [DESIGN_DECISIONS.md](./DESIGN_DECISIONS.md) | Deliberate trade-offs reviewers should DISCOUNT — settled decisions, so you don't re-flag them as bugs. |
| [skills/pre-review/SKILL.md](./skills/pre-review/SKILL.md) | Contributor skill. Self-review your own change against the rubric before you push. |
| [skills/review/SKILL.md](./skills/review/SKILL.md) | Maintainer skill. Review an incoming PR against the rubric. |

## Loading the skills

The skills are intentionally **not committed under `.claude/`** and are **not auto-loaded** — they live here, version-controlled with the code they describe. To make your assistant pick them up, link or copy them into your personal `.claude/skills/`:

* **Recommended:** run `bin/setup-dev` once from the repo root. It activates the local git hooks and symlinks the skills into `.claude/skills/`.
* **Manual:** symlink (or copy) each skill folder into your `.claude/skills/`, for example:

  ```sh
  mkdir -p .claude/skills
  ln -s ../../.github/contributing/skills/pre-review .claude/skills/pre-review
  ln -s ../../.github/contributing/skills/review .claude/skills/review
  ```

`.claude/` is gitignored, so these links stay local to your checkout and are never committed.

## Running the checks (match CI)

CI is GitHub Actions (`.github/workflows/spec.yml`). Two kinds of job run on every change:

1. **formatting** (Crystal latest) — `shards install`, then `crystal tool format --check`, then `./bin/ameba`. Lint is gated, not advisory.
2. **per-adapter specs** — `sqlite-spec`, `mysql-spec`, and `psql-spec`, each across the Crystal matrix `1.6.2`, `1.7.2`, `1.8.1`, and latest. Each installs deps and runs `crystal spec` with that adapter's env vars:
   * **sqlite** — zero external service: `CURRENT_ADAPTER=sqlite`, `SQLITE_DATABASE_URL=sqlite3:./granite.db`, `SQLITE_REPLICA_URL=sqlite3:./granite_replica.db`.
   * **mysql** — `CURRENT_ADAPTER=mysql` against a `mysql:5.7` service, plus `MYSQL_DATABASE_URL`.
   * **pg** — `CURRENT_ADAPTER=pg` against a `postgres:15.2` service, plus `PG_DATABASE_URL`.

To reproduce the per-PR gates locally in one shot, run from the repo root:

```sh
bin/check
```

It runs `crystal tool format --check`, `./bin/ameba`, and the sqlite spec suite — the **zero-setup adapter**, no database service required. It covers only sqlite and your installed Crystal.

For the **full multi-adapter check** (mysql + pg need running services), bring up the dockerized databases:

```sh
./spec/run_all_specs.sh   # builds + runs each adapter in docker, then cleans up
```

A change must hold across **all three adapters** (sqlite/mysql/pg) and across the Crystal version matrix down to `1.6.2` — green on sqlite alone, or on only your local Crystal, is not the same as correct. Don't rely on newer-stdlib-only APIs.

## Where to start

Read [REVIEW_RUBRIC.md](./REVIEW_RUBRIC.md) first, then skim [DESIGN_DECISIONS.md](./DESIGN_DECISIONS.md) so you don't re-litigate settled trade-offs.
