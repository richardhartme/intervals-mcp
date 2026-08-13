# frozen_string_literal: true

require "rails_helper"
require "rack/mock"

RSpec.describe IntervalsMcp::RequestDebugger do
  let(:logger) { instance_double(Logger, debug: nil) }
  let(:app) { ->(env) { [ 400, { "content-type" => "application/json" }, [ "{\"error\":\"Invalid JSON\"}" ] ] } }
  let(:middleware) { described_class.new(app, logger: logger) }

  it "logs a filtered MCP request and error response without consuming its body" do
    env = Rack::MockRequest.env_for(
      "/mcp",
      method: "POST",
      input: JSON.generate("token" => "secret-value", "method" => "initialize"),
      "HTTP_ACCEPT" => "application/json, text/event-stream",
      "CONTENT_TYPE" => "application/json",
      "HTTP_MCP_PROTOCOL_VERSION" => "2025-11-25",
    )

    response = middleware.call(env)

    expect(response.first).to eq(400)
    expect(env.fetch("rack.input").read).to include("initialize")
    expect(logger).to have_received(:debug).with(a_string_including("[MCP] request", "[FILTERED]", "mcp-protocol-version"))
    expect(logger).to have_received(:debug).with(a_string_including("[MCP] response status=400", "Invalid JSON"))
  end

  it "unwraps a Rack response body when logging an MCP error" do
    wrapped_body = Class.new do
      def initialize(body)
        @body = body
      end
    end.new([ "{\"error\":\"Missing session ID\"}" ])
    wrapped_app = ->(_env) { [ 400, { "content-type" => "application/json" }, wrapped_body ] }

    described_class.new(wrapped_app, logger: logger).call(Rack::MockRequest.env_for("/mcp", method: "POST", input: "{}"))

    expect(logger).to have_received(:debug).with(a_string_including("Missing session ID"))
  end

  it "does not log non-MCP requests" do
    middleware.call(Rack::MockRequest.env_for("/up"))

    expect(logger).not_to have_received(:debug)
  end
end
