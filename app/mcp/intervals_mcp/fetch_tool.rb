# frozen_string_literal: true

module IntervalsMcp
  class FetchTool < GetActivityTool
    tool_name "fetch"
    description "Fetch one Intervals.icu activity by its activity ID. Set include_intervals to true only when interval-level data is needed."
    annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true
    input_schema(
      properties: {
        activity_id: { type: "string", description: "Intervals.icu activity ID." },
        include_intervals: { type: "boolean", default: false, description: "Include interval-level activity data." }
      },
      required: [ "activity_id" ],
    )
  end
end
