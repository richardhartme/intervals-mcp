# Intervals.icu MCP Server

This repository is a Ruby on Rails application that exposes a Model Context Protocol (MCP) server for the [Intervals.icu API](https://intervals.icu/api-docs.html). Keep the server a thin, dependable adapter: MCP-facing code should validate and normalize inputs, call the upstream API, and return useful, structured results without recreating Intervals.icu business logic locally.

## Project conventions

- Use Ruby/Rails conventions and keep application code under `app/`; use RSpec tests under `spec/`.
- Prefer small service objects for Intervals.icu HTTP calls and MCP tool implementations. Keep controllers limited to transport concerns.
- Follow the step-down rule when ordering methods: put public entry points first, then place each helper below the method that calls it, moving from high-level orchestration to lower-level detail. Keep shared low-level utilities at the bottom of the relevant section.
- Use the `mcp` gem already declared in `Gemfile`; do not introduce another MCP SDK unless there is a compelling compatibility need.
- Prefer clear, explicit tool names such as `list_athlete_activities`, `get_activity`, or `create_event`. Describe required identifiers, date formats, and side effects in each tool's MCP metadata.
- Accept ISO 8601 dates/times and normalize them before calling the upstream API. Preserve upstream IDs and timestamps in returned data.
- Return concise, JSON-serializable MCP responses. Translate expected upstream failures into actionable errors; do not expose stack traces or raw credential-related response details.

## Intervals.icu API integration

- Treat the official API documentation as the source of truth for endpoints, request bodies, pagination, rate limits, and supported fields. Do not guess undocumented behavior.
- Keep the API key in an environment variable (for example, `INTERVALS_ICU_API_KEY`). Never commit it, hard-code it, place it in fixtures, or include it in logs or error messages.
- Centralize authentication, base URL configuration, timeouts, request headers, response parsing, and error mapping in one HTTP client/service.
- Set conservative connection and read timeouts. Handle network failures, invalid JSON, 401/403 authentication failures, 404s, 429 rate limits, and upstream 5xx responses explicitly.
- Use pagination for list endpoints and expose a predictable limit/cursor or page interface to MCP clients. Avoid fetching an athlete's entire history by default.
- Cache only when it improves a read-heavy tool and its freshness semantics are explicit. Never cache credentials.

## Safety and data handling

- Read-only tools are the default. Tools that create, update, delete, or otherwise mutate Intervals.icu data must clearly state the effect and require all target identifiers explicitly.
- For destructive operations, make the scope unambiguous and avoid broad defaults. Do not add bulk-delete behavior without an explicit product requirement.
- Treat athlete data as sensitive. Return only fields required by the tool, avoid logging request/response bodies by default, and redact authorization headers and API keys everywhere.
- Do not silently retry non-idempotent writes. Retries for safe reads should be bounded and should respect `Retry-After` when supplied.

## Development workflow

- Run `bin/rspec` for tests and `bin/rubocop` for style checks before handing off a change. Add focused specs for normal responses, malformed input, authentication failures, rate limits, and upstream errors when changing API/MCP behavior.
- Keep `.env*` files untracked. Document required environment variables in `README.md` using placeholders only.
- Make changes narrowly scoped. Avoid editing generated Rails configuration or deployment files unless the change requires it.
