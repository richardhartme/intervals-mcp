# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntervalsMcp::IntervalsIcuClient do
  subject(:client) { described_class.new(api_key: "test-api-key") }

  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end

  describe "#list_activities" do
    it "uses the documented endpoint, filters, and API-key basic authentication" do
      response = json_response([ { "id" => "activity-1", "name" => "Morning ride" } ])
      request = nil
      allow(http).to receive(:request) { |value| request = value; response }

      activities = client.list_activities(
        athlete_id: "athlete-1",
        oldest: "2026-01-01",
        newest: "2026-01-31T12:00:00",
        limit: 25,
        route_id: 42,
        fields: %w[id name],
      )

      expect(activities).to all(be_a(IntervalsMcp::Activity))
      expect(activities.first.summary).to eq("id" => "activity-1", "name" => "Morning ride")
      request_uri = URI.parse(request.path)
      expect(request_uri.path).to eq("/api/v1/athlete/athlete-1/activities")
      expect(URI.decode_www_form(request_uri.query).to_h).to eq(
        "oldest" => "2026-01-01",
        "newest" => "2026-01-31T12:00:00",
        "limit" => "25",
        "route_id" => "42",
        "fields" => "id,name",
      )
      expect(request["authorization"]).to eq("Basic #{Base64.strict_encode64("API_KEY:test-api-key")}")
    end

    it "rejects an invalid date before making an upstream request" do
      expect { client.list_activities(athlete_id: "athlete-1", oldest: "not-a-date") }
        .to raise_error(ArgumentError, "oldest must be an ISO 8601 date or date-time")
      expect(Net::HTTP).not_to have_received(:start)
    end
  end

  describe "#get_activity" do
    it "requests optional interval data" do
      response = json_response("id" => "activity-1", "icu_intervals" => [])
      request = nil
      allow(http).to receive(:request) { |value| request = value; response }

      expect(client.get_activity(activity_id: "activity-1", intervals: true).to_h).to include("id" => "activity-1")
      request_uri = URI.parse(request.path)
      expect(request_uri.path).to eq("/api/v1/activity/activity-1")
      expect(URI.decode_www_form(request_uri.query).to_h).to eq("intervals" => "true")
    end

    it "maps a rate-limited response without exposing the upstream body" do
      allow(http).to receive(:request).and_return(Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests"))

      expect { client.get_activity(activity_id: "activity-1") }
        .to raise_error(IntervalsMcp::IntervalsIcuClient::RateLimitError, "Intervals.icu rate limit exceeded")
    end
  end

  describe "#get_intervals" do
    it "requests the documented intervals endpoint" do
      response = json_response("icu_intervals" => [ { "id" => 1, "type" => "WORK", "elapsed_time" => 300 } ])
      request = nil
      allow(http).to receive(:request) { |value| request = value; response }

      intervals = client.get_intervals(activity_id: "activity-1")

      expect(intervals).to all(be_a(IntervalsMcp::ActivityInterval))
      expect(intervals.first.elapsed_time).to eq(300)
      expect(request.path).to eq("/api/v1/activity/activity-1/intervals")
    end
  end

  describe "#get_activity_with_intervals" do
    it "hydrates the activity aggregate in one request" do
      response = json_response(
        "id" => "activity-1",
        "icu_intervals" => [ { "id" => 1, "type" => "WORK", "elapsed_time" => 300 } ],
      )
      request = nil
      allow(http).to receive(:request) { |value| request = value; response }

      activity = client.get_activity_with_intervals(activity_id: "activity-1")

      expect(activity.intervals.map(&:id)).to eq([ 1 ])
      request_uri = URI.parse(request.path)
      expect(request_uri.path).to eq("/api/v1/activity/activity-1")
      expect(URI.decode_www_form(request_uri.query).to_h).to eq("intervals" => "true")
      expect(http).to have_received(:request).once
    end
  end

  def json_response(payload)
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.body = JSON.generate(payload)
      response.instance_variable_set(:@read, true)
    end
  end
end
