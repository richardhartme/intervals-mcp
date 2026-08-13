# frozen_string_literal: true

module IntervalsMcp
  class GetActivityTool < MCP::Tool
    tool_name "get_activity"
    description "Get one Intervals.icu activity by ID. Set include_intervals to true only when interval-level data is needed."
    annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true
    input_schema(
      properties: {
        activity_id: { type: "string", description: "Intervals.icu activity ID." },
        include_intervals: { type: "boolean", default: false, description: "Include interval-level activity data." }
      },
      required: [ "activity_id" ],
    )

    class << self
      def call(activity_id:, include_intervals: false, server_context: nil)
        response(client(server_context).get_activity(activity_id: activity_id, intervals: include_intervals).to_h)
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
