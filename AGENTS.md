# Repository Guidelines

## Project Structure & Module Organization

- `src/orma.cr`: shard entrypoint (requires core types).
- `src/orma/`: main library code (records, queries, adapters).
- `src/orma/db_adapters/`: DB-specific behavior (`sqlite3`, `postgresql`).
- `src/ext/`: small core-type extensions used for SQL serialization (`# :nodoc:`).
- `spec/`: test suite (`*_spec.cr`) plus helpers/fakes (e.g. `spec/spec_helper.cr`).
- Generated/ignored: `lib/` (shards deps), `docs/` (API docs), `bin/` (helpers). Avoid committing these unless a change explicitly requires it.

## Build, Test, and Development Commands

- `shards install`: install dependencies into `lib/`.
- `crystal spec`: run the full test suite.
- `crystal spec --error-trace`: run specs with full traces (helpful for macro errors).
- `crystal tool format src spec`: format `src/` and `spec/` (run before pushing).
- `crystal build src/orma.cr`: quick compile check for the shard.
- `crystal docs --output docs`: generate local API docs.

## Coding Style & Naming Conventions

- Indentation: 2 spaces; LF; trim trailing whitespace (see `.editorconfig`).
- Prefer Crystal conventions: `snake_case` for files/methods, `CamelCase` for types.
- Keep public API changes intentional: `Orma::Record` heavily uses macros/annotations; add/adjust specs alongside macro changes.

## Testing Guidelines

- Framework: Crystal’s built-in `spec`.
- Naming: put new coverage in `spec/<feature>_spec.cr`.
- Prefer the in-memory SQLite setup from `spec/spec_helper.cr`; avoid filesystem-backed DBs in tests.

## Security, Configuration & Instrumentation

- `ORMA_CONTINUOUS_MIGRATION=1|true` enables continuous migrations for non-abstract records.
- DB calls are wrapped in OpenTelemetry spans (see `src/open_telemetry_instrumentation.cr`); keep instrumentation changes compatible with the `opentelemetry-sdk` shard.
