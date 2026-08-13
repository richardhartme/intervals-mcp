# frozen_string_literal: true

module IntervalsMcp
  class AnalyzeActivityIntervalsTool < MCP::Tool
    tool_name "analyze_activity_intervals"
    description "Summarize an activity's detected intervals, including splits, performance, heart rate, and Intervals.icu decoupling."
    annotations read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: true
    input_schema(
      properties: {
        activity_id: { type: "string", description: "Intervals.icu activity ID." },
        include_recovery: { type: "boolean", default: false, description: "Include recovery intervals as well as work intervals." }
      },
      required: [ "activity_id" ],
    )

    class << self
      def call(activity_id:, include_recovery: false, server_context: nil)
        activity = client(server_context).get_activity_with_intervals(activity_id: activity_id)
        analysis = ActivityIntervalAnalyzer.new(activity: activity).analyze(include_recovery: include_recovery)
        response(analysis)
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
