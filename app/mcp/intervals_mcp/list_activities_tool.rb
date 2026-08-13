# frozen_string_literal: true

module IntervalsMcp
  class ListActivitiesTool < MCP::Tool
    tool_name "list_activities"
    description "List an athlete's Intervals.icu activities in descending date order for a required local ISO 8601 date range."
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

    class << self
      def call(athlete_id:, oldest:, newest: nil, limit: nil, route_id: nil, fields: nil, server_context: nil)
        activities = client(server_context).list_activities(
          athlete_id: athlete_id,
          oldest: oldest,
          newest: newest,
          limit: limit,
          route_id: route_id,
          fields: fields,
        )
        response(activities.map(&:summary))
      rescue IntervalsIcuClient::Error, ArgumentError => error
        error_response(error.message)
      end

      private

      def client(server_context)
        server_context&.fetch(:intervals_icu_client, nil) || IntervalsIcuClient.new
      end

      def response(data)
        MCP::Tool::Response.new([ { type: "text", text: JSON.generate(data) } ], structured_content: data)
      end

      def error_response(message)
        MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
      end
    end
  end
end
