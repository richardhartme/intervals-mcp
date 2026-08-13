# frozen_string_literal: true

require "rails_helper"

RSpec.describe "activity tools" do
  let(:client) { instance_double(IntervalsMcp::IntervalsIcuClient) }
  let(:server_context) { { intervals_icu_client: client } }

  it "returns activities as structured content" do
    activities = [ IntervalsMcp::Activity.new("id" => "activity-1", "name" => "Morning ride") ]
    allow(client).to receive(:list_activities).with(
      athlete_id: "athlete-1", oldest: "2026-01-01", newest: nil, limit: nil, route_id: nil, fields: nil,
    ).and_return(activities)

    response = IntervalsMcp::ListActivitiesTool.call(
      athlete_id: "athlete-1", oldest: "2026-01-01", server_context: server_context,
    )

    expect(response.error?).to be(false)
    expected_response = [ { "id" => "activity-1", "name" => "Morning ride" } ]
    expect(response.structured_content).to eq(expected_response)
    expect(JSON.parse(response.content.first[:text])).to eq(expected_response)
  end

  it "returns a safe tool error when the activity is not found" do
    allow(client).to receive(:get_activity)
      .with(activity_id: "activity-1", intervals: false)
      .and_raise(IntervalsMcp::IntervalsIcuClient::NotFoundError, "The requested Intervals.icu resource was not found")

    response = IntervalsMcp::GetActivityTool.call(activity_id: "activity-1", server_context: server_context)

    expect(response.error?).to be(true)
    expect(response.content.first[:text]).to eq("The requested Intervals.icu resource was not found")
  end

  it "returns the full activity representation when requested by ID" do
    activity = IntervalsMcp::Activity.new("id" => "activity-1", "device_name" => "Garmin Edge 540")
    allow(client).to receive(:get_activity).with(activity_id: "activity-1", intervals: false).and_return(activity)

    response = IntervalsMcp::GetActivityTool.call(activity_id: "activity-1", server_context: server_context)

    expect(response.structured_content).to eq("id" => "activity-1", "device_name" => "Garmin Edge 540")
  end

  it "analyzes work-interval splits and heart rate" do
    interval = IntervalsMcp::ActivityInterval.new(
      "id" => 1, "type" => "WORK", "elapsed_time" => 300, "moving_time" => 300,
      "distance" => 2500, "average_watts" => 300, "average_heartrate" => 155, "decoupling" => 3.1,
    )
    activity = IntervalsMcp::Activity.new({ "id" => "activity-1", "name" => "Five by five" }, intervals: [ interval ])
    allow(client).to receive(:get_activity_with_intervals).with(activity_id: "activity-1").and_return(activity)

    response = IntervalsMcp::AnalyzeActivityIntervalsTool.call(activity_id: "activity-1", server_context: server_context)

    expect(response.error?).to be(false)
    expect(response.structured_content.fetch("intervals").first).to include(
      "split" => include("elapsed_seconds" => 300),
      "heart_rate" => include("average_bpm" => 155, "drift_percent" => 3.1),
    )
  end

  it "registers both tools with read-only annotations" do
    tools = IntervalsMcp::Server.build.tools

    expect(tools.keys).to contain_exactly("analyze_activity_intervals", "get_activity", "list_activities")
    expect(tools.fetch("list_activities").annotations_value.read_only_hint).to be(true)
    expect(tools.fetch("get_activity").annotations_value.read_only_hint).to be(true)
    expect(tools.fetch("analyze_activity_intervals").annotations_value.read_only_hint).to be(true)
  end
end
