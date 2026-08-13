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

## Available tools

- `list_activities`: Lists an athlete's activities for a required `oldest`
  local ISO 8601 date/date-time and optional `newest`, `limit`, `route_id`,
  and `fields` filters.
- `get_activity`: Fetches an activity by ID. Set `include_intervals` only when
  interval-level data is required.
- `analyze_activity_intervals`: Summarizes detected work intervals with splits,
  power/pace, heart rate, Intervals.icu decoupling, and repeat-to-repeat trends.
  Set `include_recovery` to include recovery intervals.

## Development

```sh
bin/rails server
bin/rspec
```
