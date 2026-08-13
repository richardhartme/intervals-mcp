# frozen_string_literal: true

module IntervalsMcp
  class Server
    def self.build
      MCP::Server.new(
        name: "intervals_icu",
        title: "Intervals.icu",
        version: "0.1.0",
        instructions: "Use search to discover activities by date range, then use fetch with an activity ID to retrieve one. The list_activities and get_activity tools remain available for domain-specific clients. Use analyze_activity_intervals for factual workout interval performance and heart-rate data; interpret the results in the client.",
        tools: [ SearchTool, FetchTool, ListActivitiesTool, GetActivityTool, AnalyzeActivityIntervalsTool ],
      )
    end
  end
end
