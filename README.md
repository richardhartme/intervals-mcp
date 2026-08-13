# Intervals.icu MCP server

This Rails application exposes a Streamable HTTP MCP server at `/mcp` for the
Intervals.icu API.

## Configuration

Set an Intervals.icu API key before running the server:

```sh
export INTERVALS_ICU_API_KEY="your-api-key"
```

The key is sent to Intervals.icu with HTTP Basic authentication, using
`API_KEY` as the username. Do not commit the key or add it to fixtures.

Set the public MCP hostname before starting Rails. This allows both Rails and
the MCP transport to accept requests for that host. For an ngrok tunnel:

```sh
export MCP_PUBLIC_HOST="your-tunnel.ngrok-free.app"
```

The MCP endpoint is `https://your-public-host/mcp`. The server is read-only,
but it accesses athlete data with the server's Intervals.icu API key. Do not
make it broadly public without adding MCP caller authentication and
authorization.

In development, MCP requests and 4xx/5xx MCP responses are logged at debug
level. Request JSON is truncated to 16 KiB and filtered using Rails's standard
parameter filters; check `log/development.log` when diagnosing a failed MCP
handshake.

## Available tools

- `search`: ChatGPT-compatible activity retrieval. Searches an athlete's
  activity history by required `athlete_id` and `oldest` date, with the same
  optional filters as `list_activities`.
- `fetch`: ChatGPT-compatible activity retrieval by `activity_id`, with the
  same optional interval data as `get_activity`.
- `list_activities`: Lists an athlete's activities for a required `oldest`
  local ISO 8601 date/date-time and optional `newest`, `limit`, `route_id`,
  and `fields` filters.
- `get_activity`: Fetches an activity by ID. Set `include_intervals` only when
  interval-level data is required.
- `analyze_activity_intervals`: Summarizes detected work intervals with splits,
  power/pace, heart rate, Intervals.icu decoupling, and neutral repeat-to-repeat
  observations. Set `include_recovery` to include recovery intervals; clients
  should interpret the returned metrics rather than treating them as coaching advice.

## Development

```sh
bin/rails server
bin/rspec
```
