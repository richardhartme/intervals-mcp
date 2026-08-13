# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP endpoint" do
  it "serves a sessionless tools/list request from ChatGPT" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 0,
        method: "tools/list",
        params: {
          _meta: {
            "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
            "io.modelcontextprotocol/clientInfo" => { name: "openai-mcp", version: "1.0.0" }
          }
        }
      }.to_json,
      headers: {
        "HOST" => "b863-88-97-204-75.ngrok-free.app",
        "ACCEPT" => "application/json, text/event-stream",
        "CONTENT_TYPE" => "application/json",
        "MCP_PROTOCOL_VERSION" => "2026-07-28"
      }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("result", "tools").map { |tool| tool.fetch("name") })
      .to include("search", "fetch")
  end
end
