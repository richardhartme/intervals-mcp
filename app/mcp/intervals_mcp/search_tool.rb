# frozen_string_literal: true

module IntervalsMcp
  class SearchTool < ListActivitiesTool
    tool_name "search"
    description "Search an athlete's Intervals.icu activity history by local ISO 8601 date range, returning matching activities in descending date order."
    annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true
    input_schema(
      properties: {
        athlete_id: { type: "string", description: "Intervals.icu athlete ID." },
        oldest: { type: "string", description: "Inclusive local ISO 8601 start date or date-time." },
        newest: { type: "string", description: "Inclusive local ISO 8601 end date or date-time; defaults to now." },
        limit: { type: "integer", minimum: 1, description: "Maximum number of activities to return." },
        route_id: { type: "integer", description: "Only return activities on this route." },
        fields: { type: "array", items: { type: "string" }, description: "Optional activity fields to return." }
      },
      required: %w[athlete_id oldest],
    )
  end
end
