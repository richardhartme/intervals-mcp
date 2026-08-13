# frozen_string_literal: true

module IntervalsMcp
  class Server
    def self.build
      MCP::Server.new(
        name: "intervals_icu",
        title: "Intervals.icu",
        version: "0.1.0",
        instructions: "Use these read-only tools to retrieve Intervals.icu activities. List activities before requesting a specific activity when its ID is unknown. Use analyze_activity_intervals for workout interval performance and heart-rate insights.",
        tools: [ ListActivitiesTool, GetActivityTool, AnalyzeActivityIntervalsTool ],
      )
    end
  end
end
